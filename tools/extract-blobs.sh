#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Refresh the vendor repository from a full OTA or fastboot ROM.
#
# Usage:
#   tools/extract-blobs.sh /path/to/amethyst_global_OS3.0.307.0.WOPMIXM.zip
#   SRC=~/android/lineage-23.2 tools/extract-blobs.sh /path/to/dump-directory
#
# The source can be a full OTA zip, a fastboot ROM archive, or an already
# extracted dump directory.

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <full-ota.zip|fastboot-rom.tgz|dump-directory>" >&2
    exit 1
fi

OTA="$1"
SRC="${SRC:-$(pwd)}"
DEVICE="$SRC/device/xiaomi/amethyst"
VENDOR="$SRC/vendor/xiaomi/amethyst"

if [[ ! -f "$DEVICE/extract-files.py" ]]; then
    echo "error: $DEVICE/extract-files.py not found (set SRC)" >&2
    exit 1
fi

if [[ ! -d "$VENDOR" ]]; then
    echo "error: $VENDOR is missing; sync the vendor repository first" >&2
    exit 1
fi

if [[ ! -e "$OTA" ]]; then
    echo "error: $OTA does not exist" >&2
    exit 1
fi

echo "Source tree : $SRC"
echo "Input       : $OTA"
echo "Vendor      : $VENDOR"
echo

cd "$DEVICE"

# --keep-dump keeps the temporary extraction for inspection. Remove the dump
# directory that appears next to the archive when you are done.
./extract-files.py --keep-dump "$OTA"

echo
echo "Extraction finished."
echo
echo "Next steps:"
echo "  1. Review: git -C $VENDOR status --short"
echo "  2. Update the header of proprietary-files.txt"
echo "  3. Update VENDOR_SECURITY_PATCH in BoardConfig.mk"
echo "  4. Rebuild and test"
