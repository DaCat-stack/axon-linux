#!/usr/bin/env bash
# Внутри контейнера archlinux: перенести прошедшие e2e пакеты из axon-testing в axon.
# Использование: ci/publish-promote.sh <каталог сайта> <итог e2e: строки «имя версия»>
# Переносит ровно проверенную версию; если её файла нет в axon-testing — ошибка.
set -euo pipefail
"$(cd "$(dirname "$0")" && pwd)/use-mirrors.sh"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE="${1:?сайт}"; LIST="${2:?список}"
pacman -Syu --noconfirm --needed sudo
id builder >/dev/null 2>&1 || useradd -m builder
sudo -u builder gpg --batch --pinentry-mode loopback --passphrase "$AXON_SIGN_PASS" --import <<<"$AXON_SIGN_SUBKEY"
chown -R builder: "$SITE"
files=()
while read -r name ver; do
    [ -n "$name" ] || continue
    matches=("$SITE"/axon-testing/x86_64/"$name-$ver"-*.pkg.tar.zst)
    [ "${#matches[@]}" -eq 1 ] && [ -f "${matches[0]}" ] || { echo "в axon-testing нет проверенного $name $ver"; exit 1; }
    files+=("${matches[0]}")
done < "$LIST"
[ "${#files[@]}" -gt 0 ] || { echo "нечего переносить"; exit 0; }
sudo -u builder env AXON_SIGN_PASS="$AXON_SIGN_PASS" "$ROOT/ci/repo-add-channel.sh" "$SITE" axon "${files[@]}"
