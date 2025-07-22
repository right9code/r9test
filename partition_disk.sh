#!/bin/bash
DISK="/dev/vda"
# For non-dual-boot (fresh install), uncomment the line below to wipe the disk and create a new GPT:
# parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart primary fat32 0% 512MiB
NEW_EFI_PART_NUM=$(parted -s "$DISK" print | grep -E '^\s*[0-9]+' | tail -n 1 | awk '{print $1}')
parted -s "$DISK" set "$NEW_EFI_PART_NUM" esp on
parted -s "$DISK" mkpart primary btrfs 512MiB 100%
EFI_PART="${DISK}p${NEW_EFI_PART_NUM}"
NEW_ROOT_PART_NUM=$(parted -s "$DISK" print | grep 'btrfs' | tail -n 1 | awk '{print $1}')
ROOT_PART="${DISK}p${NEW_ROOT_PART_NUM}"
mkfs.fat -F32 "$EFI_PART"
mkfs.btrfs "$ROOT_PART"
