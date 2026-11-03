#!/usr/bin/env bash
# Проверка опубликованного репозитория «как у пользователя»: чистый Arch, ключ AXON, канал с
# SigLevel = Required DatabaseRequired, установка каждого пакета по отдельности.
# Использование (на машине с docker): ci/e2e-repo.sh <base-url> <канал> <пакет...>
# Пишет имена прошедших пакетов в e2e-passed.txt; код выхода 1, если хоть один не прошёл.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="${1:?url}"; CH="${2:?канал}"; shift 2
: > "$ROOT/e2e-passed.txt"

curl -fsI "$BASE/$CH/x86_64/$CH.db" >/dev/null || { echo "нет базы $BASE/$CH/x86_64/$CH.db"; exit 1; }

failed=0
for pkg in "$@"; do
    if docker run --rm -v "$ROOT:/build:ro" archlinux:latest bash -euo pipefail -c "
        pacman-key --init >/dev/null 2>&1
        pacman-key --populate archlinux >/dev/null 2>&1
        pacman-key --add /build/packages/axon-keyring/axon.gpg
        pacman-key --lsign-key \$(cut -d: -f1 /build/packages/axon-keyring/axon-trusted)
        awk -v ch='$CH' -v base='$BASE' '!d && /^\[core\]/ { print \"[\" ch \"]\nSigLevel = Required DatabaseRequired\nServer = \" base \"/\" ch \"/\\\$arch\n\"; d=1 } { print }' /etc/pacman.conf > /tmp/p && cp /tmp/p /etc/pacman.conf
        pacman -Syu --noconfirm $pkg
        case $pkg in
            axon-branding) test -s /usr/share/plymouth/themes/axon/axon.script; test -x /usr/lib/axon/check-updates-age ;;
            axon-welcome)  test -x /usr/bin/axon-welcome ;;
            axon-keyring)  pacman-key --list-keys 98546F93C7C579F0A058B5F712B7AFBC4F2420BE >/dev/null ;;
        esac
        pacman -Qkk $pkg >/dev/null
    "; then
        echo "e2e ok: $pkg"; echo "$pkg" >> "$ROOT/e2e-passed.txt"
    else
        echo "::error::e2e: $pkg не ставится из $CH"; failed=1
    fi
done
exit $failed
