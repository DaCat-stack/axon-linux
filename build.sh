#!/usr/bin/env bash
# Сборка ISO AXON Linux. Запускается внутри контейнера archlinux:latest (--privileged).
# Берём официальный профиль archiso "releng" и накладываем поверх него profile/.
set -euo pipefail

"$(cd "$(dirname "$0")" && pwd)/ci/use-mirrors.sh"

ROOT="$(cd "$(dirname "$0")" && pwd)"
PROFILE=/tmp/axon-profile
WORK=/tmp/axon-work
OUT="$ROOT/out"

pacman -Syu --noconfirm --needed archiso grub

rm -rf "$PROFILE" "$WORK"
cp -r /usr/share/archiso/configs/releng "$PROFILE"

# --- Убираем то, что в releng конфликтует с десктопом ---
# сеть делает NetworkManager, а не iwd/systemd-networkd; автологин root на tty1 и sshd не нужны
find "$PROFILE/airootfs/etc/systemd/system" \
    \( -name 'iwd.service' -o -name 'systemd-networkd*' -o -name 'sshd.service' \) -prune -exec rm -rf {} +
rm -rf "$PROFILE/airootfs/etc/systemd/system/getty@tty1.service.d"

# --- multilib (нужен для Steam и 32-битного Wine) ---
sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' "$PROFILE/pacman.conf"
# NoExtract = etc/xdg/autostart/org.kde.plasma-welcome.desktop — у AXON своё приветствие
"$ROOT/ci/pacman-noextract.sh" "$PROFILE/pacman.conf"
cp "$PROFILE/pacman.conf" "$PROFILE/airootfs/etc/pacman.conf"

# --- Репозиторий AXON для live и установленной системы (только подписанные пакеты) ---
awk '!done && /^\[core\]/ {
        print "[axon]\nSigLevel = Required DatabaseRequired\nServer = https://dacat-stack.github.io/axon-repo/axon/$arch\n"; done=1 }
    { print }' "$PROFILE/airootfs/etc/pacman.conf" > "$PROFILE/airootfs/etc/pacman.conf.new"
mv "$PROFILE/airootfs/etc/pacman.conf.new" "$PROFILE/airootfs/etc/pacman.conf"
grep -q '^\[axon\]' "$PROFILE/airootfs/etc/pacman.conf"

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

# --- Меню флешки: в UEFI вместо текстового systemd-boot — GRUB с темой AXON ---
sed -i 's/uefi.systemd-boot/uefi.grub/' "$PROFILE/profiledef.sh"
grep -q "uefi.grub" "$PROFILE/profiledef.sh"
# тема (картинки + шрифты .pf2) — из только что собранного пакета axon-branding;
# mkarchiso кладёт всё из $PROFILE/grub/ (кроме .cfg) в /boot/grub/ на ISO
mkdir -p /tmp/axon-branding-pkg
bsdtar -xf "$(ls "$LOCAL_REPO"/axon-branding-*.pkg.tar.zst | head -1)" -C /tmp/axon-branding-pkg usr/share/grub/themes/axon
mkdir -p "$PROFILE/grub/themes"
cp -r /tmp/axon-branding-pkg/usr/share/grub/themes/axon "$PROFILE/grub/themes/axon"
# у пунктов меню флешки класс arch, у прошивки — uefi-firmware: те же иконки
cp "$PROFILE/grub/themes/axon/icons/axon.png" "$PROFILE/grub/themes/axon/icons/arch.png"
cp "$PROFILE/grub/themes/axon/icons/efi.png" "$PROFILE/grub/themes/axon/icons/uefi-firmware.png"
# графический режим + тема (в releng там «terminal_output console»)
"$ROOT/ci/grub-theme-cfg.sh" "$PROFILE/grub/grub.cfg"

# заставка текстового меню BIOS (syslinux): AXON вместо Arch
cp "$ROOT/branding/syslinux-splash.png" "$PROFILE/syslinux/splash.png"

# --- Брендинг ---

sed -i \
    -e 's|^iso_name=.*|iso_name="axon"|' \
    -e 's|^iso_label=.*|iso_label="AXON_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"|' \
    -e 's|^iso_publisher=.*|iso_publisher="AXON <https://axon-project.ru>"|' \
    -e 's|^iso_application=.*|iso_application="AXON Linux Live"|' \
    "$PROFILE/profiledef.sh"
cat >> "$PROFILE/profiledef.sh" <<'EOF'
file_permissions+=(["/etc/sudoers.d"]="0:0:750" ["/etc/sudoers.d/axon-live"]="0:0:440")
file_permissions+=(["/usr/local/bin/axon-install"]="0:0:755")
file_permissions+=(["/usr/share/axon/target/cleanup.sh"]="0:0:755" ["/etc/skel/Desktop/axon-install.desktop"]="0:0:755")
EOF
grep -rl 'Arch Linux' "$PROFILE"/{syslinux,grub,efiboot} 2>/dev/null \
    | xargs -r sed -i 's/Arch Linux install medium/AXON Linux/g; s/Arch Linux/AXON Linux/g'

mkdir -p "$OUT"
mkarchiso -v -w "$WORK" -o "$OUT" "$PROFILE"
ls -lh "$OUT"
