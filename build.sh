#!/usr/bin/env bash
# Сборка ISO AXON Linux. Запускается внутри контейнера archlinux:latest (--privileged).
# Берём официальный профиль archiso "releng" и накладываем поверх него profile/.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PROFILE=/tmp/axon-profile
WORK=/tmp/axon-work
OUT="$ROOT/out"

pacman -Syu --noconfirm --needed archiso

rm -rf "$PROFILE" "$WORK"
cp -r /usr/share/archiso/configs/releng "$PROFILE"

# --- Убираем то, что в releng конфликтует с десктопом ---
# сеть делает NetworkManager, а не iwd/systemd-networkd; автологин root на tty1 и sshd не нужны
find "$PROFILE/airootfs/etc/systemd/system" \
    \( -name 'iwd.service' -o -name 'systemd-networkd*' -o -name 'sshd.service' \) -prune -exec rm -rf {} +
rm -rf "$PROFILE/airootfs/etc/systemd/system/getty@tty1.service.d"

# --- multilib (нужен для Steam и 32-битного Wine) ---
sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' "$PROFILE/pacman.conf"
cp "$PROFILE/pacman.conf" "$PROFILE/airootfs/etc/pacman.conf"

# --- Наши файлы и пакеты ---
cp -a "$ROOT/profile/airootfs/." "$PROFILE/airootfs/"
cat "$PROFILE/packages.x86_64" "$ROOT/profile/packages.x86_64" \
    | sed 's/#.*//; s/[[:space:]]//g; /^$/d' | sort -u > "$PROFILE/packages.tmp"
mv "$PROFILE/packages.tmp" "$PROFILE/packages.x86_64"

# --- Брендинг ---
sed -i \
    -e 's|^iso_name=.*|iso_name="axon"|' \
    -e 's|^iso_label=.*|iso_label="AXON_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"|' \
    -e 's|^iso_publisher=.*|iso_publisher="AXON <https://axon-project.ru>"|' \
    -e 's|^iso_application=.*|iso_application="AXON Linux Live"|' \
    "$PROFILE/profiledef.sh"
cat >> "$PROFILE/profiledef.sh" <<'EOF'
file_permissions+=(["/etc/sudoers.d"]="0:0:750" ["/etc/sudoers.d/axon-live"]="0:0:440")
EOF
grep -rl 'Arch Linux' "$PROFILE"/{syslinux,grub,efiboot} 2>/dev/null \
    | xargs -r sed -i 's/Arch Linux install medium/AXON Linux/g; s/Arch Linux/AXON Linux/g'

mkdir -p "$OUT"
mkarchiso -v -w "$WORK" -o "$OUT" "$PROFILE"
ls -lh "$OUT"
