#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# microG + Aurora Store variant, enabled with WITH_MICROG=true.
#
# The APKs are not kept in git (microG Services is ~108 MB, above GitHub's
# per-file limit); fetch them with microg/fetch-prebuilts.sh first.

# A repo sync can drop the frameworks/base signature-spoofing commit and this
# variant still compiles, boots and installs microG; the only symptom is the
# Self-Check failing on the phone. Checking here, in the product configuration,
# protects a manual `breakfast` + `m` the same way tools/build.sh is protected.
MICROG_PATCH_CHECK := $(shell SRC=$(abspath .) bash device/xiaomi/amethyst/tools/check-microg-patch.sh >/dev/null 2>&1 || echo missing)

ifeq ($(MICROG_PATCH_CHECK),missing)
$(error frameworks/base lost the microG signature-spoofing patch, run git -C frameworks/base am device/xiaomi/amethyst/tools/patches/microg-user-spoofing.patch)
endif

MICROG_PREBUILTS := device/xiaomi/amethyst/microg/prebuilts

ifeq ($(wildcard $(MICROG_PREBUILTS)/GmsCore.apk),)
$(error microG prebuilts are missing, run device/xiaomi/amethyst/microg/fetch-prebuilts.sh before building)
endif

PRODUCT_PACKAGES += \
    MicrogGmsCore \
    MicrogCompanion \
    MicrogGsfProxy \
    AuroraStore \
    microg-gms-privapp-permissions \
    microg-gms-default-permissions \
    microg-gms-sysconfig \
    microg-vending-privapp-permissions \
    microg-vending-default-permissions

# ro.debuggable=1, which LineageOS needs for its native signature spoofing, is
# arranged in lineage_amethyst.mk rather than here: the flag is a single-value
# product variable and an empty value inherited from this node loses against
# vendor/lineage/config/common.mk's non-empty one.
