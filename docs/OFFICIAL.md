# Path to an official LineageOS device

This is a checklist, not a promise. LineageOS accepts devices case by case.

## What LineageOS asks for

From the public submission page:

1. The device must meet the project's device support requirements (charter).
2. A maintainer who will continue supporting the device: bug fixes, security
   updates, performance work.
3. An email to developer relations with:
   - links to the device, vendor and kernel trees,
   - the email addresses of every maintainer.

After acceptance:

4. A wiki page for the device.
5. A patch to the `hudson` project adding the device to `lineage_build_targets`.
6. Gerrit review for the device tree.

## Current gaps in this tree

| Requirement | Status | Action |
|---|---|---|
| Public device tree | 🔧 | Publish this repository. |
| Public vendor tree | ⬜ | Fork `proprietary_vendor_xiaomi_amethyst`. |
| Public kernel tree | ⚠️ | Current kernel repo is **prebuilt**. Needs a source tree. |
| `lineage.dependencies` | ✅ | Added. Update names when the repos move. |
| Device wiki page | ⬜ | Write after the first stable build. |
| Test matrix | 🔧 | Fill [TESTING.md](TESTING.md). |
| Maintainer commitment | ⬜ | Decide who maintains it long-term. |
| Clean kernel (no root patches) | ⬜ | If using an OSS kernel, remove KernelSU/SUSFS. |

## The kernel problem

The current kernel repository (`android_device_xiaomi_amethyst-kernel`) contains:

- `images/kernel`, `images/dtbo.img`, `images/dtbs/`
- `modules/vendor_dlkm`, `modules/vendor_boot`, `modules/system_dlkm`
- `kernel-headers/`

It does **not** contain kernel sources. That is fine for an unofficial
bring-up, but it is a weak point for an official submission.

There is community work on a source-built GKI kernel
(`TechAmethyst`-style, based on Google's `android14-6.1` tags). For LineageOS:

- Start from a clean GKI tree.
- Keep the KMI compatible so Xiaomi's prebuilt vendor modules load.
- Drop KernelSU, SUSFS and any other out-of-tree root patches.
- Add the required Xiaomi modules and device tree fragments.
- Document the exact tag and build command.

## Suggested order

1. Stabilize 23.2 and publish reproducible builds.
2. Refresh blobs from the latest global firmware.
3. Build a clean GKI kernel from source and switch the device tree to it.
4. Publish the vendor repository.
5. Write the wiki page.
6. Submit the trees to Gerrit.
7. Email developer relations.

## Things that will be rejected

- Private repositories.
- A vendor tree without a matching blob list and fixups.
- A kernel that cannot be rebuilt from source.
- A device tree that depends on another team's private repository.
- Shipping proprietary apps or root solutions in the tree.

## Reference

- <https://wiki.lineageos.org/submitting_device.html>
- <https://wiki.lineageos.org/contributing.html>
- <https://wiki.lineageos.org/device_requests.html>
