#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Build LineageOS for amethyst with a sane default job count.
#
# Usage:
#   tools/build.sh                 # mka bacon -j16
#   JOBS=12 tools/build.sh         # mka bacon -j12
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

if [[ ! -f "$SRC/build/envsetup.sh" ]]; then
    echo "error: $SRC is not a LineageOS source tree" >&2
    exit 1
fi

cd "$SRC" || exit 1

# shellcheck disable=SC1091
. build/envsetup.sh

# breakfast sets TARGET_RELEASE and calls lunch with the three-part form.
# The two-part `lunch lineage_amethyst-userdebug` is rejected on Android 16.
breakfast "$DEVICE" || {
    echo "error: breakfast $DEVICE failed; see docs/TROUBLESHOOTING.md" >&2
    exit 1
}

mka "$TARGET" -j"$JOBS" || {
    echo "error: mka $TARGET failed" >&2
    exit 1
}

echo
echo "Build finished. Artifacts:"
ls -lh "out/target/product/amethyst/"*.zip 2>/dev/null || true
