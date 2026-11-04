#!/usr/bin/env bash
# Собирает AUR-пакеты из списка (по умолчанию aur/packages.txt — для ISO) в каталог репозитория.
# Запускается внутри контейнера archlinux от root. Аргументы: <каталог> [список].
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="${1:?каталог репозитория}"
LIST="${2:-$ROOT/aur/packages.txt}"   # список AUR-пакетов; по умолчанию — для ISO (Calamares)

# строка списка: <имя> [коммит AUR] [коммит исходников для *-git] — закреплённая, просмотренная версия
mapfile -t LINES < <(sed 's/#.*//' "$LIST" | awk 'NF')
PKGS=()
[ "${#LINES[@]}" -gt 0 ] || exit 0

# python нужен Calamares при сборке, иначе его Python-модули тихо выключаются
pacman -S --noconfirm --needed base-devel git python
id builder >/dev/null 2>&1 || useradd -m builder
echo 'builder ALL=(ALL) NOPASSWD: /usr/bin/pacman' > /etc/sudoers.d/builder
mkdir -p "$REPO"

for line in "${LINES[@]}"; do
    read -r p aur_commit src_commit <<<"$line"
    PKGS+=("$p")
    rm -rf "/home/builder/$p"
    sudo -u builder git clone -q "https://aur.archlinux.org/$p.git" "/home/builder/$p"
    if [ -n "${aur_commit:-}" ]; then
        sudo -u builder git -C "/home/builder/$p" checkout -q "$aur_commit"
    fi
    if [ -n "${src_commit:-}" ]; then
        sudo -u builder "$ROOT/ci/aur-pin-source.sh" "/home/builder/$p/PKGBUILD" "$src_commit"
    fi
    (cd "/home/builder/$p" && sudo -u builder makepkg -s --noconfirm --needed)
    built=()
    for f in /home/builder/"$p"/*.pkg.tar.zst; do
        case "$f" in *-debug-*) continue ;; esac   # отладочные пакеты не нужны
        cp "$f" "$REPO/"; built+=("$f")
    done
    # ставим сразу: следующий в списке может от него зависеть (Sweet → иконки Candy), а в репозиториях Arch его нет
    pacman -U --noconfirm --needed "${built[@]}"
done
repo-add "$REPO/axon-local.db.tar.gz" "$REPO"/*.pkg.tar.zst
