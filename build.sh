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

# --- Пакеты из AUR (Calamares) — локальный репозиторий только для сборки ---
LOCAL_REPO=/tmp/axon-repo
"$ROOT/ci/build-aur.sh" "$LOCAL_REPO"
"$ROOT/ci/build-packages.sh" "$LOCAL_REPO"
repo-add "$LOCAL_REPO/axon-local.db.tar.gz" "$LOCAL_REPO"/axon-*.pkg.tar.zst
if [ -f "$LOCAL_REPO/axon-local.db.tar.gz" ]; then
    awk -v repo="$LOCAL_REPO" '!done && /^\[core\]/ {
            print "[axon-local]\nSigLevel = Optional TrustAll\nServer = file://" repo "\n"; done=1 }
        { print }' "$PROFILE/pacman.conf" > "$PROFILE/pacman.conf.new"
    mv "$PROFILE/pacman.conf.new" "$PROFILE/pacman.conf"
fi

# --- Наши файлы и пакеты ---
cp -a "$ROOT/profile/airootfs/." "$PROFILE/airootfs/"
cat "$PROFILE/packages.x86_64" "$ROOT/profile/packages.x86_64" \
    | sed 's/#.*//; s/[[:space:]]//g; /^$/d' | sort -u > "$PROFILE/packages.tmp"
mv "$PROFILE/packages.tmp" "$PROFILE/packages.x86_64"

# --- Анимация загрузки: хук plymouth в initramfs и «quiet splash» в меню загрузки ---
"$ROOT/ci/add-plymouth-hook.sh" "$PROFILE/airootfs/etc/mkinitcpio.conf.d/archiso.conf"
for f in "$PROFILE"/syslinux/*.cfg "$PROFILE"/grub/*.cfg "$PROFILE"/efiboot/loader/entries/*.conf; do
    sed -i '/archisobasedir=/{/accessibility/!s/$/ quiet splash/}' "$f"
done

# --- Брендинг ---
sed -i \
    -e 's|^iso_name=.*|iso_name="axon"|' \
    -e 's|^iso_label=.*|iso_label="AXON_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"|' \
    -e 's|^iso_publisher=.*|iso_publisher="AXON <https://axon-project.ru>"|' \
    -e 's|^iso_application=.*|iso_application="AXON Linux Live"|' \
    "$PROFILE/profiledef.sh"
cat >> "$PROFILE/profiledef.sh" <<'EOF'
file_permissions+=(["/etc/sudoers.d"]="0:0:750" ["/etc/sudoers.d/axon-live"]="0:0:440")
file_permissions+=(["/usr/bin/axon-welcome"]="0:0:755" ["/usr/local/bin/axon-install"]="0:0:755")
file_permissions+=(["/usr/share/axon/target/cleanup.sh"]="0:0:755" ["/etc/skel/Desktop/axon-install.desktop"]="0:0:755")
EOF
grep -rl 'Arch Linux' "$PROFILE"/{syslinux,grub,efiboot} 2>/dev/null \
    | xargs -r sed -i 's/Arch Linux install medium/AXON Linux/g; s/Arch Linux/AXON Linux/g'

mkdir -p "$OUT"
mkarchiso -v -w "$WORK" -o "$OUT" "$PROFILE"
ls -lh "$OUT"
