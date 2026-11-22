# Changelog

## 2026-11-22 — Release candidate 1

- Integrate the `android.hardware.power-service.lineage-libperfmgr` power HAL
  with the GPU, DDR and L3 boosts, the `cpu_dma_latency` default the kernel
  accepts and the L3 frequency the node accepts.
- Expose the 60–120 Hz refresh range in Display settings, hide the smooth
  display switch and record the 120 Hz jank A/B in
  [DISPLAY-TESTING.md](docs/DISPLAY-TESTING.md).
- Camera: restore the Aperture overlay (auxiliary lenses, main and front
  1080p60), enable the third-party EIS2 with the stock CamX profiles and cap
  the macro sensor's video profiles at 720p.
- Known issues: 2160p video with the 0.7× lens still closes Aperture, and
  1080p recording with stabilization active can show corrupted chroma. The
  branch inventory and the pending tests are in
  [BRANCHES.md](docs/BRANCHES.md).

## 2026-11-20 — Integrated Global 307 build

- Sync the Global 307 kernel, DTBs, DTBO and matching modules through the
  published local manifest. The device tree builds with these inputs directly.
- Integrate the StrongBox and Weaver policy and the tested camera settings
  with the matching vendor makefile.
- Record functional calls, SMS, cellular data, Wi-Fi, hotspot, Bluetooth,
  Bluetooth in the car, screen-off fingerprint unlock, in-call proximity
  and USB. Record the EIS limitation and pending tests in [TESTING.md](docs/TESTING.md).

## 2026-11-18 — Tree hygiene and documentation

- Import the `lineage-23.2` tree from `amethyst-playground`.
- Add a full README with an indexed documentation set.
- Add `docs/ARCHITECTURE.md`, `BUILD.md`, `FIRMWARE.md`, `BLOBS.md`,
  `FLASH.md`, `TESTING.md`, `TROUBLESHOOTING.md`, `ROADMAP.md`, `OFFICIAL.md`
  and `DECISIONS.md`.
- Add `lineage.dependencies` for roomservice.
- Add helper scripts under `tools/` for host checks, syncing, building,
  blob extraction and log collection.
- Add `.gitattributes`, `.gitignore`, `CONTRIBUTING.md` and `CREDITS.md`.
- Document the blob refresh from `OS3.0.307.0.WOPMIXM`.

## 2026-07-02 — Original import

- Last upstream commit: `amethyst: Remove virtual framebuffer`.
- Base: `lineage-23.2`, firmware `OS3.0.4.0.WOPMIXM`.
