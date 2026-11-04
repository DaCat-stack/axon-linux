#!/usr/bin/env bash
# tools/axon-boot-login.sh --only-limine <файл>: меню Limine скрыто (quiet, короткий timeout),
# «CachyOS» → «AXON», записи загрузки не тронуты; повторный запуск ничего не дублирует.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
cp tests/fixtures/limine.conf "$tmp"
bash tools/axon-boot-login.sh --only-limine "$tmp"
bash tools/axon-boot-login.sh --only-limine "$tmp"
fail() { echo "FAIL: $*"; cat "$tmp"; exit 1; }
head_=$(awk '/^\//{exit} {print}' "$tmp")
[ "$(grep -c '^timeout: 2$' <<<"$head_")" = 1 ] || fail "timeout не 2 или задвоен"
[ "$(grep -c '^quiet: yes$' <<<"$head_")" = 1 ] || fail "нет quiet: yes"
grep -q '^interface_branding: AXON$' <<<"$head_" || fail "брендинг не AXON"
grep -qx '/+AXON' "$tmp" || fail "пункт не переименован в AXON"
! grep -q 'CachyOS$' "$tmp" || fail "осталось CachyOS в заголовке"
grep -q 'comment: machine-id=0123456789abcdef0123456789abcdef' "$tmp" || fail "потерян machine-id"
grep -q 'path: boot():/0123/linux-cachyos/vmlinuz-linux-cachyos' "$tmp" || fail "сломана запись ядра"
[ "$(grep -c '^/' "$tmp")" = 1 ] || fail "число записей верхнего уровня изменилось"
echo PASS
