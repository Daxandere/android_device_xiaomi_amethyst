#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# microG + Aurora Store variant, enabled with WITH_MICROG=true.
#
# The APKs are not kept in git (microG Services is ~108 MB, above GitHub's
# per-file limit); fetch them with microg/fetch-prebuilts.sh first.

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
