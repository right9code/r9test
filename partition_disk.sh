#!/bin/bash
set -eux # Keep for debugging if needed, can remove later

# IMPORTANT: Set your target disk device here (e.g., "/dev/vda" or "/dev/nvme0n1")
DISK="/dev/vda" # <--- SET THIS TO YOUR TARGET DISK FOR EACH RUN

# For non-dual-boot (fresh install), uncomment the line below to wipe the disk and create a new GPT:
# parted -s "$DISK" mklabel gpt

# Creating the EFI partition with more precise start/end values (1MiB offset for alignment)
parted -s "$DISK" mkpart primary fat32 1MiB 513MiB
NEW_EFI_PART_NUM=$(parted -s "$DISK" print | grep -E '^\s*[0-9]+' | tail -n 1 | awk '{print $1}')
parted -s "$DISK" set "$NEW_EFI_PART_NUM" esp on

# Creating the Btrfs root partition using the rest of the disk space
parted -s "$DISK" mkpart primary btrfs 513MiB 100%

# Corrected logic to find the new root partition (it will be the last one created by parted)
NEW_ROOT_PART_NUM=$(parted -s "$DISK" print | grep -E '^\s*[0-9]+' | tail -n 1 | awk '{print $1}')

# >>> NEW LOGIC: Dynamically determine partition prefix (p for NVMe, empty for others) <<<
PART_PREFIX=""
if [[ "$DISK" == /dev/nvme* ]]; then
    PART_PREFIX="p"
fi

# Construct partition paths using the determined prefix
EFI_PART="${DISK}${PART_PREFIX}${NEW_EFI_PART_NUM}"
ROOT_PART="${DISK}${PART_PREFIX}${NEW_ROOT_PART_NUM}"

echo "Identified EFI partition: $EFI_PART"
echo "Identified Root partition: $ROOT_PART"

mkfs.fat -F32 "$EFI_PART"
mkfs.btrfs "$ROOT_PART"
