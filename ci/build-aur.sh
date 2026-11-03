#!/usr/bin/env bash
# Собирает пакеты из aur/packages.txt в локальный репозиторий axon-local.
# Запускается внутри контейнера archlinux от root. Аргумент: каталог репозитория.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="${1:?каталог репозитория}"

mapfile -t PKGS < <(sed 's/#.*//; s/[[:space:]]//g; /^$/d' "$ROOT/aur/packages.txt")
[ "${#PKGS[@]}" -gt 0 ] || exit 0

# python нужен Calamares при сборке, иначе его Python-модули тихо выключаются
pacman -S --noconfirm --needed base-devel git python
id builder >/dev/null 2>&1 || useradd -m builder
echo 'builder ALL=(ALL) NOPASSWD: /usr/bin/pacman' > /etc/sudoers.d/builder
mkdir -p "$REPO"

for p in "${PKGS[@]}"; do
    rm -rf "/home/builder/$p"
    sudo -u builder git clone --depth 1 "https://aur.archlinux.org/$p.git" "/home/builder/$p"
    (cd "/home/builder/$p" && sudo -u builder makepkg -s --noconfirm --needed)
    cp /home/builder/"$p"/*.pkg.tar.zst "$REPO/"
done
repo-add "$REPO/axon-local.db.tar.gz" "$REPO"/*.pkg.tar.zst
