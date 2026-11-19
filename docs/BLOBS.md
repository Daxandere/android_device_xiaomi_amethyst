# Refreshing the vendor blobs

The vendor repository is generated from a **full** Xiaomi OTA or fastboot ROM.
Never hand-edit generated files.

## What you need

- A full OTA zip or fastboot ROM for the **global** variant:
  `OS3.0.307.0.WOPMIXM` (or newer).
- A synced LineageOS 23.2 source tree, including
  `tools/extract-utils` and `prebuilts/extract-tools`.
- About 30 GB of free disk for the temporary dump.

Incremental OTAs are not enough on their own. Use a full OTA, or chain a full
dump plus incrementals.

## Package verified for this refresh

The archive used to prepare the `OS3.0.307.0.WOPMIXM` blobs was checked before
extraction. The zip itself is not committed; these values are enough to verify a
future download.

| Field | Value |
|---|---|
| File | `amethyst_global-ota_full-OS3.0.307.0.WOPMIXM-user-16.0-d1217882c3.zip` |
| Type | Full OTA (`ota-type=AB`, no `pre-build` key) |
| Size | 6,064,951,297 bytes |
| MD5 | `d1217882c30d2bb7ffd2bf589ddc3011` |
| SHA-256 | `8cebd0794f900cd1fe4722651955d705c52147806f0ee090d2012143b8595901` |
| `payload.bin` | 6,064,942,598 bytes, equal to `FILE_SIZE` in `payload_properties.txt` |
| Fingerprint | `Redmi/amethyst_global/amethyst:16/BP2A.250605.031.A3/16OS3.1.260917.182821572.QCPEGL.S:user/release-keys` |
| Platform security patch | 2026-09-01 (`post-security-patch-level`) |

A delta OTA carries `pre-build` and `post-build` describing two different
releases, and its `payload.bin` is a small set of `SOURCE_COPY` operations
against the installed images. `payload-dumper-go` rejects those with
`unsupported op: SOURCE_COPY`, which is the quickest way to tell them apart
without trusting a filename.


## The vendor repository is already forked

`proprietary_vendor_xiaomi_amethyst` is forked under `Daxandere`, branch
`lineage-23.2`:

```text
https://github.com/Daxandere/proprietary_vendor_xiaomi_amethyst
```

The local manifest points that project at the `mine` remote, so a fresh sync
already gets the refreshed blobs. Nothing else has to be forked for a build.

Refreshing blobs is then a normal commit on that fork:

```bash
cd vendor/xiaomi/amethyst
git checkout lineage-23.2
git add -A
git commit -m "amethyst: Refresh blobs from <firmware>"
git push origin lineage-23.2
```

The build host checks the repository out anonymously, so publishing needs a
credential: a fine-grained token with `Contents: read and write` on that one
repository, revoked right after the push. Reading the tree — what everyone else
does — needs no credentials at all.

If you work from a checkout that still points at the playground remote, repoint
it once with:

```bash
repo sync -c --force-sync vendor/xiaomi/amethyst
```

The extraction rewrites the whole directory, so a stale upstream checkout would
leave you with a fork that cannot be fast-forwarded.

## Procedure

### 1. Verify the download

Compare the MD5/SHA-256 published by Xiaomi with the file:

```bash
sha256sum amethyst_global_OS3.0.307.0.WOPMIXM.zip
```

### 2. Extract the blobs

From the device tree, with `$SRC` as the source root:

```bash
cd $SRC/device/xiaomi/amethyst
./extract-files.py --keep-dump /path/to/amethyst_global_OS3.0.307.0.WOPMIXM.zip
```

What the tool does:

1. Extracts the zip/tar to a temporary dump directory.
2. Finds `payload.bin` (or `super.img`) and extracts the partitions.
3. Unpacks EROFS/EXT4 images.
4. Applies the fixups in `extract-files.py`.
5. Cleans and repopulates `vendor/xiaomi/amethyst`.
6. Regenerates `amethyst-vendor.mk`, `Android.bp` and `BoardConfigVendor.mk`.

`--keep-dump` keeps the temporary dump next to the archive. Delete it when you
are done; do not commit it.

### 3. Check the result

```bash
cd $SRC
git -C vendor/xiaomi/amethyst status --short | head
git -C vendor/xiaomi/amethyst diff --stat | tail -n 5
```

The vendor repository is about 2.8 GB and contains roughly 3,100 files. The
largest file is around 83 MB, below GitHub's 100 MB per-file limit, so Git LFS
is not required.

### 4. Update the metadata

`extract-files.py` updates `proprietary-files.txt`, but two values are manual:

1. The header of `proprietary-files.txt`:

   ```text
   # All unpinned blobs below are extracted from amethyst OS3.0.307.0.WOPMIXM
   ```

2. `VENDOR_SECURITY_PATCH` in `BoardConfig.mk`. Read the real value from the
   dump:

   ```bash
   grep ro.vendor.build.security_patch vendor/build.prop
   ```

   Then set:

   ```make
   VENDOR_SECURITY_PATCH := 2026-10-01
   ```

### 5. Review the diff

Blob refreshes are not always neutral. Check for:

- Camera libraries or firmware removed/renamed by Xiaomi.
- Audio policy files that changed path.
- New libraries that need a `replace_needed`/`add_needed` fixup in
  `extract-files.py`.
- Libraries that no longer exist but are still listed in
  `proprietary-files.txt`.

If a fixup breaks, the build usually fails with a missing `NEEDED` library or a
missing file. Fix the fixup, do not delete the blob.

Two cosmetic items are known and harmless, but worth cleaning during a refresh:

