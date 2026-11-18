# Design decisions

Short records of why the tree is built this way. Update this file when a
decision changes.

## D001 — Start from `amethyst-playground`, not from a newer fork

The Android 17 forks are useful references, but they carry add-ons (ViPER,
Dolby, MiuiCamera) and a newer firmware base. Starting from the original
bring-up keeps the tree small, reviewable and closer to a clean LineageOS tree.

## D002 — Prebuilt kernel for the first bring-up

The current kernel repository ships a prebuilt GKI `Image`, `dtbo`, DTBs and
vendor modules. This removes the kernel build from the first boot equation and
keeps the vendor modules consistent with the kernel.

Trade-off: an official submission needs a source-built kernel. This is tracked
in [OFFICIAL.md](OFFICIAL.md) and [ROADMAP.md](ROADMAP.md).

## D003 — Local manifest instead of `roomservice`

The device repositories are not in the LineageOS organisation. `breakfast`
cannot find them. The local manifest is explicit, reviewable and works for both
public and private forks.

`lineage.dependencies` is still present because it is required for the official
path.

## D004 — `ext4` for dynamic partitions

The tree builds `system`, `vendor`, `product`, `odm`, `system_ext` and the DLKM
partitions as `ext4`. Stock HyperOS may use EROFS for some of them. `ext4` is
simpler to debug and is already validated by the original bring-up; changing it
is a separate project.

## D005 — Global variant first

The product identity is the global model `24115RA8EG` (`amethyst_global`) and
the SKU properties include `GL`, `IN` and `CN`. Global is the primary target;
other regions are selected by the existing SKU mechanism.

## D006 — Blobs from the latest global stable

The first import used `OS3.0.4.0.WOPMIXM`. New builds target
`OS3.0.307.0.WOPMIXM`, which is the latest global stable at the time of
writing. This reduces camera/audio/modem mismatches on updated devices.

## D007 — Documentation as part of the tree

The original tree had no README, no dependency file and no build/flash/test
documentation. A device tree that cannot be understood by a new contributor is
hard to maintain and impossible to submit. Documentation lives in `docs/` and
is indexed from the README.

## D008 — Public device tree, private keys

The device tree contains no secrets and is derived from public Apache-2.0 work.
Publishing it helps testers and is required for an official submission. Signing
keys, `persist` backups and personal logs stay out of the repository.

## D009 — Android 16 before Android 17

Android 16 (LineageOS 23.2) is the mature base for this device. Android 17
ports exist but are still fixing audio, camera and eSIM. Porting to 24.0 before
23.2 is stable would multiply the variables.

## D010 — Only device-specific repositories in the local manifest

LineageOS `snippets/lineage.xml` already declares the shared Qualcomm trees at
the paths this device uses, including `device/qcom/sepolicy_vndr/sm8650`
(`lineage-23.2-caf-sm8650`) and the `SEPolicy.mk` linkfile generated from
`hardware/qcom-caf/common`. `repo` validates every manifest before syncing and
aborts on `duplicate path`, so the local manifest lists only the four
repositories that LineageOS does not have: the device tree, the kernel, the
vendor blobs and `hardware/xiaomi`.

`lineage.dependencies` was trimmed the same way. It keeps the entries that the
official process needs, and nothing that the default manifest already provides.
