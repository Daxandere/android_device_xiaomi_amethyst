# Documentation index

Everything in this directory is meant to be read in this order when starting
from scratch.

| # | Document | Read it when… |
|---|---|---|
| 1 | [ARCHITECTURE.md](ARCHITECTURE.md) | You need to understand the tree layout. |
| 2 | [BUILD.md](BUILD.md) | You are preparing a build host or running a build. |
| 3 | [FIRMWARE.md](FIRMWARE.md) | You are about to flash firmware or a ROM. |
| 4 | [BLOBS.md](BLOBS.md) | You need to refresh the vendor repository. |
| 5 | [FLASH.md](FLASH.md) | You are flashing the phone for the first time. |
| 6 | [TESTING.md](TESTING.md) | You have a booting build and need to validate it. |
| 7 | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | A build or a boot failed. |
| 8 | [ROADMAP.md](ROADMAP.md) | You want to know what comes next. |
| 9 | [OFFICIAL.md](OFFICIAL.md) | You want to submit the device to LineageOS. |
| 10 | [DECISIONS.md](DECISIONS.md) | You want to know why something is done this way. |
| 11 | [BRANCHES.md](BRANCHES.md) | You are resuming an experiment or checking what is still pending. |
| 12 | [DOWNLOAD.md](DOWNLOAD.md) | You want the published ZIPs, their checksums or how to flash them. |
| 13 | [releases/rcd1.md](releases/rcd1.md) | You want the release notes of the published RC, or the base for the next one. |
| 14 | [SIGNING.md](SIGNING.md) | You are building a release ZIP and need your own keys, or you are moving a phone to them. |

## Conventions

- Commands are written for a **Linux build host** (Ubuntu 24.04 LTS).
- `$SRC` is the root of the LineageOS source tree.
- `$DEVICE` is `$SRC/device/xiaomi/amethyst`.
- `amethyst` is always the codename; the retail name is only used in prose.
- “Firmware” means the partitions shipped by Xiaomi (modem, bootloader, DSP,
  etc.). “ROM” means the images built by LineageOS.
- The tree is unofficial: bugs go to this repository's issue tracker, not to
  LineageOS.

## Status legend

| Symbol | Meaning |
|---|---|
| ✅ | Verified on hardware |
| 🔧 | In progress / needs work |
| ⬜ | Not tested yet |
| ❌ | Known broken |
| ⚠️ | Works with caveats |
