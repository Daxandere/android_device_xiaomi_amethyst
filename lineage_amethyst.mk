#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# Inherit from amethyst device
$(call inherit-product, device/xiaomi/amethyst/device.mk)

# LineageOS gates microG's signature spoofing on Build.isDebuggable(), and
# vendor/lineage/config/common.mk sets PRODUCT_NOT_DEBUGGABLE_IN_USERDEBUG to
# keep ro.debuggable=0 on userdebug builds. That variable takes a single value,
# and the product DAG merges it by letting the last non-empty branch win, so an
# empty value inherited from device.mk is discarded in favour of common.mk's
# "true". Clearing it here, after every inheritance has been recorded, is the
# only place where it sticks. WITH_ADB_INSECURE is deliberately not used: it
# would also set ro.adb.secure=0.
ifneq ($(WITH_MICROG),)
PRODUCT_NOT_DEBUGGABLE_IN_USERDEBUG :=
endif

PRODUCT_NAME := lineage_amethyst
PRODUCT_DEVICE := amethyst
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_BRAND := Redmi
PRODUCT_MODEL := 24115RA8EG

PRODUCT_SYSTEM_NAME := amethyst_global
PRODUCT_SYSTEM_DEVICE := amethyst

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="amethyst_global-user 16 BP2A.250605.031.A3 16OS3.1.260917.182821572.QCPEGL.S release-keys" \
    BuildFingerprint=Redmi/amethyst_global/amethyst:16/BP2A.250605.031.A3/16OS3.1.260917.182821572.QCPEGL.S:user/release-keys \
    DeviceName=$(PRODUCT_SYSTEM_DEVICE) \
    DeviceProduct=$(PRODUCT_SYSTEM_NAME)

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi
