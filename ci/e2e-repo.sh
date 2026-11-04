#!/usr/bin/env bash
# Проверка опубликованного репозитория «как у пользователя»: чистый Arch, ключ AXON, канал с
# SigLevel = Required DatabaseRequired, установка каждого пакета по отдельности.
# Использование (на машине с docker): ci/e2e-repo.sh <base-url> <канал> <файл итога> <пакет...>
# В файл итога пишет «имя версия» каждого прошедшего пакета — ровно ту версию, что поставилась;
# код выхода 1, если хоть один не прошёл.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="${1:?url}"; CH="${2:?канал}"; OUT="${3:?файл итога}"; shift 3
: > "$OUT"
VER=$(mktemp -d); chmod 777 "$VER"; trap 'rm -rf "$VER"' EXIT

curl -fsI "$BASE/$CH/x86_64/$CH.db" >/dev/null || { echo "нет базы $BASE/$CH/x86_64/$CH.db"; exit 1; }

failed=0
for pkg in "$@"; do
    if docker run --rm -v "$ROOT:/build:ro" -v "$VER:/out" archlinux:latest bash -euo pipefail -c "
        bash /build/ci/use-mirrors.sh
        pacman-key --init >/dev/null 2>&1
        pacman-key --populate archlinux >/dev/null 2>&1
        pacman-key --add /build/packages/axon-keyring/axon.gpg
        pacman-key --lsign-key \$(cut -d: -f1 /build/packages/axon-keyring/axon-trusted)
        awk -v ch='$CH' -v base='$BASE' '!d && /^\[core\]/ { print \"[\" ch \"]\nSigLevel = Required DatabaseRequired\nServer = \" base \"/\" ch \"/\\\$arch\n\"; d=1 } { print }' /etc/pacman.conf > /tmp/p && cp /tmp/p /etc/pacman.conf
        pacman -Syu --noconfirm $pkg
        case $pkg in
            axon-branding) test -s /usr/share/plymouth/themes/axon/axon.script; test -x /usr/lib/axon/check-updates-age; test -s /usr/share/grub/themes/axon/inter-regular-20.pf2; test -s /usr/share/grub/themes/axon/inter-bold-20.pf2 ;;
            axon-welcome)  test -x /usr/bin/axon-welcome ;;
            axon-keyring)  pacman-key --list-keys 98546F93C7C579F0A058B5F712B7AFBC4F2420BE >/dev/null ;;
        esac
        pacman -Qkk $pkg >/dev/null
        pacman -Q $pkg > /out/$pkg
    "; then
        echo "e2e ok: $(cat "$VER/$pkg")"; cat "$VER/$pkg" >> "$OUT"
    else
        echo "::error::e2e: $pkg не ставится из $CH"; failed=1
    fi
done
exit $failed
