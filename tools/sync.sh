#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Initialize and sync a LineageOS tree for amethyst.
#
# Usage:
#   tools/sync.sh                     # ~/android/lineage-23.2
#   tools/sync.sh /mnt/build/lineage  # custom target
#
# Environment:
#   BRANCH         LineageOS branch   (default: lineage-23.2)
#   MANIFEST_REPO  local_manifests    (default: Daxandere/local_manifests)
#   JOBS           repo sync -j       (default: nproc)
#
# The script is idempotent: it initializes only if .repo is missing and
# updates the manifest repository on later runs.

set -euo pipefail

BRANCH="${BRANCH:-lineage-23.2}"
MANIFEST_REPO="${MANIFEST_REPO:-https://github.com/Daxandere/local_manifests}"
JOBS="${JOBS:-$(nproc --all)}"
TARGET="${1:-$HOME/android/$BRANCH}"

if ! command -v repo >/dev/null 2>&1; then
    echo "error: repo is not in PATH; see docs/BUILD.md" >&2
    exit 1
fi

echo "Target : $TARGET"
echo "Branch : $BRANCH"
echo "Jobs   : $JOBS"
echo

mkdir -p "$TARGET"
cd "$TARGET"

if [[ ! -d .repo ]]; then
    echo "==> repo init"
    repo init -u https://github.com/LineageOS/android.git -b "$BRANCH" --git-lfs
else
    echo "==> existing .repo found, skipping repo init"
fi

echo "==> local manifest"
manifests=.repo/local_manifests
if [[ -e "$manifests/.git" ]]; then
    git -C "$manifests" pull --ff-only
elif [[ -f "$manifests/amethyst.xml" ]]; then
    echo "Using the existing $manifests/amethyst.xml"
else
    git clone "$MANIFEST_REPO" "$manifests"
fi

echo "==> repo sync"
repo sync -c -j"$JOBS" --no-clone-bundle --no-tags

echo
echo "Checking required paths:"
missing=0
for path in \
    device/xiaomi/amethyst/BoardConfig.mk \
    device/xiaomi/amethyst-kernel/images/kernel \
    device/xiaomi/amethyst-kernel/kernel-kit.sha256 \
    vendor/xiaomi/amethyst/amethyst-vendor.mk \
    hardware/xiaomi/Android.bp \
    hardware/qcom-caf/sm8650 \
    device/qcom/sepolicy_vndr/sm8650; do
    if [[ -e "$path" ]]; then
        echo "  OK   $path"
    else
        echo "  MISS $path"
        missing=1
    fi
done

if (( missing )); then
    echo
    echo "Some paths are missing. Verify .repo/local_manifests/amethyst.xml and LineageOS snippets/lineage.xml." >&2
    exit 1
fi

cat <<EOF

Sync finished.

Next:

  cd $TARGET
  unset OUT_DIR OUT_DIR_COMMON_BASE
  . build/envsetup.sh
  breakfast amethyst
  m -j$JOBS bacon

EOF
