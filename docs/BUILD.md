# Building LineageOS 23.2 for `amethyst`

These instructions assume a **Linux build host**. Windows is not supported for
the build itself (WSL2 may work, but it is not the supported path).

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

## 2. Sync the source

```bash
mkdir -p ~/android/lineage-23.2
cd ~/android/lineage-23.2

repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
```

`--git-lfs` is required: some prebuilts are stored with Git LFS.

## 3. Add the device repositories

The device repositories are not in the LineageOS organisation, so they are
added through a local manifest.

```bash
mkdir -p .repo/local_manifests
git clone https://github.com/Daxandere/local_manifests .repo/local_manifests
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
```

If you prefer not to clone a second repository, copy
`docs/local_manifest.example.xml` to
`.repo/local_manifests/amethyst.xml` instead. It is the same manifest.

The manifest points to:

- `device/xiaomi/amethyst`
- `device/xiaomi/amethyst-kernel`
- `vendor/xiaomi/amethyst`
- `hardware/xiaomi`
- `device/qcom/sepolicy_vndr/sm8650`

Verify the result:

```bash
ls device/xiaomi/amethyst/BoardConfig.mk
ls device/xiaomi/amethyst-kernel/images/kernel
ls vendor/xiaomi/amethyst/amethyst-vendor.mk
ls hardware/xiaomi
ls device/qcom/sepolicy_vndr/sm8650
```

## 4. Build

```bash
cd ~/android/lineage-23.2
. build/envsetup.sh
lunch lineage_amethyst-userdebug
mka bacon -j16
```

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

The zip is the normal installation artifact. The individual images are useful
for debugging and for `fastboot boot`.

## 5. ccache (optional, recommended)

```bash
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
ccache -M 50G
ccache -o compression=true
```

Keep the ccache directory outside the source tree if the disk is small, or
clean it with `ccache -C`. A second build of the same tree is usually 3–5×
faster.

## 6. Signing

`mka bacon` signs unofficial builds with the AOSP **test keys**. That is fine
for testing, but every build has different keys, so you cannot update over a
previous build without wiping.

For personal release keys, create `vendor/lineage-priv/keys` (outside the
device tree) and follow the LineageOS signing guide. Never commit the keys.
Official LineageOS builds are signed by the LineageOS infrastructure.

## 7. Common build problems

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md). The three most common ones:

1. **OOM killed** — reduce `-j`, add swap/zram, or use a host with more RAM.
2. **Missing blob** — the vendor repository is incomplete; re-run
   [BLOBS.md](BLOBS.md).
3. **`neverallow` in sepolicy** — a vendor blob needs a rule; add it to
   `sepolicy/vendor`, do not disable the check.
