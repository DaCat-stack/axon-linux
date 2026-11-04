#!/usr/bin/env bash
# axon-os-release: имя системы — AXON (os-release, lsb-release, /etc/issue), служебные ID не трогаем;
# работает и когда /etc/os-release — симлинк на /usr/lib/os-release (как в чистом Arch).
set -euo pipefail
cd "$(dirname "$0")/.."
S=$PWD/pkgsrc/axon-branding/usr/lib/axon/axon-os-release
fail() { echo "FAIL: $*"; exit 1; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# CachyOS: обычные файлы
mkdir -p "$tmp/c/etc"
cp tests/fixtures/cachyos-os-release "$tmp/c/etc/os-release"
cp tests/fixtures/cachyos-lsb-release "$tmp/c/etc/lsb-release"
cp tests/fixtures/cachyos-issue "$tmp/c/etc/issue"
ROOT="$tmp/c" bash "$S"; ROOT="$tmp/c" bash "$S"
o="$tmp/c/etc/os-release"
grep -qx 'NAME="AXON Linux"' "$o" || fail "NAME"
grep -qx 'PRETTY_NAME="AXON Linux"' "$o" || fail "PRETTY_NAME"
grep -qx 'ID=cachyos' "$o" || fail "ID должен остаться cachyos"
grep -qx 'ID_LIKE=arch' "$o" || fail "ID_LIKE должен остаться"
grep -qx 'LOGO=axon-logo' "$o" || fail "LOGO"
grep -qx 'HOME_URL="https://axon-project.ru/"' "$o" || fail "HOME_URL"
! grep -qi 'cachyos\.org\|discuss\.cachyos\|github.com/cachyos' "$o" || fail "остались ссылки CachyOS"
[ "$(grep -c '^NAME=' "$o")" = 1 ] || fail "NAME задвоен"
grep -qx 'DISTRIB_DESCRIPTION="AXON Linux"' "$tmp/c/etc/lsb-release" || fail "lsb-release"
! grep -q 'CachyOS' "$tmp/c/etc/issue" || fail "/etc/issue"

# Arch: /etc/os-release — симлинк
mkdir -p "$tmp/a/etc" "$tmp/a/usr/lib"
cp tests/fixtures/arch-os-release "$tmp/a/usr/lib/os-release"
ln -s ../usr/lib/os-release "$tmp/a/etc/os-release"
ROOT="$tmp/a" bash "$S"
[ ! -L "$tmp/a/etc/os-release" ] || fail "симлинк не заменён файлом"
grep -qx 'PRETTY_NAME="AXON Linux"' "$tmp/a/etc/os-release" || fail "Arch: PRETTY_NAME"
grep -qx 'ID=arch' "$tmp/a/etc/os-release" || fail "Arch: ID должен остаться arch"
grep -qx 'PRETTY_NAME="Arch Linux"' "$tmp/a/usr/lib/os-release" || fail "файл пакета filesystem тронут"
echo PASS
