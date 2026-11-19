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

The tree is designed to be used with a **local manifest**, because the device
repositories are not in the LineageOS organisation.

```bash
# 1. LineageOS 23.2 source
repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

# 2. Add the device repositories (see docs/local_manifest.example.xml)
mkdir -p .repo/local_manifests
git clone https://github.com/Daxandere/local_manifests .repo/local_manifests
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

# 3. Build
. build/envsetup.sh
breakfast amethyst
mka bacon -j16
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
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Build, boot and runtime issues |
| [docs/ROADMAP.md](docs/ROADMAP.md) | 23.2 → 24.0 → official |
| [docs/OFFICIAL.md](docs/OFFICIAL.md) | Requirements and gaps for LineageOS submission |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Why the tree is built this way |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Commit style and contribution rules |
| [CHANGELOG.md](CHANGELOG.md) | Tree changes |

---

## Current status

This table is intentionally conservative: it only records what has been
verified on hardware.

| Area | Status | Notes |
|---|---|---|
| Build | 🔧 In progress | LineageOS 23.2, prebuilt kernel |
| Boot | ⬜ Untested | Target: global `24115RA8EG` on `OS3.0.307.0.WOPMIXM` |
| Calls / SMS | ⬜ Untested | Verify VoLTE/VoWiFi on stock first |
| Mobile data | ⬜ Untested | |
| Wi-Fi / hotspot | ⬜ Untested | |
| Bluetooth / LE Audio | ⬜ Untested | |
| Camera | ⬜ Untested | Aperture + MiuiCamera |
| Fingerprint (UDFPS) | ⬜ Untested | |
| NFC / eSIM | ⬜ Untested | |
| GPS | ⬜ Untested | |
| Sensors | ⬜ Untested | |
| Charging (120 W) | ⬜ Untested | |
| USB / OTG | ⬜ Untested | |

Update this table after each hardware test. The full matrix lives in
[docs/TESTING.md](docs/TESTING.md).

---

## Firmware base

The tree currently declares:

```text
OS3.0.4.0.WOPMIXM
```

The recommended base for new builds is the latest global stable:

```text
OS3.0.307.0.WOPMIXM
```

Blobs will be refreshed from that firmware (see [docs/BLOBS.md](docs/BLOBS.md)).
Firmware and ROM partitions are different things; read
[docs/FIRMWARE.md](docs/FIRMWARE.md) before flashing or downgrading anything.

---

## Repositories used to build

| Repository | Path | Notes |
|---|---|---|
| `Daxandere/android_device_xiaomi_amethyst` | `device/xiaomi/amethyst` | This tree |
| `android_device_xiaomi_amethyst-kernel` | `device/xiaomi/amethyst-kernel` | Prebuilt kernel, dtbo, modules |
| `proprietary_vendor_xiaomi_amethyst` | `vendor/xiaomi/amethyst` | Proprietary blobs |
| `android_hardware_xiaomi` | `hardware/xiaomi` | Xiaomi HALs |

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
