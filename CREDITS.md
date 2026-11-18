# Credits

This tree is a continuation of the original community bring-up for the Redmi
Note 14 Pro+ 5G (`amethyst`).

## Original bring-up

- [`amethyst-playground`](https://github.com/amethyst-playground) — device tree,
  kernel, vendor blobs, hardware/xiaomi and CAF sepolicy.

Top contributors in the git history:

- AdarshGrewal
- Mikazuuu07
- Michael Bestas
- Arian
- LuK1337
- danielml
- Cosmin Tanislav
- Danny Lin
- Yumi Yukimura

See `git shortlog -sne --all` for the complete list.

## Android 17 references

- [`BluedMC-Amethyst`](https://github.com/BluedMC-Amethyst) — `seventeen`
  device tree, kernel and local manifest.
- [`Novicio-2309`](https://github.com/Novicio-2309) — `seventeen` device tree
  and test builds.

These were used as references for the platform changes required by Android 17.
No code is copied without attribution; commits retain their original authors.

## LineageOS

- LineageOS project and the device maintainers whose work is the base of this
  tree.
- `hardware/qcom-caf`, `hardware/xiaomi` and the CAF sepolicy repositories.

## Xiaomi

- The stock HyperOS firmware and the proprietary blobs, which remain the
  property of their respective owners.

## Tooling

- `extract_utils` and the LineageOS build system.
- `payload-dumper-go` and `erofs-utils`, used for manual blob extraction.
