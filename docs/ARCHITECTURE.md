# Architecture and change guide

This document explains what each part of the tree does, so a change can be
made in the right place instead of in the first file that looks related.

## Build entry points

| File | Purpose |
|---|---|
| `AndroidProducts.mk` | Declares `lineage_amethyst.mk` as the product. |
| `lineage_amethyst.mk` | Product identity: name, model, brand, fingerprint, GMS client ID. |
| `device.mk` | Packages, copied files, Soong namespaces, HAL selection. |
| `BoardConfig.mk` | Board-level configuration: partitions, kernel, AVB, sepolicy, Wi-Fi. |
| `extract-files.py` | Blob list parsing, fixups and vendor makefile generation. |
| `setup-makefiles.py` | Thin wrapper: `extract-files.py --regenerate_makefiles`. |
| `proprietary-files.txt` | The list of blobs, grouped by section. |

## Directory map

### `aidl/` and `interfaces/`

Xiaomi **Hypsys** service. The device ships a Xiaomi system service that is not
present in AOSP; the tree builds a small compatible service so the vendor
blobs can bind to it. Only touch this if a vendor blob fails to find
`xiaomi.system.hypsys.common`.

### `configs/`

Configuration files copied into the build. They are grouped by subsystem:

| Path | Installed to | Purpose |
|---|---|---|
| `configs/audio/` | `vendor/etc/audio/sku_volcano/` | Audio policy and effects for the `volcano` platform. |
| `configs/display/` | `vendor/etc/displayconfig/` | Display calibration per panel ID. |
| `configs/hidl/` | manifests / compatibility matrix | VINTF declarations. |
| `configs/media/` | `vendor/etc/` | Codec and profile definitions. |
| `configs/sensors/` | `vendor/etc/sensors/` | Sensor HAL configuration. |
| `configs/wifi/` | `vendor/etc/wifi/` | WCNSS, supplicant and P2P configuration. |
| `configs/config.fs` | build system | `fs_config` ownership/mode rules. |

### `overlay/`

Runtime Resource Overlays (RROs). Each overlay is an independent `Android.bp`
module named `*OverlayAmethyst`. They are listed in `device.mk` under
`PRODUCT_PACKAGES`.

Typical changes:

- Default refresh rate, peak refresh rate, brightness curves → `FrameworksOverlayAmethyst`.
- Carrier configuration → `CarrierConfigOverlayAmethyst`.
- Wi-Fi / NFC / Secure Element behavior → their respective overlays.
- Lineage-specific defaults → `LineageSettingsOverlayAmethyst`.

### `power/` and `configs/power/`

The power HAL is Lineage's `android.hardware.power-service.lineage-libperfmgr`,
not Qualcomm's `android.hardware.power-service-qti`. What each hint does is data
in `configs/power/powerhint.json`, installed as `/vendor/etc/powerhint.json`.

`power/power-mode.cpp` is the mode extension (`libpowermode-ext-amethyst`) that
keeps double tap to wake on the Xiaomi touch node, wired through:

```make
$(call soong_config_set,power_libperfmgr,mode_extension_lib,//$(LOCAL_PATH):libpowermode-ext-amethyst)
```

Two things are easy to get wrong:

- The service parses the JSON at boot but only starts applying hints once
  `vendor.powerhal.init` is `1`. `rootdir/etc/init.target.power.rc` sets it; drop
  that file and the HAL runs but does nothing.
- Nodes named in the JSON still need SELinux write access. The generic libperfmgr
  policy covers `/sys/devices/system/cpu/*` and the cgroups; `sepolicy/vendor/hal_power.te`
  adds `vendor_sysfs_msm_perf`, `vendor_latency_device` and `vendor_sysfs_kgsl`.
  `/proc/sys/walt/*` is labelled plain `proc`, so WALT scheduler tunings are
  intentionally left out.