1. `device.mk` copies
   `vendor/etc/seccomp_policy/c2audio.vendor.{base,ext}-arm64.policy` from
   `hardware/qcom-caf/sm8650/audio/primary-hal`, and the vendor blob tree ships
   the same two files byte for byte. The build installs both and prints a
   duplicate-rule warning (tolerated by `BUILD_BROKEN_DUP_RULES`). Keeping only
   the HAL copies is the cleaner end state: drop the two lines from
   `proprietary-files.txt`, delete the two blobs and their `Android.bp` entries.
   `device.mk` itself stays identical to the official sm8650 trees.

2. `extract-files.py` still carries fixups for
   `vendor/etc/media_codecs_volcano_v0.xml` and `vendor/etc/sensors/hals.conf`,
   which are not in `proprietary-files.txt`. `extract-utils` ignores unused
   fixups (it has a TODO to report them), so they are dead code — remove them
   when the surrounding fixups change.

### 6. Build and test

```bash
. build/envsetup.sh
breakfast amethyst
mka bacon -j16
```

Then follow [TESTING.md](TESTING.md). Pay special attention to camera, audio,
fingerprint, NFC and calls.

### 7. Commit

Commit the two repositories separately:

```bash
git -C vendor/xiaomi/amethyst add -A
git -C vendor/xiaomi/amethyst commit -m "amethyst: Update blobs from OS3.0.307.0.WOPMIXM"

git add proprietary-files.txt BoardConfig.mk
git commit -m "amethyst: Target OS3.0.307.0.WOPMIXM"
```

## If the extraction fails

| Error | Fix |
|---|---|
| `payload.bin` not found | The zip is an incremental OTA or a vendor firmware zip. Use the full ROM. |
| `ota_extractor` missing | The source is incomplete; `repo sync prebuilts/extract-tools`. |
| EROFS/EXT4 extraction error | Install `erofs-utils`; check free disk. |
| Python import error | Run from the device tree, with the shebang's `PYTHONPATH`. |
| `java` not found | `prebuilts/jdk/jdk21` is missing; sync it. |
| `path: file not found` | The firmware renamed or dropped the file. Diff the list against the dump before deleting anything (see below). |

### Renamed files are not missing files

`file not found` means the path is wrong, not necessarily that the blob is
gone. Diff the two lists instead of pruning on sight:

```bash
grep -o 'binShaders64/[^:]*\.bin' proprietary-files.txt |
    sed 's|.*/||' | sort -u > /tmp/listed
find ~/amethyst_ota/odm/etc/camera/resources/render/BuildIn/binShaders64 \
    -name '*.bin' -printf '%f\n' | sort -u > /tmp/actual
comm -23 /tmp/listed /tmp/actual   # listed but absent
comm -13 /tmp/listed /tmp/actual   # present but unlisted
```

In `OS3.0.307.0.WOPMIXM` the count stayed at 66, but six shaders dropped the
`_FRAMEBUFFER_FETCH_ADRENO` suffix:

| Old name (`OS3.0.290.0`) | New name (`OS3.0.307.0`) |
|---|---|
| `OGL_BLEND_COLOR_LAYER_WITH_MASK_Define_NORMAL_MASK_CHANNEL_TYPE_R_FRAMEBUFFER_FETCH_ADRENO.bin` | `OGL_BLEND_COLOR_LAYER_WITH_MASK_Define_NORMAL_MASK_CHANNEL_TYPE_R.bin` |
| `OGL_BLEND_IMAGE_LAYER_Define_MULTIPLY_FRAMEBUFFER_FETCH_ADRENO.bin` | `OGL_BLEND_IMAGE_LAYER_Define_MULTIPLY.bin` |
| `OGL_BLEND_IMAGE_LAYER_Define_SOFT_LIGHT_FRAMEBUFFER_FETCH_ADRENO.bin` | `OGL_BLEND_IMAGE_LAYER_Define_SOFT_LIGHT.bin` |
| `OGL_BLEND_IMAGE_LAYER_WITH_MASK_Define_MULTIPLY_MASK_CHANNEL_TYPE_R_FRAMEBUFFER_FETCH_ADRENO.bin` | `OGL_BLEND_IMAGE_LAYER_WITH_MASK_Define_MULTIPLY_MASK_CHANNEL_TYPE_R.bin` |
| `OGL_BLEND_IMAGE_LAYER_WITH_MASK_Define_SOFT_LIGHT_MASK_CHANNEL_TYPE_R_FRAMEBUFFER_FETCH_ADRENO.bin` | `OGL_BLEND_IMAGE_LAYER_WITH_MASK_Define_SOFT_LIGHT_MASK_CHANNEL_TYPE_R.bin` |
| `OGL_NORMAL_LUT_512_512_Define_FRAMEBUFFER_FETCH_ADRENO.bin` | `OGL_NORMAL_LUT_512_512.bin` |

`OGL_RETOUCH_FOGGY_SIMPLE_PROCESS_Define_CHANNEL_R_FRAMEBUFFER_FETCH_ADRENO.bin`
kept its suffix, so do not strip it globally: rename only the six affected
entries.

As a fallback, extract manually with `payload-dumper-go`, unpack the images
with `extract.erofs`/loop mount, and pass the resulting directory to
`extract-files.py`:

```bash
./extract-files.py --keep-dump /path/to/dump-directory
```

## Related documents

- [FIRMWARE.md](FIRMWARE.md) — firmware vs ROM, ARB.
- [ARCHITECTURE.md](ARCHITECTURE.md) — where blobs and fixups live.
