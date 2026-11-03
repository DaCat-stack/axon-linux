#!/usr/bin/env bash
# Собирает все packages/*/PKGBUILD в <каталог>. С --sign подписывает подключом из $AXON_SIGN_SUBKEY.
# Запускается внутри контейнера archlinux от root. Использование: ci/build-packages.sh <outdir> [--sign]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:?каталог}"; SIGN="${2:-}"
mkdir -p "$OUT"

pacman -S --noconfirm --needed base-devel git
# то, что нужно при сборке самих пакетов AXON (makedepends): шрифты меню загрузки
pacman -S --noconfirm --needed grub inter-font fontconfig
# зависимости пакетов AXON (Plasma, plymouth…) ставит mkarchiso, при сборке они не нужны: makepkg -d
git config --global --add safe.directory "$ROOT"
id builder >/dev/null 2>&1 || useradd -m builder
echo 'builder ALL=(ALL) NOPASSWD: /usr/bin/pacman' > /etc/sudoers.d/builder

WORK=/home/builder/axon-pkgs
rm -rf "$WORK"; mkdir -p "$WORK"
cp -r "$ROOT/packages" "$ROOT/pkgsrc" "$WORK/"
chown -R builder: "$WORK"

if [ "$SIGN" = "--sign" ]; then
    : "${AXON_SIGN_SUBKEY:?нет секрета AXON_SIGN_SUBKEY}" "${AXON_SIGN_PASS:?нет секрета AXON_SIGN_PASS}"
    sudo -u builder gpg --batch --pinentry-mode loopback --passphrase "$AXON_SIGN_PASS" --import <<<"$AXON_SIGN_SUBKEY"
fi

# версия пакета = время последнего коммита, где менялся сам пакет или его файлы (растёт с каждой правкой)
pkgver_for() {
    git -C "$ROOT" log -1 --format=%cd --date=format-local:%Y%m%d.%H%M%S -- "packages/$1" "pkgsrc/$1"
}

for dir in "$WORK"/packages/*/; do
    name=$(basename "$dir")
    ver=$(TZ=UTC pkgver_for "$name"); ver=${ver:-0}
    (cd "$dir" && sudo -u builder env AXON_PKGVER="$ver" makepkg -d --noconfirm --cleanbuild)
    for pkg in "$dir"/*.pkg.tar.zst; do
        [ "$SIGN" = "--sign" ] && sudo -u builder gpg --batch --yes --pinentry-mode loopback --passphrase "$AXON_SIGN_PASS" --detach-sign --no-armor "$pkg"
        cp "$pkg" "$OUT/"
        [ -f "$pkg.sig" ] && cp "$pkg.sig" "$OUT/"
    done
done
ls -l "$OUT"
