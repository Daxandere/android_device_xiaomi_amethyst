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

set -euo pipefail

SRC="${SRC:-$(pwd)}"
JOBS="${JOBS:-16}"
TARGET="${TARGET:-bacon}"
PRODUCT="${PRODUCT:-lineage_amethyst-userdebug}"

if [[ ! -f "$SRC/build/envsetup.sh" ]]; then
    echo "error: $SRC is not a LineageOS source tree" >&2
    exit 1
fi

cd "$SRC"

# shellcheck disable=SC1091
. build/envsetup.sh

lunch "$PRODUCT"
mka "$TARGET" -j"$JOBS"

echo
echo "Build finished. Artifacts:"
ls -lh "out/target/product/amethyst/"*.zip 2>/dev/null || true
