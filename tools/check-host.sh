#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Quick sanity check for a LineageOS build host.
# Usage: tools/check-host.sh [source-root]

set -euo pipefail

SRC="${1:-$(pwd)}"

ok()   { printf '  \033[32mOK\033[0m   %s\n' "$*"; }
warn() { printf '  \033[33mWARN\033[0m %s\n' "$*"; }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$*"; }

echo "LineageOS build host check"
echo "Source: $SRC"
echo

if [[ "$(uname -s)" != "Linux" ]]; then
    fail "This is not Linux. Build on Linux (WSL2 is unsupported)."
else
    ok "Linux"
fi

if command -v lsb_release >/dev/null 2>&1; then
    ok "$(lsb_release -ds 2>/dev/null || true)"
else
    warn "lsb_release not found; cannot determine distribution"
fi

mem_gb=$(( $(awk '/MemTotal/ {print $2}' /proc/meminfo) / 1024 / 1024 ))
if (( mem_gb >= 60 )); then
    ok "${mem_gb} GB RAM"
elif (( mem_gb >= 28 )); then
    warn "${mem_gb} GB RAM (32 GB + swap is the minimum; use -j12/-j16)"
else
    fail "${mem_gb} GB RAM is too low for a comfortable build"
fi

avail_gb=$(df -Pk "$SRC" | awk 'NR==2 {print int($4/1024/1024)}')
if (( avail_gb >= 450 )); then
    ok "${avail_gb} GB free on the source filesystem"
elif (( avail_gb >= 350 )); then
    warn "${avail_gb} GB free (400 GB+ recommended)"
else
    fail "${avail_gb} GB free (at least 400 GB recommended)"
fi

missing=()
for cmd in git git-lfs repo python3 ccache curl unzip zip; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if (( ${#missing[@]} == 0 )); then
    ok "core tools present"
else
    fail "missing: ${missing[*]}"
fi

if [[ -f "$SRC/build/envsetup.sh" ]]; then
    ok "LineageOS source tree found"
else
    fail "build/envsetup.sh not found in $SRC"
fi

for path in \
    "$SRC/device/xiaomi/amethyst/BoardConfig.mk" \
    "$SRC/device/xiaomi/amethyst-kernel/images/kernel" \
    "$SRC/vendor/xiaomi/amethyst/amethyst-vendor.mk" \
    "$SRC/hardware/xiaomi" \
    "$SRC/device/qcom/sepolicy_vndr/sm8650"; do
    if [[ -e "$path" ]]; then
        ok "${path#$SRC/}"
    else
        fail "missing ${path#$SRC/}"
    fi
done

if command -v java >/dev/null 2>&1; then
    warn "system java found ($(java -version 2>&1 | head -n1)); LineageOS uses its prebuilt JDK"
else
    ok "no system java (expected; prebuilts/jdk is used)"
fi

echo
echo "Done. Fix FAIL items before building."
