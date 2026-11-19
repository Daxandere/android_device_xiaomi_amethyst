# Contributing

## Scope

This repository is the device tree only. Do not add:

- proprietary blobs (they belong in the vendor repository),
- signing keys or `persist` backups,
- GApps, ViPER, Dolby or other add-ons,
- kernel sources (they belong in a kernel repository),
- generated vendor makefiles.

## Commit style

Use the device prefix, like the rest of the tree:

```text
amethyst: Short imperative description
```

Examples:

```text
amethyst: Update blobs from OS3.0.307.0.WOPMIXM
amethyst: Fix UDFPS enrollment after blob refresh
amethyst: Document firmware base
```

Keep one logical change per commit. Explain the “why” in the body if it is not
obvious.

## Before opening a pull request

1. Build the tree:

   ```bash
   . build/envsetup.sh
   breakfast amethyst
   mka bacon -j16
   ```

2. Flash and test the affected area.
3. Update [docs/TESTING.md](docs/TESTING.md) if the change affects behavior.
4. Attach the relevant logs (not the whole bug report).
5. Mention the firmware version used for the test.

## Bug reports

Include:

- device model and region,
- firmware version,
- build zip name and date,
- exact reproduction steps,
- `logcat`, `dmesg` and `avc` lines if relevant,
- whether the issue also happens on stock.

## Blob changes

Follow [docs/BLOBS.md](docs/BLOBS.md). A blob-only change must include:

- the firmware version it was extracted from,
- the vendor repository commit,
- the updated `VENDOR_SECURITY_PATCH`,
- a note about any fixup changes in `extract-files.py`.

## Licensing

Device tree code is Apache-2.0. By contributing you agree to license your
changes under the same terms. Keep the SPDX headers on new files.
