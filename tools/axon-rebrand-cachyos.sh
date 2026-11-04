#!/usr/bin/env bash
# AXON на CachyOS: обновить пакеты AXON (имя системы, «О системе», лого в терминале, компактный вход)
# и убрать фирменные приложения, темы, обои и анимации CachyOS. Можно запускать повторно.
#
#   curl -fsSLO https://raw.githubusercontent.com/DaCat-stack/axon-linux/main/tools/axon-rebrand-cachyos.sh
#   sudo bash axon-rebrand-cachyos.sh
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Запусти через sudo: sudo bash $0"; exit 1; }
say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

# видимые пользователю части CachyOS; ничего из этого не нужно другим пакетам
REMOVE=(
    cachyos-hello cachyos-kernel-manager cachyos-packageinstaller cachy-update
    cachyos-emerald-kde-theme-git cachyos-nord-kde-theme-git cachyos-iridescent-kde
    cachyos-wallpapers cachyos-plymouth-bootanimation cachyos-plymouth-theme
)

say "Обновление системы и пакетов AXON"
pacman -Syu --noconfirm

say "Убираю приложения и оформление CachyOS"
installed=()
for p in "${REMOVE[@]}"; do pacman -Qq "$p" >/dev/null 2>&1 && installed+=("$p"); done
if [ "${#installed[@]}" -gt 0 ]; then
    pacman -Rns --noconfirm "${installed[@]}"
else
    echo "уже убрано"
fi

say "Имя системы AXON"
/usr/lib/axon/axon-os-release
grep -E '^(NAME|PRETTY_NAME)=' /etc/os-release

say "Анимация загрузки AXON (initramfs)"
plymouth-set-default-theme axon
if command -v limine-mkinitcpio >/dev/null; then limine-mkinitcpio; else mkinitcpio -P; fi

say "Готово. Перезагрузись, чтобы всё применилось."
