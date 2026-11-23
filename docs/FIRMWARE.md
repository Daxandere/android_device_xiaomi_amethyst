# Firmware and ROM compatibility

## Two different things

| Term | Partitions | Who ships it |
|---|---|---|
| **Firmware** | `xbl`, `abl`, `tz`, `hyp`, `modem`, `dsp`, `bluetooth`, `keymaster`, `persist`, … | Xiaomi (HyperOS) |
| **ROM** | `boot`, `init_boot`, `vendor_boot`, `dtbo`, `vbmeta`, `super` (`system`, `vendor`, `product`, `odm`, `system_ext`, `vendor_dlkm`, `system_dlkm`) | LineageOS build |

A custom ROM replaces the second group, not the first. That is why a ROM
build can boot on a newer firmware base, but camera, audio or modem behavior
can still differ.

## Supported base

| | Version |
|---|---|
| Tree declared in `proprietary-files.txt` / `lineage_amethyst.mk` | **`OS3.0.307.0.WOPMIXM`** |
| Recommended global stable (Oct 2026) | **`OS3.0.307.0.WOPMIXM`** |
| Region | Global (`WOPMIXM`), model `24115RA8EG` |

The blobs were refreshed from `OS3.0.307.0.WOPMIXM`. Flash that build before
reporting camera/audio issues. `OS3.0.307.0.WOPMIXM` or newer for the same
region is accepted; do not mix regions and do not downgrade (see
[Rules](#rules)).

## Check what the phone is running

```bash
adb shell getprop ro.build.version.incremental   # OS3.0.307.0.WOPMIXM
adb shell getprop ro.product.mod_device          # amethyst_global
adb shell getprop ro.boot.hwc                    # GL / IN / CN
adb shell getprop ro.product.model               # 24115RA8EG
```

On the phone: **Settings → About phone → HyperOS version**.

## Rules

1. **Do not downgrade firmware** unless you have checked Xiaomi's anti-rollback
   (ARB) index for this exact model. A downgrade can hard-brick the device.
2. **Flash the ROM, not the firmware**, when testing LineageOS. The ROM zip
   contains the images it needs.
3. If you update HyperOS, boot it once, then reinstall the ROM. A firmware
   update may wipe the custom ROM's `boot`/`vendor_boot`.
4. Do not mix firmware from different regions (`WOPMIXM` vs `WOPINXM` vs
   `WOPCNXM`) on a global device.
5. `persist` contains factory calibration (fingerprint, sensors). Never flash a
   foreign `persist` image.

## Symptoms of a firmware/ROM mismatch

| Symptom | Likely cause |
|---|---|
| No audio at all, or only speaker | Audio blobs / policy older than firmware |
| Camera opens but black frames | Camera blobs / firmware mismatch |
| Modem crash, no SIM, IMEI null | `modem`/`dsp` firmware mismatch |
| Fingerprint enrollment fails | `persist` or UDFPS blob mismatch |
| Wi-Fi MAC changes or no Wi-Fi | `wlan`/`bt` firmware mismatch |
| Bootloop after logo | Kernel/modules or `vbmeta` mismatch |

## Updating firmware

Preferred, if you must:

1. Download the **fastboot ROM** for `OS3.0.307.0.WOPMIXM` (global).
2. Verify the checksum.
3. Follow the [stock restoration procedure](FLASH.md#7-restoring-stock) and
   choose the script according to whether you need to keep userdata.
4. Boot HyperOS once, finish setup, enable developer options.
5. Flash LineageOS again.

Do **not** relock the bootloader while a custom ROM is installed.

## Related documents

- [BLOBS.md](BLOBS.md) — refresh the vendor repository from a full OTA.
- [FLASH.md](FLASH.md) — backup, recovery and installation.
