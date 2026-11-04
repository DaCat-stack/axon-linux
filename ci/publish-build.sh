#!/usr/bin/env bash
# Внутри контейнера archlinux: собрать и подписать пакеты AXON, добавить новые в канал axon-testing.
# Использование: ci/publish-build.sh <каталог сайта>   (нужны $AXON_SIGN_SUBKEY, $AXON_SIGN_PASS)
set -euo pipefail
"$(cd "$(dirname "$0")" && pwd)/use-mirrors.sh"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE="${1:?сайт}"
pacman -Syu --noconfirm --needed
"$ROOT/ci/build-packages.sh" /tmp/axon-pkgs --sign
# вещи Магазина AXON из AUR (aur/store.txt) — в тот же каталог, подписываем тем же подключом
"$ROOT/ci/build-aur.sh" /tmp/axon-pkgs "$ROOT/aur/store.txt"
for pkg in /tmp/axon-pkgs/*.pkg.tar.zst; do
    [ -f "$pkg.sig" ] && continue
    sudo -u builder gpg --batch --yes --pinentry-mode loopback --passphrase "$AXON_SIGN_PASS" --detach-sign --no-armor "$pkg"
done
chown -R builder: "$SITE"
sudo -u builder env AXON_SIGN_PASS="$AXON_SIGN_PASS" "$ROOT/ci/repo-add-channel.sh" "$SITE" axon-testing /tmp/axon-pkgs/*.pkg.tar.zst
