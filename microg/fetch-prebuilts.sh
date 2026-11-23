#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Fetch the APKs used by the WITH_MICROG=true variant.
#
# They are not committed because microG Services alone is ~108 MB, above
# GitHub's 100 MB per-file limit. Every file is pinned to an upstream release
# and verified against a SHA-256 before the build uses it.

set -euo pipefail

MICROG_TAG="v0.3.18.252432"
AURORA_VERSION="4.8.4"

OUT_DIR="$(cd "$(dirname "$0")" && pwd)/prebuilts"
mkdir -p "$OUT_DIR"

# file|url|sha256
SOURCES="
GmsCore.apk|https://github.com/microg/GmsCore/releases/download/${MICROG_TAG}/com.google.android.gms-252432036.apk|1094fa60ace2367ac52bd08d1bd4f33fa8144ba930e355121b28234b8ebbf382
FakeStore.apk|https://github.com/microg/GmsCore/releases/download/${MICROG_TAG}/com.android.vending-84022636.apk|3f1bde2f72bca746fbb53b61a32c2a85fcb026f886ee96d6fe9a05de9a6c6d5b
GsfProxy.apk|https://github.com/microg/GsfProxy/releases/download/v0.1.0/GsfProxy.apk|86891b174301f06a1c84187b545a0a2a57044c6b768f3e84e865908743349692
AuroraStore.apk|https://gitlab.com/-/project/6922885/uploads/245eec8867a47057cbc54535f73b32ee/AuroraStore-${AURORA_VERSION}.apk|8a1ed9aa09631290da91cb793e0517b0f20dc70239ac94ae6682cd94f91a4bad
"

fail=0
for entry in $SOURCES; do
    name="${entry%%|*}"
    rest="${entry#*|}"
    url="${rest%%|*}"
    want="${rest##*|}"
    dest="$OUT_DIR/$name"

    if [ -f "$dest" ] && [ "$(sha256sum "$dest" | cut -d' ' -f1)" = "$want" ]; then
        printf 'ok      %s\n' "$name"
        continue
    fi

    printf 'fetch   %s\n' "$name"
    if ! curl -fSL --retry 3 -o "$dest.part" "$url"; then
        printf 'ERROR   could not download %s from %s\n' "$name" "$url" >&2
        rm -f "$dest.part"
        fail=1
        continue
    fi

    got="$(sha256sum "$dest.part" | cut -d' ' -f1)"
    if [ "$got" != "$want" ]; then
        printf 'ERROR   %s checksum mismatch\n  want %s\n  got  %s\n' "$name" "$want" "$got" >&2
        rm -f "$dest.part"
        fail=1
        continue
    fi

    mv "$dest.part" "$dest"
    printf 'ok      %s\n' "$name"
done

if [ "$fail" -ne 0 ]; then
    printf 'One or more prebuilts are missing; not safe to build.\n' >&2
    exit 1
fi

cat <<EOF

microG Services   ${MICROG_TAG}
microG Companion  ${MICROG_TAG}
Aurora Store      ${AURORA_VERSION}

Build the variant with:
  WITH_MICROG=true TARGET_UNOFFICIAL_BUILD_ID=rcd1-microg breakfast amethyst
  WITH_MICROG=true TARGET_UNOFFICIAL_BUILD_ID=rcd1-microg m -j32 bacon
EOF
