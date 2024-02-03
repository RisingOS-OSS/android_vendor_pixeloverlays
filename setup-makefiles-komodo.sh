#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
# Copyright (C) 2024 The risingOS Android Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=komodo
VENDOR=pixeloverlays

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" true

# Warning headers and guards
write_headers "arm64"
sed -i 's|TARGET_DEVICE|TARGET_ARCH|g' "${ANDROIDMK}"
sed -i 's|vendor/pixeloverlays/|vendor/pixeloverlays/komodo|g' "${PRODUCTMK}"
sed -i 's|device/pixeloverlays//setup-makefiles.sh|vendor/pixeloverlays/setup-makefiles-komodo.sh|g' "${ANDROIDBP}" "${ANDROIDMK}" "${BOARDMK}" "${PRODUCTMK}"

write_makefiles "${MY_DIR}/proprietary-files-komodo.txt" true

# Finish
write_footers

# Overlays
echo -e "\ninclude vendor/pixeloverlays/komodo/overlays.mk" >> "$PRODUCTMK"
