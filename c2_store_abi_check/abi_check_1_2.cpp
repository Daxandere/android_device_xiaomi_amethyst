//
// SPDX-FileCopyrightText: The LineageOS Project
// SPDX-License-Identifier: Apache-2.0
//

#include <codec2/hidl/1.2/ComponentStore.h>

static_assert(
        sizeof(android::hardware::media::c2::V1_2::utils::ComponentStore) == 288,
        "sizeof(ComponentStore) changed; repatch the QTI c2 service blobs");