The GPU floor is `min_pwrlevel` on kgsl, where a lower index means a higher
clock: `0` is 1050 MHz, `2` is 895 MHz and `8` is 264 MHz, the idle floor. The
JSON raises it to `2` for `INTERACTION` and `0` for `LAUNCH`, and returns to `8`
when the hint ends. Verified on hardware that the knob clamps the clock: writing
`0` moves `gpuclk` from 362 MHz to 1050 MHz, writing `2` to 895 MHz.

`libqti-perfd-client` is not built from source here: the vendor image ships the
real QTI client and the perf2 HAL behind it, and the stub in
`hardware/qcom-caf/common` would collide with the same path.

### `props/`

Properties are split by destination partition:

| File | Partition |
|---|---|
| `props/system.prop` | `system` |
| `props/system_ext.prop` | `system_ext` |
| `props/vendor.prop` | `vendor` |
| `props/odm.prop` | `odm` |
| `props/product.prop` | `product` |

`props/sku/` contains the per-region properties (`CN`, `GL`, `IN`) and an
`Android.bp` module (`amethyst_sku_properties`) that installs all of them. The
region is selected at runtime by the bootloader/SKU mechanism; the global
build uses `GL_amethyst_build.prop` (`24115RA8EG`, `amethyst_global`).

### `qcril-database/`

A small SQL migration for the Qualcomm RIL database. It disables a
power-on optimization that breaks some operators. It is installed as
`qcrilNrDb_vendor`.

### `rootdir/`

Init scripts, `fstab.qcom`, `ueventd` rules and the charger firmware fstab.
`rootdir/bin/init.kernel.post_boot-*.sh` are Qualcomm performance profiles;
changing them affects thermals and scheduling. Keep the `mgame` thermal
configuration unless you have data showing otherwise.

### `sepolicy/vendor/`

Device-specific SELinux policy. Add rules here, never in
`device/qcom/sepolicy_vndr` and never by disabling `neverallow` checks.

Common tasks:

- New vendor service → add a `.te` file, a `service_contexts` entry and a
  `file_contexts` label.
- New property → `property.te` + `property_contexts`.
- New sysfs node → `genfs_contexts`.

### `udfps/` and `vibrator/`

Small C++ wrappers around Xiaomi's proprietary implementations:

- `libudfpshandler` works around the under-display fingerprint HAL.
- `vibratorfeature-wrapper` exposes Xiaomi's vibrator feature service from
  `vendor` instead of `odm`.

Both are loaded by name from vendor blobs; renaming a module breaks the blob.

## Where to change what

| I want to… | Edit |
|---|---|
| Change the product model or fingerprint | `lineage_amethyst.mk` |
| Add a package to the build | `device.mk` (`PRODUCT_PACKAGES`) |
| Copy a config file | `device.mk` (`PRODUCT_COPY_FILES`) |
| Change a partition size or filesystem | `BoardConfig.mk` |
| Change kernel handling | `BoardConfig.mk` (`# Kernel`) |
| Add a SELinux rule | `sepolicy/vendor/*.te` |
| Change a default setting | the matching `overlay/` |
| Change what a power hint boosts | `configs/power/powerhint.json` |
| Add/remove a blob | `proprietary-files.txt` + re-extract |
| Update the firmware base | `docs/BLOBS.md` procedure |

## Generated files

Do **not** edit these by hand:

- `vendor/xiaomi/amethyst/amethyst-vendor.mk`
- `vendor/xiaomi/amethyst/Android.bp`
- `vendor/xiaomi/amethyst/BoardConfigVendor.mk`

They are generated by `extract-files.py` from `proprietary-files.txt`. Edit the
list and regenerate instead.

## What is intentionally not here

- **Vendor blobs.** They are in `proprietary_vendor_xiaomi_amethyst`.
- **Kernel source.** The current kernel repository is prebuilt. A clean GKI
  source tree is a prerequisite for an official submission; see
  [OFFICIAL.md](OFFICIAL.md).
- **Recovery UI.** LineageOS recovery is built from the same source.
