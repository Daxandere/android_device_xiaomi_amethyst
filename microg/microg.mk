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

# LineageOS gates its native signature spoofing on Build.isDebuggable(), and
# vendor/lineage/config/common.mk forces ro.debuggable=0 on userdebug builds
# unless WITH_ADB_INSECURE is set. Clearing the flag is the only way to keep
# ro.debuggable=1 without also disabling ADB authentication.
PRODUCT_NOT_DEBUGGABLE_IN_USERDEBUG :=
