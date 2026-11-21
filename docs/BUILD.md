# Building LineageOS 23.2 for `amethyst`

These instructions assume a **Linux build host**. Windows is not supported for
the build itself (WSL2 may work, but it is not the supported path).

The local manifest retrieves the kernel, DTBs, DTBO, modules, headers and
vendor blobs for HyperOS Global 307. The versioned device configuration uses
them directly. Use the standard `out` directory. The [Global 307 handoff](HANDOFF-307.md)
records the tests and the current EIS limitation.

## 1. Host requirements

| Resource | Minimum | Recommended |
|---|---|---|
| CPU | 8 vCPU | 16 vCPU |
| RAM | 32 GB + 32 GB swap/zram | 64 GB |
| Disk | 400 GB SSD | 500 GB–1 TB NVMe |
| OS | Ubuntu 22.04/24.04 | Ubuntu 24.04 LTS |

The build is mostly CPU-bound, but Soong/Ninja can easily exceed 32 GB of RAM.
If the host has 32 GB, use `-j12` or `-j16`, not `-j$(nproc)` on a 32-vCPU
machine.

The JDK is **not** installed manually: LineageOS ships `prebuilts/jdk/jdk21`.
Do not install a PPA JDK.

### Packages

```bash
sudo apt update
sudo apt install -y \
  bc bison build-essential ccache curl erofs-utils flex g++-multilib \
  gcc-multilib git git-lfs gnupg gperf imagemagick kmod lib32readline-dev \
  lib32z1-dev libdw-dev libelf-dev libgnutls28-dev libsdl1.2-dev libssl-dev \
  libxml2 libxml2-utils lz4 lzop pngcrush protobuf-compiler python3-protobuf \
  python-is-python3 rsync schedtool squashfs-tools unzip xsltproc xxd zip zlib1g-dev
```

If your distribution ships `libxml2-16` instead of `libxml2` (Ubuntu 25.10 and
newer), install that package name instead.

### Tools

```bash
mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
export PATH="$HOME/bin:$PATH"
```

Add the `PATH` export to `~/.bashrc`.

## 2. Sync LineageOS and the device repositories

Run this sequence from an empty build directory. Add the local manifest
before the first sync so that `repo` fetches the base and device projects
in one pass.

```bash
mkdir -p ~/android/lineage-23.2
cd ~/android/lineage-23.2

repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs
git clone https://github.com/Daxandere/local_manifests .repo/local_manifests
repo sync -c -j8 --no-clone-bundle --no-tags
```

Keep Git LFS enabled for LineageOS prebuilts. For an existing checkout with
the manifest cloned at path `.repo/local_manifests`, run
`git -C .repo/local_manifests pull --ff-only` before `repo sync`.
`tools/sync.sh` automates this sequence. The canonical manifest is
[Daxandere/local_manifests](https://github.com/Daxandere/local_manifests).

The manifest points to:

- `device/xiaomi/amethyst` on the Daxandere `lineage-23.2` branch.
- `device/xiaomi/amethyst-kernel` on the Daxandere `lineage-23.2-global307` branch.
- `vendor/xiaomi/amethyst` on the Daxandere `lineage-23.2` branch.
- `hardware/xiaomi` pinned to the tested hardware repository revision.

Verify the result:

```bash
ls device/xiaomi/amethyst/BoardConfig.mk
ls device/xiaomi/amethyst-kernel/images/kernel
test -f device/xiaomi/amethyst-kernel/kernel-kit.sha256
ls vendor/xiaomi/amethyst/amethyst-vendor.mk
ls hardware/xiaomi
ls device/qcom/sepolicy_vndr/sm8650        # from snippets/lineage.xml
ls hardware/qcom-caf/sm8650                # from snippets/lineage.xml
```

LineageOS supplies the last two paths through `snippets/lineage.xml`.
The local manifest declares each device project once. To verify the included
kernel kit against its checksums, run the following from the source root.

```bash
(cd device/xiaomi/amethyst-kernel && sha256sum --quiet -c kernel-kit.sha256)
```

## 3. Build

```bash
cd ~/android/lineage-23.2
unset OUT_DIR OUT_DIR_COMMON_BASE
. build/envsetup.sh
breakfast amethyst
m -j16 bacon
```

`breakfast` is the LineageOS wrapper: it sets `TARGET_RELEASE` from
`vendor/lineage/vars/aosp_target_release` and calls
`lunch lineage_amethyst-<release>-userdebug`. On Android 16 the two-part
`lunch lineage_amethyst-userdebug` form is rejected with
`Invalid lunch combo`, and calling `lunch` without a release makes the build
fail with `No release config set for target`.

Keep `OUT_DIR` at its default. With some alternate output directories the
kernel header generation and Soong disagree on the location of
`linux/msm_ipa.h`, which breaks `libipanat`. The standard build uses the
published headers and image paths directly.

Useful variants:

```bash
mka installclean          # remove installed files, keep intermediates
mka clean                 # remove intermediates for this product
mka bootimage             # boot image only
mka vendorbootimage       # vendor_boot only
mka recoveryimage         # recovery only
```

### Output

```text
out/target/product/amethyst/
├── lineage-23.2-<date>-UNOFFICIAL-amethyst.zip
├── boot.img
├── init_boot.img
├── recovery.img
├── vendor_boot.img
├── dtbo.img
└── super_empty.img
```

The ZIP is the normal installation artifact. Use the dedicated, slotted
recovery from the matching OTA payload for installation. See
[FLASH.md](FLASH.md) for the partition layout and sideload procedure.

From the configured build shell, extract and hash the matching recovery.

```bash
product="$(get_build_var PRODUCT_OUT)"
zip="$product/lineage-$(get_build_var LINEAGE_VERSION).zip"
install_dir="$product/verified-install"
mkdir -p "$install_dir"
unzip -p "$zip" payload.bin > "$install_dir/payload.bin"
prebuilts/extract-tools/linux-x86/bin/ota_extractor \
    --partitions=recovery --output_dir="$install_dir" \
    --payload="$install_dir/payload.bin"
sha256sum "$zip" "$install_dir/recovery.img"
```

Save the precise revisions for a build using `repo manifest -r -o manifest.xml`.

## 4. ccache (optional, recommended)

```bash
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
ccache -M 50G
ccache -o compression=true
```

Keep the ccache directory outside the source tree if the disk is small, or
clean it with `ccache -C`. A second build of the same tree is usually 3–5×
faster.

## 5. Signing

`m bacon` signs the default unofficial build with AOSP **test keys**.
The device accepts updates signed with the same keys. A change of signing
keys requires preparing the migration separately.

For personal release keys, create `vendor/lineage-priv/keys` (outside the
device tree) and follow the LineageOS signing guide. Never commit the keys.
Official LineageOS builds are signed by the LineageOS infrastructure.

## 6. Common build problems

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md). The three most common ones:

1. **OOM killed** — reduce `-j`, add swap/zram, or use a host with more RAM.
2. **Missing blob** — the vendor repository is incomplete; re-run
   [BLOBS.md](BLOBS.md).
3. **`neverallow` in sepolicy** — a vendor blob needs a rule; add it to
   `sepolicy/vendor`, do not disable the check.
