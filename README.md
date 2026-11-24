# LineageOS device tree — Redmi Note 14 Pro+ 5G (`amethyst`)

Unofficial LineageOS device tree for the **Xiaomi Redmi Note 14 Pro+ 5G**.

| | |
|---|---|
| Device | Redmi Note 14 Pro+ 5G |
| Codename | `amethyst` |
| SoC | Qualcomm Snapdragon 7s Gen 3 (`SM7635`, platform `volcano`) |
| GPU | Adreno 810 |
| Architecture | arm64 |
| Android base | LineageOS 23.2 (Android 16) |
| Kernel | GKI 6.1, prebuilt for now |
| Partitions | A/B, dynamic (`super`), ext4 |
| Global model | `24115RA8EG` (`amethyst_global`) |
| Status | **Unofficial / bring-up** |

> This is **not** an official LineageOS device tree. Do not report bugs from this
> tree to the LineageOS project. Use the issue tracker of this repository.

---

## Table of contents

1. [Quick start](#quick-start)
2. [Repository layout](#repository-layout)
3. [Documentation index](#documentation-index)
4. [Current status](#current-status)
5. [Firmware base](#firmware-base)
6. [Repositories used to build](#repositories-used-to-build)
7. [Credits](#credits)
8. [License](#license)

---

## Quick start

Use the local manifest to sync the device tree, vendor blobs, Global 307
kernel bundle and Xiaomi hardware support with LineageOS 23.2. These repositories
contain the build inputs used by the current device configuration.

```bash
mkdir -p ~/android/lineage-23.2
cd ~/android/lineage-23.2
repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs
git clone https://github.com/Daxandere/local_manifests .repo/local_manifests
repo sync -c -j8 --no-clone-bundle --no-tags

unset OUT_DIR OUT_DIR_COMMON_BASE
. build/envsetup.sh
breakfast amethyst
m -j16 bacon
```

The flashable zip is written to:

```text
out/target/product/amethyst/lineage-23.2-<date>-UNOFFICIAL-amethyst.zip
```

Full instructions, host requirements and troubleshooting are in
[docs/BUILD.md](docs/BUILD.md).

---

## Repository layout

```text
device/xiaomi/amethyst/
├── aidl/                  Xiaomi Hypsys AIDL service
├── configs/               Audio, display, HIDL, media, sensors, Wi-Fi, fs
├── interfaces/            Hypsys AIDL interfaces
├── overlay/              RRO overlays (framework, Settings, Wi-Fi, NFC, …)
├── power/                 Qualcomm power extension library
├── props/                 Partition and SKU properties
├── qcril-database/        QCRIL database migration
├── rootdir/               Init scripts, fstab, ueventd
├── sepolicy/vendor/       Device vendor sepolicy
├── udfps/                 UDFPS handler wrapper
├── vibrator/              Xiaomi vibrator wrapper
├── Android.bp
├── AndroidProducts.mk
├── BoardConfig.mk
├── device.mk
├── lineage_amethyst.mk
├── extract-files.py       Blob extraction + fixups
├── setup-makefiles.py     Regenerate vendor makefiles
├── proprietary-files.txt  Blob list
├── lineage.dependencies   Roomservice dependencies (official path)
├── docs/                  Documentation (this file's siblings)
├── tools/                 Helper scripts for build / blobs / logs
├── CHANGELOG.md           History of tree changes
├── CONTRIBUTING.md        Commit style and rules
├── CREDITS.md             Authors and upstream work
└── LICENSE                Apache-2.0
```

A detailed explanation of every directory and “where to change what” is in
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## Documentation index

| Document | What it covers |
|---|---|
| [docs/INDEX.md](docs/INDEX.md) | Index of all documentation |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Tree layout and change guide |
| [docs/BUILD.md](docs/BUILD.md) | Host setup, sync, lunch, build, outputs |
| [docs/FIRMWARE.md](docs/FIRMWARE.md) | Firmware base, matching rules, ARB warnings |
| [docs/BLOBS.md](docs/BLOBS.md) | Refresh vendor blobs from a full OTA |
| [docs/FLASH.md](docs/FLASH.md) | Backup, recovery, sideload, slots, restore |
| [docs/TESTING.md](docs/TESTING.md) | Test matrix and log collection |
| [docs/HANDOFF-307.md](docs/HANDOFF-307.md) | Global 307 results, build inputs and pending 1080p validation |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Build, boot and runtime issues |
| [docs/ROADMAP.md](docs/ROADMAP.md) | 23.2 → 24.0 → official |
| [docs/OFFICIAL.md](docs/OFFICIAL.md) | Requirements and gaps for LineageOS submission |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Why the tree is built this way |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Commit style and contribution rules |
| [CHANGELOG.md](CHANGELOG.md) | Tree changes |

---

## Current status

These results apply to the Global `24115RA8EG` with
`OS3.0.307.0.WOPMIXM` firmware. Calls, messaging, Bluetooth and fingerprint
results are from the device owner's tests. Boot, USB ADB and the video samples
were also checked directly.

| Area | Status | Notes |
|---|---|---|
| Build | ✅ Verified | LineageOS 23.2 with the kernel and modules provided by the local manifest. |
| Boot | ✅ Verified | `k307-eis2diag` reached Android. The current device tree includes its configuration. |
| Calls and SMS | ✅ Verified | Device-owner test. MMS, VoLTE and VoWiFi remain pending. |
| Cellular network and mobile data | ✅ Verified | Device-owner test. |
| Wi-Fi | ✅ Verified | Device-owner test. Individual bands remain pending. |
| Wi-Fi hotspot | ✅ Verified | Device-owner test. |
| Bluetooth | ✅ Verified | Bluetooth and the car Bluetooth connection. LE Audio and Android Auto remain pending. |
| Camera | ✅ Verified | Verified working properly in latest test. |
| Fingerprint (UDFPS) | ⚠️ Partial | Screen-off and normal unlocks work (6/6). **Known issue:** enrolling a new fingerprint leaves `LHBM_ON_WHITE_1000NIT` (`lhbm_value(2)`) lit until the display is turned off (`rem=0` teardown). |
| NFC | ✅ Verified | Device-owner test. |
| eSIM | ⬜ Untested | No eSIM available to test. |
| GPS | ✅ Verified | Device-owner test. |
| Proximity | ✅ Verified | Verified both in-call and live via HAL (`5.0` ↔ `0.0`). |
| Other sensors | ✅ Verified | Verified on `rcd6`: `icm4x6xx` accel/gyro, `qmc630x` mag, `sip1328` light & flicker, `sns_tilt`, `pickup`, `ois_manager`, `pocket_mode`, `sar_detector`, `GripPostureDetection`, `fod_detector`, `MiPhoneCall`, `Touch Sensor`, `UDFPS Sensor`. `dbtap_v2` fires raw HAL events (3850; DT2W unlinked in LineageOS). Idle OEM/trigger entries: `pedometer`, `sns_smd`, `motion_detect`, `Elevator_Acc_Grv`, `oem_treadmill`, `basement_detect`, `eqm`, `wwan`, `semtech_sx937x_0`, `Dynamic Sensor Manager`. |
| Charging (120 W) | ⬜ Untested | Peak charging power remains unmeasured. |
| USB | ✅ Verified | USB connection and ADB. |
| USB OTG | ⬜ Untested | |

Published builds: `rcd1` (GitHub release), `rcd2` (`user`, own release keys,
running on the phone) and the `rcd3-test` validation build. Downloads, checksums
and installation are in [docs/DOWNLOAD.md](docs/DOWNLOAD.md).

Update this table after each hardware test. The full matrix lives in
[docs/TESTING.md](docs/TESTING.md).

---

## Firmware base

The blobs in this tree are extracted from:

```text
OS3.0.307.0.WOPMIXM
```

Flash that build before reporting camera, audio or modem issues: the blobs come
from it, so anything older is untested. To refresh them again, see
[docs/BLOBS.md](docs/BLOBS.md).
Firmware and ROM partitions are different things; read
[docs/FIRMWARE.md](docs/FIRMWARE.md) before flashing or downgrading anything.

---

## Repositories used to build

| Repository | Path | Notes |
|---|---|---|
| `Daxandere/android_device_xiaomi_amethyst` | `device/xiaomi/amethyst` | This tree |
| `Daxandere/android_device_xiaomi_amethyst-kernel` | `device/xiaomi/amethyst-kernel` | Global 307 kernel, DTBs, DTBO, modules and headers |
| `Daxandere/proprietary_vendor_xiaomi_amethyst` | `vendor/xiaomi/amethyst` | Global 307 blobs and the matching ODM makefile |
| `amethyst-playground/android_hardware_xiaomi` | `hardware/xiaomi` | Xiaomi HALs at the revision selected by the manifest |

The Qualcomm trees are provided by LineageOS `snippets/lineage.xml` and must not
be added to the local manifest:

| Repository | Path | Notes |
|---|---|---|
| `LineageOS/android_device_qcom_sepolicy_vndr` | `device/qcom/sepolicy_vndr/sm8650` | CAF sepolicy, branch `lineage-23.2-caf-sm8650` |

The manifest lives in
[`Daxandere/local_manifests`](https://github.com/Daxandere/local_manifests)
and is mirrored in-tree as
[docs/local_manifest.example.xml](docs/local_manifest.example.xml):

```bash
mkdir -p .repo/local_manifests
git clone https://github.com/Daxandere/local_manifests .repo/local_manifests
```

---

## Credits

This tree is based on the original community bring-up by
[`amethyst-playground`](https://github.com/amethyst-playground). See
[CREDITS.md](CREDITS.md) and the git history for the full list of authors.

Android 17 forward-port references:

- [`BluedMC-Amethyst/device_xiaomi_amethyst`](https://github.com/BluedMC-Amethyst/device_xiaomi_amethyst) (`seventeen`)
- [`Novicio-2309/device_xiaomi_amethyst`](https://github.com/Novicio-2309/device_xiaomi_amethyst) (`seventeen`)

---

## License

Device tree files are licensed under **Apache-2.0** unless stated otherwise.
See [LICENSE](LICENSE).

Proprietary blobs live in a separate repository and are **not** licensed under
Apache-2.0.
