#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
# Copyright (C) 2024 The risingOS Android Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

read -p "Enter the device codename: " DEVICE
if [ -z "${DEVICE}" ]; then
    echo "Device codename cannot be empty!"
    exit 1
fi

VENDOR=pixeloverlays

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

ANDROID_ROOT="${MY_DIR}/../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
       product/overlay/*apk)
            starletMagic $1 $2 &
            ;;
    esac
}

function starletMagic() {
    folder=${2/.apk/}
    echo "    "${folder##*/} "\\" >> "${MY_DIR}/${DEVICE}/overlays.mk"
    apktool -q d "$2" -o $folder -f
    rm -rf $2 $folder/{apktool.yml,original,res/values/public.xml,unknown}
    cp ${MY_DIR}/overlay-template.txt $folder/Android.bp
    sed -i "s|dummy|${folder##*/}|g" $folder/Android.bp
    find $folder -type f -name default_wallpaper.png -exec rm {} \;
    find $folder -type f -name AndroidManifest.xml -exec sed -i "s|extractNativeLibs\=\"false\"|extractNativeLibs\=\"true\"|g" {} \;
    for file in $(find $folder/res -name *xml ! -path "$folder/res/raw" ! -path "$folder/res/drawable*" ! -path "$folder/res/xml"); do
        for tag in $(cat exclude-tag.txt); do
            type=$(echo $tag | cut -d: -f1)
            node=$(echo $tag | cut -d: -f2)
            xmlstarlet ed -L -d "/resources/$type[@name="\'$node\'"]" $file
            xmlstarlet fo -s 4 $file > $file.bak
            mv $file.bak $file
        done
        sed -i "s|\?android:\^attr-private|\@\*android\:attr|g" $file
        sed -i "s|\@android\:color|\@\*android\:color|g" $file
        sed -i "s|\^attr-private|attr|g" $file
    done
    if [[ "${folder}" == *SimAppDialogOverlay* ]]; then
        for sim_file in $(find $folder/res -name '\$*'); do
            new_name=$(echo $sim_file | sed 's/\$//g')
            mv "$sim_file" "$new_name"
        done
        illo_sim_app_dialog="${folder}/res/drawable/illo_sim_app_dialog.xml"
        if [ -f "$illo_sim_app_dialog" ]; then
            sed -i 's/\$//g' "$illo_sim_app_dialog"
        fi
    fi
    if [[ "${folder}" == *PixelSetupWizardOverlay2024* ]]; then
        for deferred_file in $(find $folder/res -name '\$*'); do
            new_name=$(echo $deferred_file | sed 's/\$//g')
            mv "$deferred_file" "$new_name"
        done
        deferred_setup_welcome_illustration="${folder}/res/drawable/deferred_setup_welcome_illustration__0.xml"
        assistant_icon="${folder}/res/drawable/assistant_icon__0.xml"
        if [ -f "${folder}/res/drawable/deferred_setup_welcome_illustration.xml" ]; then
            sed -i 's/\$deferred_setup_welcome_illustration__0/deferred_setup_welcome_illustration__0/g' "${folder}/res/drawable/deferred_setup_welcome_illustration.xml"
        fi
        if [ -f "${folder}/res/drawable-night/deferred_setup_welcome_illustration.xml" ]; then
            sed -i 's/\$deferred_setup_welcome_illustration__0/deferred_setup_welcome_illustration__0/g' "${folder}/res/drawable-night/deferred_setup_welcome_illustration.xml"
        fi
        if [ -f "${folder}/res/drawable/assistant_icon.xml" ]; then
            sed -i 's/\$assistant_icon__0/assistant_icon__0/g' "${folder}/res/drawable/assistant_icon.xml"
        fi
    fi
}

if [ -z "$SRC" ]; then
    echo "Path to system dump not specified! Specify one with --path"
    exit 1
fi

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

echo "PRODUCT_PACKAGES += \\" > "${MY_DIR}/${DEVICE}/overlays.mk"

extract "${MY_DIR}/proprietary-files-${DEVICE}.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh" "${DEVICE}"

echo "Waiting for extraction"
wait
echo "Overlays extracted"
