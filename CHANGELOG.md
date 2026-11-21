# Changelog

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
