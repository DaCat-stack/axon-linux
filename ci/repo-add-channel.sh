#!/usr/bin/env bash
# Добавляет пакеты (с .sig рядом) в канал репозитория и подписывает базу.
# Использование: ci/repo-add-channel.sh <каталог сайта> <канал> <пакет.pkg.tar.zst...>
# Пакет, который уже лежит в канале (тот же файл), пропускается — опубликованные файлы не меняются.
# Нужны gpg-ключ в связке текущего пользователя и $AXON_SIGN_PASS.
set -euo pipefail
SITE="${1:?сайт}"; CH="${2:?канал}"; shift 2
DIR="$SITE/$CH/x86_64"
mkdir -p "$DIR"
sign() { gpg --batch --yes --pinentry-mode loopback --passphrase "${AXON_SIGN_PASS:?}" --detach-sign --no-armor "$1"; }

added=()
for pkg in "$@"; do
    name=$(basename "$pkg")
    case "$name" in *-debug-*) echo "пропускаю отладочный: $name"; continue ;; esac
    [ -e "$DIR/$name" ] && { echo "уже есть: $CH/$name"; continue; }
    [ -f "$pkg.sig" ] || { echo "нет подписи: $pkg"; exit 1; }
    cp "$pkg" "$pkg.sig" "$DIR/"
    added+=("$DIR/$name")
done
[ "${#added[@]}" -gt 0 ] || { echo "$CH: нечего добавлять"; exit 0; }

repo-add -R "$DIR/$CH.db.tar.gz" "${added[@]}"   # -R удаляет файлы старых версий
for db in db files; do
    sign "$DIR/$CH.$db.tar.gz"
    # Pages не отдаёт симлинки — кладём обычные копии под именами, которые ждёт pacman
    rm -f "$DIR/$CH.$db" "$DIR/$CH.$db.sig"
    cp "$DIR/$CH.$db.tar.gz" "$DIR/$CH.$db"
    cp "$DIR/$CH.$db.tar.gz.sig" "$DIR/$CH.$db.sig"
done
printf '%s\n' "${added[@]##*/}"
