#!/usr/bin/env bash
# Внутри контейнера archlinux: собрать и подписать пакеты AXON, добавить новые в канал axon-testing.
# Использование: ci/publish-build.sh <каталог сайта>   (нужны $AXON_SIGN_SUBKEY, $AXON_SIGN_PASS)
set -euo pipefail
"$(cd "$(dirname "$0")" && pwd)/use-mirrors.sh"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE="${1:?сайт}"
pacman -Syu --noconfirm --needed
"$ROOT/ci/build-packages.sh" /tmp/axon-pkgs --sign
chown -R builder: "$SITE"
sudo -u builder env AXON_SIGN_PASS="$AXON_SIGN_PASS" "$ROOT/ci/repo-add-channel.sh" "$SITE" axon-testing /tmp/axon-pkgs/*.pkg.tar.zst
