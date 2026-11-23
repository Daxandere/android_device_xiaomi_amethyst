#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Build LineageOS for amethyst with a sane default job count.
#
# Usage:
#   tools/build.sh                  # user build (m -j16 bacon)
#   WITH_MICROG=true tools/build.sh # microG variant, also user (checks the
#                                   #   frameworks/base patch first)
#   VARIANT=userdebug tools/build.sh  # debugging build
#   JOBS=12 tools/build.sh         # m -j12 bacon
#   TARGET=installclean tools/build.sh
#   TARGET=bootimage tools/build.sh
#
# SRC defaults to the current directory and must be the LineageOS source root.
#
# Note: no `set -u`. build/envsetup.sh reads unset variables (TOP among them)
# and aborts with "unbound variable" under nounset.

set -o pipefail

SRC="${SRC:-$(pwd)}"
JOBS="${JOBS:-16}"
TARGET="${TARGET:-bacon}"
DEVICE="${DEVICE:-amethyst}"
# Release builds are `user`: no root, ro.debuggable=0. The microG variant is
# also `user`; signature spoofing comes from the frameworks/base patch in
# tools/patches/ (docs/MICROG.md), not from a debug build.
VARIANT="${VARIANT:-user}"

# Resolved before cd: BASH_SOURCE is relative when the script is called by a
# relative path, and the guard below needs it from inside $SRC.
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "$SRC/build/envsetup.sh" ]]; then
    echo "error: $SRC is not a LineageOS source tree" >&2
    exit 1
fi

cd "$SRC" || exit 1

# A repo sync can revert frameworks/base and still produce a microG build that
# compiles and boots, with the fake signature silently gone. Refuse to build
# instead of shipping that.
if [[ "${WITH_MICROG:-false}" == "true" ]]; then
    "$HERE/check-microg-patch.sh" || {
        echo "error: WITH_MICROG=true needs the frameworks/base patch; see docs/MICROG.md" >&2
        exit 1
    }
fi

# The published header and boot-image configuration uses the standard out dir.
unset OUT_DIR OUT_DIR_COMMON_BASE

# shellcheck disable=SC1091
. build/envsetup.sh || exit 1

# breakfast sets TARGET_RELEASE and calls lunch with the three-part form.
# The two-part `lunch lineage_amethyst-userdebug` is rejected on Android 16.
breakfast "$DEVICE" "$VARIANT" || {
    echo "error: breakfast $DEVICE $VARIANT failed; see docs/TROUBLESHOOTING.md" >&2
    exit 1
}

m -j"$JOBS" "$TARGET" || {
    echo "error: m $TARGET failed" >&2
    exit 1
}

echo
echo "$VARIANT build finished. Artifacts:"
ls -lh "out/target/product/amethyst/"*.zip 2>/dev/null || true
