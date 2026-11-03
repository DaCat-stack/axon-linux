#!/usr/bin/env bash
# Собирает все packages/*/PKGBUILD в <каталог>. С --sign подписывает подключом из $AXON_SIGN_SUBKEY.
# Запускается внутри контейнера archlinux от root. Использование: ci/build-packages.sh <outdir> [--sign]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:?каталог}"; SIGN="${2:-}"
mkdir -p "$OUT"

pacman -S --noconfirm --needed base-devel
id builder >/dev/null 2>&1 || useradd -m builder
echo 'builder ALL=(ALL) NOPASSWD: /usr/bin/pacman' > /etc/sudoers.d/builder

WORK=/home/builder/axon-pkgs
rm -rf "$WORK"; mkdir -p "$WORK"
cp -r "$ROOT/packages" "$ROOT/pkgsrc" "$WORK/" 2>/dev/null || cp -r "$ROOT/packages" "$WORK/"
chown -R builder: "$WORK"

if [ "$SIGN" = "--sign" ]; then
    : "${AXON_SIGN_SUBKEY:?нет секрета AXON_SIGN_SUBKEY}"
    sudo -u builder gpg --batch --import <<<"$AXON_SIGN_SUBKEY"
fi

for dir in "$WORK"/packages/*/; do
    (cd "$dir" && sudo -u builder makepkg -s --noconfirm --needed --cleanbuild)
    for pkg in "$dir"/*.pkg.tar.zst; do
        [ "$SIGN" = "--sign" ] && sudo -u builder gpg --batch --yes --detach-sign --no-armor "$pkg"
        cp "$pkg" "$OUT/"
        [ -f "$pkg.sig" ] && cp "$pkg.sig" "$OUT/"
    done
done
ls -l "$OUT"
