#!/bin/bash

# This must ran on the destination image

set -ouex pipefail

K_VERSION=$(ls /ctx/files/system_files/kernel/lib/modules/ | head -n 1)
CPIO="busybox cpio"

SOURCE_MODULES="/ctx/files/system_files/kernel/lib/modules/${K_VERSION}"
SOURCE_VMLINUZ="/ctx/files/system_files/kernel/boot/vmlinuz"

if [ -z "$K_VERSION" ]; then
    echo "ERROR: Something when wrong with the kernel-fetcher..."
    exit 1
fi

# Modules check (Ensure kernel-fetch ran successfully)
if [ ! -d "$SOURCE_MODULES" ]; then
    echo "ERROR: Source modules not found at $SOURCE_MODULES"
    echo "Current contents of /ctx/files/system_files/kernel/lib/modules/:"
    ls -l /ctx/files/system_files/kernel/lib/modules/ || echo "Directory does not exist"
    exit 1
fi

# GnomeOS/bootc target paths
TARGET_INITRAMFS="/usr/lib/modules/${K_VERSION}/initramfs.img"
TARGET_VMLINUZ="/usr/lib/modules/${K_VERSION}/vmlinuz"

# Create target dir
mkdir -p "/usr/lib/modules/${K_VERSION}"

TEMPLATE_INITRAMFS="$(find /usr/lib/modules -name "initramfs.img" | head -n 1)"

INITRAMFS_EXTRACT_BLOCK_FILE="$(mktemp)"
INITRAMFS_EXTRACT_DIR="$(mktemp -d)"
NEW_INITRAMFS_BLOCK_FILE="$(mktemp)"

# --- Extraction Logic ---
INITIAL_BLOCK="$(cd "$(mktemp -d)" && ${CPIO} -idvm < "${TEMPLATE_INITRAMFS}" 2>&1 | tail -n 1 | cut -f1 -d' ')"
dd if="${TEMPLATE_INITRAMFS}" skip="${INITIAL_BLOCK}" of="${INITRAMFS_EXTRACT_BLOCK_FILE}"

mkdir -p "${INITRAMFS_EXTRACT_DIR}"
cd "${INITRAMFS_EXTRACT_DIR}"
zstdcat "${INITRAMFS_EXTRACT_BLOCK_FILE}" | ${CPIO} -idmv

# Swap the Modules
rm -rf "${INITRAMFS_EXTRACT_DIR}/usr/lib/modules/"*
mkdir -p "${INITRAMFS_EXTRACT_DIR}/usr/lib/modules/${K_VERSION}"
cp -av "${SOURCE_MODULES}/." "${INITRAMFS_EXTRACT_DIR}/usr/lib/modules/${K_VERSION}/"

# Decompress modules and run depmod
find "${INITRAMFS_EXTRACT_DIR}/usr/lib/modules/${K_VERSION}" -name "*.ko.zst" -exec zstd -d --rm {} +
depmod -b "${INITRAMFS_EXTRACT_DIR}" "${K_VERSION}"

# Ostree support (not tested)
mkdir -p "${INITRAMFS_EXTRACT_DIR}/usr/lib/ostree"
cp /usr/lib/ostree/ostree-prepare-root "${INITRAMFS_EXTRACT_DIR}/usr/lib/ostree/"
ldd /usr/lib/ostree/ostree-prepare-root | grep -o '/[^ ]*' | xargs -I '{}' cp --parents -n -v '{}' "${INITRAMFS_EXTRACT_DIR}/"
cp /usr/lib/systemd/system/ostree-prepare-root.service "${INITRAMFS_EXTRACT_DIR}/usr/lib/systemd/system/"
ln -sf /usr/lib/systemd/system/ostree-prepare-root.service "${INITRAMFS_EXTRACT_DIR}/usr/lib/systemd/system/initrd-root-fs.target.wants/"

# Re-pack
find . | ${CPIO} -o -H newc > "$NEW_INITRAMFS_BLOCK_FILE"
zstd -19 -T0 "$NEW_INITRAMFS_BLOCK_FILE" -o "${NEW_INITRAMFS_BLOCK_FILE}.zst"

HEADER_SIZE=$((INITIAL_BLOCK * 512))

dd if="${TEMPLATE_INITRAMFS}" of="${TARGET_INITRAMFS}" bs=1 count="${HEADER_SIZE}" conv=notrunc
cat "${NEW_INITRAMFS_BLOCK_FILE}.zst" >> "${TARGET_INITRAMFS}"

# Copy the vmlinuz
cp -v "${SOURCE_VMLINUZ}" "${TARGET_VMLINUZ}"

# Modules handling
cp -av "${SOURCE_MODULES}/." "/usr/lib/modules/${K_VERSION}/"
depmod -a "${K_VERSION}" -b /

# Remove old kernel
find /usr/lib/modules -mindepth 1 -maxdepth 1 -type d ! -name "$K_VERSION" -exec rm -rf {} +
