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

Amethyst has a dedicated slotted `recovery` partition. This tree builds
`recovery.img` without a kernel and includes `recovery` as a separate partition
in `AB_OTA_PARTITIONS`. Before using the image, check that the bootloader
reports `has-slot:recovery: yes`:

```bash
fastboot getvar has-slot:recovery
fastboot getvar current-slot
```

Use the recovery image and ZIP from the same verified build. The following
command targets the recovery partition in the current slot:

```bash
# From the build output directory
fastboot flash recovery recovery.img
fastboot reboot recovery
```

If recovery fails to start, check the active slot and the AVB key chain for
that slot before writing anything else. Stock `vbmeta` can reference a recovery
key different from the one used by LineageOS.

Before moving from HyperOS to LineageOS, verify that your backup is readable
and that you can restore it. Stock userdata may use Xiaomi's `mifs` format.
If recovery reports `unknown fs_type "mifs"` or fails to mount `/data`, stop
and check the data under stock before deciding whether to perform a clean
installation. Formatting userdata erases its contents.

Once in recovery:

```bash
adb devices
adb sideload lineage-23.2-<date>-UNOFFICIAL-amethyst.zip
```

The zip:

- flashes the inactive slot,
- updates physical A/B partitions including `boot`, `init_boot`,
  `vendor_boot`, `dtbo`, `recovery`, `vbmeta` and `vbmeta_system`,
- selects the target slot after a successful installation. When recovery
  cannot allocate Virtual A/B snapshots, a full OTA can reuse source extents
  in `super`. This happened during the Global 307 clean migration. A slot
  marked successful in the bootloader may then have incomplete logical
  partitions. Confirm the actual contents of the slot before relying on it
  for rollback.

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
3. Verify the package, battery and anti-rollback compatibility. For a
   data-preserving attempt, review the package's `flash_all_except_storage`
   script and verify that it leaves `userdata` and `metadata` intact.
   Confirm that you have a backup whenever you can still access the files.
   The plain `flash_all` scripts erase userdata.
4. Keep the bootloader unlocked during restoration and verify that HyperOS
   boots and can read your files.

## 8. Emergency notes

| Situation | What to do |
|---|---|
| Bootloop after flashing | Record the active slot and collect the recovery and boot logs. Use a complete, matching stock package if restoration is required. |
| `fastboot` works, recovery does not | Check the active slot, recovery partition and AVB chain against the intended build. |
| No display, but USB works | Try `adb`/`fastboot`; if neither, EDL recovery is required. |
| IMEI null | Do not flash `modem`/`persist` from another device; restore the correct firmware. |
