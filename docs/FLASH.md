# Flashing and restoring

> **Warning:** unlocking the bootloader wipes the phone. Back up first. You are
> responsible for your own device.

## 1. Prerequisites

- Bootloader unlocked (Xiaomi's unlock tool, with the waiting period).
- `adb` and `fastboot` from Android platform-tools.
- The LineageOS zip built by this tree.
- The recovery image from the same build.
- The full firmware package for your exact model, in case you need to restore.

Check the connection:

```bash
adb devices
adb reboot bootloader
fastboot devices
fastboot getvar current-slot
fastboot getvar product
```

`product` must be `amethyst`. If it is not, stop.

## 2. Back up

At minimum:

- Photos, documents, chat backups, authenticator seeds.
- Xiaomi cloud / Google account credentials.
- The stock `boot`, `init_boot`, `vendor_boot`, `dtbo` and `vbmeta` images from
  the firmware package you are on.

### `persist`

`persist` contains fingerprint and sensor calibration. Losing it can leave the
fingerprint reader unusable. A backup requires root. Options:

- Boot a rooted GKI boot image temporarily (`fastboot boot`) and copy
  `/dev/block/bootdevice/by-name/persist`.
- Use a recovery with `adb root` (for example an OrangeFox build for
  `amethyst`).
- Some EDL tools can dump it, but that is outside the scope of this document.

Example, with root:

```bash
adb shell su -c 'dd if=/dev/block/bootdevice/by-name/persist of=/sdcard/persist.img'
adb pull /sdcard/persist.img
```

Keep the file somewhere safe.

## 3. Install

The device is A/B with `init_boot` and `vendor_boot`. The exact fastboot target
for the recovery image can vary with the boot header, so verify what the build
produced:

```text
out/target/product/amethyst/recovery.img
out/target/product/amethyst/boot.img
out/target/product/amethyst/init_boot.img
out/target/product/amethyst/vendor_boot.img
```

Typical A/B flow with LineageOS recovery:

```bash
# From the build output directory
fastboot flash boot recovery.img
fastboot reboot recovery
```

If the device does not enter recovery, flash the recovery image to the
partition it was built for (`vendor_boot` or `init_boot`) and try again. When
in doubt, use the LineageOS installation page for a device with the same
partition layout as a reference.

Once in recovery:

```bash
adb devices
adb sideload lineage-23.2-<date>-UNOFFICIAL-amethyst.zip
```

The zip:

- flashes the inactive slot,
- updates `boot`, `init_boot`, `vendor_boot`, `dtbo`, `vbmeta` and `super`,
- switches the active slot on success.

Do **not** reboot in the middle of the sideload.

## 4. First boot

- 5–15 minutes is normal.
- The phone may reboot once.
- Do not interrupt it.
- If it stays on the logo for more than 20 minutes, see
  [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## 5. After boot

```bash
adb shell getprop ro.lineage.version
adb shell getprop ro.build.fingerprint
adb shell getprop ro.product.mod_device    # amethyst_global
```

Run the test matrix in [TESTING.md](TESTING.md).

## 6. Updating

- If you use the same signing keys, you can sideload a newer zip over the old
  one (`adb sideload` in recovery).
- If you switch keys (for example test-keys → your keys), a data wipe is
  required.
- Never mix firmware from another region.

## 7. Restoring stock

1. Download the fastboot ROM for your exact model and region.
2. Extract it on the build host.
3. Run `flash_all.sh` (Linux) or `flash_all.bat` (Windows) with the bootloader
   unlocked.
4. Boot HyperOS once.
5. Only relock the bootloader after a full stock restore.

## 8. Emergency notes

| Situation | What to do |
|---|---|
| Bootloop after flashing | Re-flash the stock `boot`/`init_boot`/`vendor_boot`; check the active slot. |
| `fastboot` works, recovery does not | Flash the stock boot images, then retry recovery. |
| No display, but USB works | Try `adb`/`fastboot`; if neither, EDL recovery is required. |
| IMEI null | Do not flash `modem`/`persist` from another device; restore the correct firmware. |
