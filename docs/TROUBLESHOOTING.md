# Troubleshooting

Start with the exact error message. Most “it does not boot” reports are one of
five things: a missing blob, a stale `out/`, a firmware mismatch, the wrong
slot, or a SELinux denial.

## Build

### `repo sync` fails

```bash
repo sync -c -j4 --force-sync --no-clone-bundle --no-tags
```

- `--force-sync` recovers from a dirty mirror.
- Lower `-j` if the host runs out of memory or the network drops.
- If a single project fails, `repo sync <path>`.

### `ninja: error: ... missing and no known rule to make it`

Usually a missing vendor blob or a path that changed after a blob refresh.

```bash
ls vendor/xiaomi/amethyst/amethyst-vendor.mk
grep -n "<missing-file>" proprietary-files.txt
```

Re-run [BLOBS.md](BLOBS.md) and check the `extract-files.py` fixups.

### `error: undefined reference to ...`

A blob links against a library that is not in the vendor tree, or a fixup
(`replace_needed`/`add_needed`) is missing. Find the library with:

```bash
grep -R "libname" proprietary-files.txt
```

### `neverallow` / `avc: denied`

Add a device-specific rule under `sepolicy/vendor/`. Do not disable
`BUILD_BROKEN` checks or `neverallow` to “make it build”.

Useful commands:

```bash
adb shell dmesg | grep avc
adb shell ls -Z <path>
```

### OOM killed / `cc1plus: out of memory`

- Lower `-j` (for example `mka bacon -j12`).
- Add swap/zram.
- Use a host with more RAM.
- Do not run two builds at once.

### Build works, but the zip is missing

```bash
mka bacon -j16
ls -lh out/target/product/amethyst/*.zip
```

If `bacon` is not a valid target, the product or release is wrong. Use
`breakfast amethyst`, which sets `TARGET_RELEASE` and calls `lunch` with the
three-part form. Two common symptoms:

| Error | Cause |
|---|---|
| `Invalid lunch combo: lineage_amethyst-userdebug` | The two-part `lunch` form is not accepted on Android 16 |
| `No release config set for target` | `TARGET_RELEASE` is empty; `breakfast` sets it from `vendor/lineage/vars/aosp_target_release` |

### Stale build

```bash
mka installclean
# or, if the vendor tree changed drastically:
mka clean
```

## Boot

### Stuck on the logo

1. Wait 20 minutes.
2. Check `adb devices`. If the device is visible, collect `adb logcat`.
3. Reboot to recovery and re-sideload the zip.
4. Check the active slot: `fastboot getvar current-slot`.
5. Re-flash the stock `boot`/`init_boot`/`vendor_boot` and start again.

### Bootloop after the logo

- Usually a kernel/module or `vbmeta` mismatch.
- Re-flash the ROM zip; if it persists, restore the stock images.
- If you changed firmware, boot stock once before reinstalling.

### Recovery does not start

- Verify the image matches the build (`recovery.img` from the same `out/`).
- Try the `vendor_boot`/`init_boot` target if the device uses it.
- Re-flash the stock boot images, then retry.

### “No command” / black screen in recovery

The recovery image was flashed to the wrong partition. Restore stock boot and
retry with the correct target.

## Runtime

### No audio

- Compare with stock on the same firmware.
- Check that the blob refresh completed (`libagm`, `libar-pal`, audio policy).
- `adb logcat -b all | grep -iE 'audio|agm|pal'`.
- Android 17 ports had a “no sound on first boot” bug; a reboot or an
  `audioserver` restart sometimes reveals whether it is initialization order.

### Camera black / crashes

- Check `logcat | grep -i camx`.
- Verify camera blobs and firmware match.
- Disable EIS for the front camera if colors are wrong.
- Test with Aperture first, then MiuiCamera.

### Fingerprint does not enroll

- Check `persist` is intact.
- Check the UDFPS service: `adb shell dumpsys biometric`.
- A foreign `persist` or a bad UDFPS blob will break enrollment.

### NFC / eSIM

- Check `dumpsys nfc` and `dumpsys euicc`.
- NFC firmware and the Secure Element overlay must match the region.

### Mobile data / calls

- Verify APN and carrier config.
- Check `dumpsys telephony.registry`.
- If stock also fails, it is not a ROM issue.

## Reporting

Include:

- Build date and zip name.
- Firmware version (`ro.build.version.incremental`).
- Exact steps to reproduce.
- `logcat`, `dmesg`, and `avc` lines if relevant.
- Whether the issue happens on stock.

Do not report this tree's bugs to LineageOS.
