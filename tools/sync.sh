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

echo "==> repo sync (base)"
repo sync -c -j"$JOBS" --force-sync --no-clone-bundle --no-tags

echo "==> local manifest"
mkdir -p .repo/local_manifests
if [[ -d .repo/local_manifests/.git ]]; then
    git -C .repo/local_manifests pull --ff-only
else
    rm -f .repo/local_manifests/amethyst.xml
    git clone "$MANIFEST_REPO" .repo/local_manifests
fi

echo "==> repo sync (device repositories)"
repo sync -c -j"$JOBS" --force-sync --no-clone-bundle --no-tags

echo
echo "Checking required paths:"
missing=0
for path in \
    device/xiaomi/amethyst/BoardConfig.mk \
    device/xiaomi/amethyst-kernel/images/kernel \
    vendor/xiaomi/amethyst/amethyst-vendor.mk \
    hardware/xiaomi/Android.bp \
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
    echo "Some repositories are missing. Check .repo/local_manifests/amethyst.xml" >&2
    exit 1
fi

cat <<EOF

Sync finished.

Next:

  cd $TARGET
  source build/envsetup.sh
  lunch lineage_amethyst-userdebug
  mka bacon -j$JOBS

EOF
