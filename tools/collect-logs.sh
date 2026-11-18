#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Collect the logs needed for a bug report into a timestamped directory.

set -euo pipefail

OUT="${1:-logs-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUT"

echo "Collecting into $OUT"

adb wait-for-device

adb logcat -b all -d > "$OUT/logcat.txt" 2>/dev/null || true
adb shell dmesg > "$OUT/dmesg.txt" 2>/dev/null || true

{
    echo "# getprop"
    adb shell getprop 2>/dev/null || true
} > "$OUT/getprop.txt"

# pstore / ramoops, if present
if adb shell test -d /sys/fs/pstore 2>/dev/null; then
    for f in console-ramoops-0 dmesg-ramoops-0; do
        adb shell cat "/sys/fs/pstore/$f" > "$OUT/$f.txt" 2>/dev/null || true
    done
fi

adb shell dumpsys media.audio_flinger > "$OUT/audio_flinger.txt" 2>/dev/null || true
adb shell dumpsys telephony.registry > "$OUT/telephony.txt" 2>/dev/null || true
adb shell dumpsys biometric > "$OUT/biometric.txt" 2>/dev/null || true
adb shell dumpsys nfc > "$OUT/nfc.txt" 2>/dev/null || true

adb logcat -b all -d 2>/dev/null | grep -i avc > "$OUT/avc.txt" || true

echo "Creating bugreport (this can take a minute)..."
adb bugreport "$OUT/bugreport.zip" >/dev/null 2>&1 || echo "bugreport failed (continuing)"

echo
echo "Done:"
ls -lh "$OUT"
echo
echo "Attach the smallest relevant files, not the whole directory."
