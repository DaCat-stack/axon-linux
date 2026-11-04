#!/usr/bin/env bash
# AXON поверх уже установленной Arch-системы (проверено на CachyOS с KDE Plasma).
# Подключает подписанный репозиторий AXON, ставит axon-desktop и включает анимацию загрузки AXON.
# Можно запускать повторно — ничего не задвоится.
#
#   curl -fsSLO https://raw.githubusercontent.com/DaCat-stack/axon-linux/main/tools/axon-on-arch.sh
#   sudo bash axon-on-arch.sh
set -euo pipefail

FPR=98546F93C7C579F0A058B5F712B7AFBC4F2420BE
KEY_URL=https://raw.githubusercontent.com/DaCat-stack/axon-linux/main/packages/axon-keyring/axon.gpg
REPO_BLOCK='[axon]
SigLevel = Required DatabaseRequired
Server = https://dacat-stack.github.io/axon-repo/axon/$arch
'

# [axon] — перед первым репозиторием, чтобы пакеты axon-* брались от нас
add_repo() {  # add_repo <pacman.conf>
    local conf="$1"
    grep -q '^\[axon\]' "$conf" && return 0
    B="$REPO_BLOCK" awk '!d && /^\[/ && !/^\[options\]/ { printf "%s\n", ENVIRON["B"]; d=1 } { print }' "$conf" > "$conf.axon-new"
    cat "$conf.axon-new" > "$conf" && rm -f "$conf.axon-new"
}

# для тестов: только правка pacman.conf
if [ -n "${AXON_ONLY_PACMAN_CONF:-}" ]; then
    add_repo "$AXON_ONLY_PACMAN_CONF"
    exit 0
fi

[ "$(id -u)" = 0 ] || { echo "Запусти через sudo: sudo bash $0"; exit 1; }
say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

say "Ключ подписи AXON"
tmpkey=$(mktemp); trap 'rm -f "$tmpkey"' EXIT
curl -fsSL "$KEY_URL" -o "$tmpkey"
gpg --show-keys --with-colons "$tmpkey" | grep -q "^fpr:::::::::$FPR:" || { echo "Ключ не совпадает с ожидаемым $FPR — остановка"; exit 1; }
pacman-key --add "$tmpkey"
pacman-key --lsign-key "$FPR"

say "Репозиторий AXON в /etc/pacman.conf"
cp -n /etc/pacman.conf /etc/pacman.conf.before-axon
add_repo /etc/pacman.conf

say "Пакеты AXON"
pacman -Sy --noconfirm --needed axon-desktop

say "Анимация загрузки AXON"
plymouth-set-default-theme axon
if command -v limine-mkinitcpio >/dev/null; then limine-mkinitcpio; else mkinitcpio -P; fi

say "Готово. Выйди из системы и войди снова (или перезагрузись) — появится окно «Выбери свой стиль»."
