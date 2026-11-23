# Roadmap

The goal is a clean, documented, reproducible device tree that can eventually
be submitted to LineageOS.

## Phase 0 — Tree hygiene (this repository)

- [x] Import the original bring-up from `amethyst-playground`.
- [x] Add a real README with an indexed documentation set.
- [x] Add `lineage.dependencies` for roomservice.
- [x] Add build, blob, flash and test guides.
- [x] Add helper scripts.
- [x] Add a test matrix with real results ([TESTING.md](TESTING.md)).
- [x] Publish the repository.

## Phase 1 — First boot on LineageOS 23.2

- [x] Build against `lineage-23.2` with the prebuilt kernel.
- [x] Flash on a global `24115RA8EG` running `OS3.0.307.0.WOPMIXM`.
- [x] Boot to the launcher.
- [x] Collect logs and fix build/boot blockers.
- [x] Tag the first working build (`amethyst-23.2-rcd1`).

## Phase 2 — Blob refresh and stabilization

- [x] Extract blobs from `OS3.0.307.0.WOPMIXM`.
- [ ] Update `VENDOR_SECURITY_PATCH`.
- [ ] Rebuild and compare against Phase 1.
- [ ] Fix camera, audio, fingerprint, NFC, eSIM and calls.
- [ ] Complete the test matrix.
- [ ] Publish a “daily driver” build if the matrix allows it.

## Phase 3 — Android 17 / LineageOS 24.0

Only start after Phase 2 is stable.

Changes already known to be required (from the Android 17 ports):

- [ ] `TARGET_GLOBAL_LTO := thin`, `TARGET_GLOBAL_OPTIMIZATION := O3`,
      `TARGET_GLOBAL_THINLTO := true`.
- [ ] `HWUI_COMPILE_FOR_PERF := true`, `TARGET_USES_VULKAN := true`.
- [ ] `TARGET_USE_AOSP_SURFACEFLINGER := true`.
- [ ] `DEVICE_MANIFEST_FILE +=` instead of `:=`.
- [x] Switch from QTI power to `android.hardware.power-service.lineage-libperfmgr`
      (done on 23.2 in `exp/libperfmgr-power`; `libqti-perfd-client` stays the
      vendor blob, see `ARCHITECTURE.md`).
- [ ] 8 GB Dalvik heap (`phone-xhdpi-8192-dalvik-heap.mk`).
- [ ] GKI 6.1.138 prebuilt kernel (or a source-built GKI).
- [ ] New/removed blobs from the newer firmware.
- [ ] Overlays: Aperture, eSIM switcher, NCM tethering, Xiaomi Parts.
- [ ] Re-test the whole matrix.

## Phase 4 — Official LineageOS

- [ ] Public device, vendor and kernel repositories.
- [ ] Kernel source tree that builds from source (GKI + Xiaomi modules).
- [ ] No KernelSU/SUSFS or other out-of-tree root patches in the official
      kernel.
- [ ] Complete test matrix and a maintainer commitment.
- [ ] Wiki page and Hudson build target.
- [ ] Submit to Gerrit and email the LineageOS developer relations team.

See [OFFICIAL.md](OFFICIAL.md) for the exact gaps.

## Explicit non-goals

- Shipping GApps, ViPER, Dolby or other add-ons in the device tree.
- Supporting every regional variant in one build beyond the SKU props that
  already exist.
- Chasing Android 17 before Android 16 is stable.
