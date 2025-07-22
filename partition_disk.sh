#!/bin/bash
set -eux # Keep for debugging if needed, can remove later

# IMPORTANT: Confirmed your VM's disk is /dev/vda. Change if this is not your device.
DISK="/dev/vda" 

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

# >>> THE CRUCIAL FIX HERE: REMOVE THE 'p' FROM THE DEVICE PATH CONSTRUCTION <<<
EFI_PART="${DISK}${NEW_EFI_PART_NUM}" # Changed from "${DISK}p${NEW_EFI_PART_NUM}"
ROOT_PART="${DISK}${NEW_ROOT_PART_NUM}" # Changed from "${DISK}p${NEW_ROOT_PART_NUM}"

echo "Identified EFI partition: $EFI_PART"
echo "Identified Root partition: $ROOT_PART"

mkfs.fat -F32 "$EFI_PART"
mkfs.btrfs "$ROOT_PART"
