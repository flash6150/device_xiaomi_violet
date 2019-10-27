#!/bin/bash
#
# Copyright (C) 2018-2019 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=violet
VENDOR=xiaomi

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

MK_ROOT="${MY_DIR}"/../../..

HELPER="${MK_ROOT}/vendor/lineage/build/tools/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

SECTION=
KANG=

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

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${MK_ROOT}" true "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" \
        "${KANG}" --section "${SECTION}"

BLOB_ROOT="${MK_ROOT}/vendor/${VENDOR}/${DEVICE}/proprietary"

sed -i "s/android.hidl.base@1.0.so/libhidlbase.so\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00/" "${BLOB_ROOT}/lib64/libfm-hci.so" "${BLOB_ROOT}/lib/libfm-hci.so"
sed -i "s/android.hidl.base@1.0.so/libhidlbase.so\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00/" "${BLOB_ROOT}/lib64/libwfdnative.so" "${BLOB_ROOT}/lib/libwfdnative.so"
sed -i "s/android.hidl.base@1.0.so/libhidlbase.so\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00/" "${BLOB_ROOT}/vendor/bin/hw/vendor.display.color@1.0-service"

patchelf --add-needed "libprocessgroup.so" "${BLOB_ROOT}/vendor/lib/hw/audio.primary.sm6150.so"
patchelf --add-needed "libprocessgroup.so" "${BLOB_ROOT}/vendor/lib64/hw/audio.primary.sm6150.so"

patchelf --remove-needed "vendor.xiaomi.hardware.mtdservice@1.0.so" "${BLOB_ROOT}/vendor/bin/mlipayd@1.1"
patchelf --remove-needed "vendor.xiaomi.hardware.mtdservice@1.0.so" "${BLOB_ROOT}/vendor/lib64/libmlipay.so"
patchelf --remove-needed "vendor.xiaomi.hardware.mtdservice@1.0.so" "${BLOB_ROOT}/vendor/lib64/libmlipay@1.1.so"

"${MY_DIR}/setup-makefiles.sh"
