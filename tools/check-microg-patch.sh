#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Fail unless frameworks/base grants microG its fake signature on release builds.
#
# A `repo sync` that updates frameworks/base drops the commit applied from
# tools/patches/microg-user-spoofing.patch. A `user` build without it still
# compiles, still boots and still installs microG; the only symptom is the
# "System spoofs signature" row failing the microG Self-Check, which is easy to
# miss. tools/build.sh runs this before every WITH_MICROG=true build.
#
# Usage:
#   SRC=/path/to/lineage-23.2 tools/check-microg-patch.sh

set -o pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC="${SRC:-$(pwd)}"
ENGINE="$SRC/frameworks/base/services/core/java/com/android/server/pm/ComputerEngine.java"

if [[ ! -d "$SRC/frameworks/base" ]]; then
    echo "error: $SRC/frameworks/base is missing; is SRC the LineageOS source root?" >&2
    exit 1
fi

if [[ ! -f "$ENGINE" ]]; then
    echo "error: $ENGINE is missing; frameworks/base is incomplete" >&2
    exit 1
fi

# Extract the isMicrogSigned() body brace by brace: a bare grep for
# isDebuggable() would always match the native declaration just above it, and
# a grep for MICROG_REAL_SIGNATURE would match the rest of the class.
body="$(awk '
    /public static boolean isMicrogSigned\(/ { inside = 1 }
    inside {
        print
        depth += gsub(/\{/, "{") - gsub(/\}/, "}")
        if (depth <= 0) exit
    }
' "$ENGINE")"

if [[ -z "$body" ]]; then
    echo "error: isMicrogSigned() not found in $ENGINE" >&2
    exit 1
fi

fail=0

if grep -q 'isDebuggable' <<<"$body"; then
    echo "  FAIL isMicrogSigned() still gates on isDebuggable()"
    fail=1
else
    echo "  OK   isMicrogSigned() no longer gates on isDebuggable()"
fi

if grep -q 'MICROG_REAL_SIGNATURE' <<<"$body"; then
    echo "  OK   certificate check (MICROG_REAL_SIGNATURE) is intact"
else
    echo "  FAIL certificate check (MICROG_REAL_SIGNATURE) is missing"
    fail=1
fi

for package in com.android.vending com.google.android.gms; do
    if grep -q "$package" <<<"$body"; then
        echo "  OK   allowlist still names $package"
    else
        echo "  FAIL allowlist no longer names $package"
        fail=1
    fi
done

if (( fail )); then
    cat >&2 <<EOF

error: frameworks/base does not carry the microG fake-signature patch.
       A WITH_MICROG=true build would boot with microG broken: the Self-Check
       "System spoofs signature" fails. Reapply it first:

  git -C $SRC/frameworks/base am "$HERE/patches/microg-user-spoofing.patch"

EOF
    exit 1
fi

echo "frameworks/base carries the microG fake-signature patch."
