# Helper scripts

All scripts assume a Linux build host and are meant to be run from the
LineageOS source root (`$SRC`), not from the device tree directory.

| Script | Purpose |
|---|---|
| `check-host.sh` | Verify OS, RAM, disk, tools and repository paths before building. |
| `sync.sh` | `repo init` + `repo sync` + local manifest, in one idempotent command. |
| `build.sh` | `envsetup`, `lunch`, `mka bacon` with a configurable job count. |
| `extract-blobs.sh` | Refresh `vendor/xiaomi/amethyst` from a full OTA or dump. |
| `collect-logs.sh` | Pull `logcat`, `dmesg`, `pstore`, `dumpsys` and a bug report. |

Examples:

```bash
# From $SRC
tools/check-host.sh
tools/sync.sh                     # fresh host, default ~/android/lineage-23.2
JOBS=16 tools/build.sh
tools/extract-blobs.sh ~/Downloads/amethyst_global_OS3.0.307.0.WOPMIXM.zip
tools/collect-logs.sh
```

The scripts use environment variables instead of long option lists:

| Variable | Default | Meaning |
|---|---|---|
| `SRC` | current directory | LineageOS source root |
| `JOBS` | `16` (`nproc` in `sync.sh`) | `mka`/`repo -j` value |
| `TARGET` | `bacon` | `mka` target |
| `PRODUCT` | `lineage_amethyst-userdebug` | `lunch` product |
| `BRANCH` | `lineage-23.2` | LineageOS branch for `sync.sh` |
| `MANIFEST_REPO` | `Daxandere/local_manifests` | Manifest repository for `sync.sh` |
