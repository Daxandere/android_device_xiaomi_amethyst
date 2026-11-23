# Signing and release builds

An unofficial build signed with the AOSP **test keys** works, but the phone
notices: *Settings → About phone* reports a build signed with public keys
(`ro.build.tags=test-keys`), Play Protect and banking apps refuse to trust the
platform, and every update has to be signed by the same throwaway keys. Both
problems are fixed with the owner's own release keys, so published ZIPs are
signed with them and built as `user`.

Keys and build variant are independent: `user` decides what the system exposes
(`ro.debuggable=0`, no root), signing decides who certifies the APKs and the OTA.

## 1. Keys

LineageOS already includes `vendor/lineage-priv/keys/keys.mk` from
`vendor/lineage/config/common.mk`, so the keys live next to the source tree
instead of inside the device repository, and no device tree change is needed.
Soong and `keys.conf` look every certificate up in the directory of
`PRODUCT_DEFAULT_DEV_CERTIFICATE`, so the directory needs the full set below:

| Key | Signs |
|---|---|
| `releasekey` | Everything without a more specific certificate (`PRODUCT_DEFAULT_DEV_CERTIFICATE`). |
| `platform` | Packages running with the platform certificate (`Settings`, `framework-res`, system providers). |
| `shared` | Packages that share a `sharedUserId`. |
| `media` | Media stack. |
| `networkstack` | `NetworkStack` and its updatable modules. |
| `sdk_sandbox` | SDK sandbox packages (Android 14 and newer). |
| `bluetooth` | Bluetooth stack modules (Android 15 and newer). |
| `nfc` | `NfcNci` and the NFC apex. |
| `testkey`, `release` | Referenced by `system/sepolicy/private/keys.conf` when `mac_permissions.xml` is built. |

Generate them once, on the build host, and keep the directory backed up:

```bash
cd $SRC
mkdir -p vendor/lineage-priv/keys
cd vendor/lineage-priv/keys
for c in releasekey platform shared media networkstack sdk_sandbox bluetooth nfc \
         testkey release; do
    ../../../development/tools/make_key "$c" \
        '/C=ES/ST=Madrid/L=Madrid/O=Amethyst/OU=LineageOS/CN=Amethyst/' </dev/null
done
printf 'PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/lineage-priv/keys/releasekey\n' > keys.mk
chmod 600 ./*.pk8
```

`make_key` reads one password from standard input; `</dev/null` creates the keys
without a password, which is what the build expects. Change the subject to your
own before running it, and keep the whole directory out of git: `vendor/` is a
separate project and the keys must never be pushed anywhere.

**Losing the keys means no more updates.** A build signed with a new platform
certificate cannot be installed over the old one without wiping data (§4), and
keys cannot be recovered from a build.

## 2. Build

`breakfast` takes the variant as the second argument, so a release build is:

```bash
cd $SRC
. build/envsetup.sh
breakfast amethyst user
TARGET_UNOFFICIAL_BUILD_ID=<tag> m -j32 bacon
```

All of them have to exist in that directory: a missing one fails the build with
`FAILED: ninja: 'vendor/lineage-priv/keys/<name>.x509.pem', needed by …`.

`tools/build.sh` does the same and defaults to `VARIANT=user`; pass
`VARIANT=userdebug` for a debugging build. `breakfast amethyst` without a second
argument still means `userdebug`.

The microG variant keeps `userdebug` on purpose: LineageOS only enables
signature spoofing when `ro.debuggable=1`, and a `user` build would break microG.
See [MICROG.md](MICROG.md); the variant is signed like the others.

## 3. Verify a build

```bash
product=out/target/product/amethyst

# Build variant and key tags baked into the system image.
grep -E '^ro\.build\.(type|tags)=' "$product/system/build.prop"

# The APK certificate must be the release key, not the test key.
apksigner verify --print-certs "$product/product/priv-app/Settings/Settings.apk"
openssl x509 -in vendor/lineage-priv/keys/releasekey.x509.pem -noout -fingerprint -sha256

# The OTA is signed by the same platform key.
unzip -p "$product"/lineage-23.2-*-UNOFFICIAL-*-amethyst.zip META-INF/com/android/otacert \
    | openssl x509 -noout -fingerprint -sha256

# The ZIP and the recovery from the same build.
sha256sum "$product"/lineage-23.2-*-UNOFFICIAL-*-amethyst.zip "$product/recovery.img"
```

Expected: `ro.build.type=user` (or `userdebug` for microG), `ro.build.tags=release-keys`
and the same SHA-256 fingerprint from `apksigner`, the release key and the OTA
certificate.

AVB is not part of this: the boot chain keeps the AOSP test AVB key from
`BoardConfig.mk`, because an unlocked bootloader shows the orange verified-boot
state whatever key the images are signed with.

## 4. Moving an installed phone to the new keys

The platform certificate changes, so the installed system cannot keep its data
and the old recovery will reject the new ZIP (different OTA certificate).

```bash
# With the recovery from the new build, in the active slot.
fastboot getvar current-slot
fastboot flash recovery recovery.img
fastboot reboot recovery
```

In recovery, format data (*Factory reset → Format data / factory reset*) and
then sideload the new ZIP:

```bash
adb sideload lineage-23.2-<date>-UNOFFICIAL-<tag>-amethyst.zip
```

Flash the recovery and the ZIP from the same build; see [FLASH.md](FLASH.md) for
the partition layout and [DOWNLOAD.md](DOWNLOAD.md) for the published files.
