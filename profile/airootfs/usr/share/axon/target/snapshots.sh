#!/bin/sh
# AXON: снимки и откат из меню загрузки — только если корень на btrfs.
# Запускает Calamares (shellprocess@snapshots) в chroot после initcpiocfg, до initcpio.
ROOT="${ROOT:-/}"
T=/usr/share/axon/target
[ -f "$T/snapper-root" ] || T="$(dirname "$0")"     # в тестах шаблон рядом со скриптом

[ "$(findmnt -no FSTYPE /)" = btrfs ] || exit 0

mkdir -p "$ROOT/etc/snapper/configs"
install -m640 "$T/snapper-root" "$ROOT/etc/snapper/configs/root"
mkdir -p "$ROOT/etc/conf.d"
echo 'SNAPPER_CONFIGS="root"' > "$ROOT/etc/conf.d/snapper"

# загрузка в снимок (он только для чтения) — поверх него временный слой, чтобы KDE стартовал
grep -q 'grub-btrfs-overlayfs' "$ROOT/etc/mkinitcpio.conf" ||
    sed -i.bak -E '/^HOOKS=/ s/\)$/ grub-btrfs-overlayfs)/' "$ROOT/etc/mkinitcpio.conf"
rm -f "$ROOT/etc/mkinitcpio.conf.bak"

for unit in snapper-timeline.timer snapper-cleanup.timer grub-btrfsd.service; do
    systemctl enable "$unit"
done
exit 0
