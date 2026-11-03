#!/usr/bin/env bash
# snapshots.sh: на ext4 ничего не делает; на btrfs — конфиг snapper, хук overlay в initramfs, таймеры.
set -euo pipefail
cd "$(dirname "$0")/.."
SCRIPT=$PWD/profile/airootfs/usr/share/axon/target/snapshots.sh
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/bin"
printf '#!/bin/sh\necho "$FAKE_FS"\n' > "$tmp/bin/findmnt"
printf '#!/bin/sh\necho "$@" >> "$SYSTEMCTL_LOG"\n' > "$tmp/bin/systemctl"
chmod +x "$tmp/bin/"*
export PATH="$tmp/bin:$PATH" SYSTEMCTL_LOG="$tmp/systemctl.log"

mkroot() {
    rm -rf "$tmp/root"; mkdir -p "$tmp/root/etc"
    echo 'HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck plymouth)' > "$tmp/root/etc/mkinitcpio.conf"
    : > "$SYSTEMCTL_LOG"
}

# ext4: ничего не меняется
mkroot; FAKE_FS=ext4 ROOT="$tmp/root" bash "$SCRIPT"
[ ! -e "$tmp/root/etc/snapper/configs/root" ] || { echo "ext4: не должно быть конфига snapper"; exit 1; }
[ ! -s "$SYSTEMCTL_LOG" ] || { echo "ext4: не должно быть systemctl"; exit 1; }
grep -q 'plymouth)$' "$tmp/root/etc/mkinitcpio.conf" || { echo "ext4: HOOKS изменились"; exit 1; }

# btrfs: всё настроено
mkroot; FAKE_FS=btrfs ROOT="$tmp/root" bash "$SCRIPT"
c="$tmp/root/etc/snapper/configs/root"
grep -qx 'NUMBER_LIMIT="10"' "$c" || { echo "нет NUMBER_LIMIT=10"; exit 1; }
grep -qx 'TIMELINE_LIMIT_DAILY="5"' "$c" || { echo "нет TIMELINE_LIMIT_DAILY=5"; exit 1; }
grep -qx 'SNAPPER_CONFIGS="root"' "$tmp/root/etc/conf.d/snapper" || { echo "нет SNAPPER_CONFIGS"; exit 1; }
grep -q 'plymouth grub-btrfs-overlayfs)$' "$tmp/root/etc/mkinitcpio.conf" || { echo "нет хука grub-btrfs-overlayfs в конце HOOKS"; exit 1; }
for u in snapper-timeline.timer snapper-cleanup.timer grub-btrfsd.service; do
    grep -q "enable $u" "$SYSTEMCTL_LOG" || { echo "не включён $u"; exit 1; }
done

grep -qx 'GRUB_BTRFS_SUBMENUNAME="Вернуться к снимку"' "$tmp/root/etc/default/grub-btrfs/config" || { echo "нет русского названия снимков"; exit 1; }

# повторный запуск не дублирует хук
FAKE_FS=btrfs ROOT="$tmp/root" bash "$SCRIPT"
[ "$(grep -o grub-btrfs-overlayfs "$tmp/root/etc/mkinitcpio.conf" | wc -l | tr -d ' ')" = 1 ] || { echo "хук продублирован"; exit 1; }
echo PASS
