#!/usr/bin/env bash
# На настоящем grub.cfg из releng: тема включается, console меняется на gfxterm ровно один раз.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
cp tests/fixtures/releng-grub.cfg "$tmp"
ci/grub-theme-cfg.sh "$tmp"
grep -q 'set theme=(${ARCHISO_HINT})/boot/grub/themes/axon/theme.txt' "$tmp"
grep -q 'loadfont (${ARCHISO_HINT})/boot/grub/themes/axon/inter-bold-20.pf2' "$tmp"
! grep -q '${prefix}/themes' "$tmp"   # prefix на флешке — встроенный memdisk, темы там нет
[ "$(grep -c 'terminal_output gfxterm' "$tmp")" = 1 ]
! grep -q 'terminal_output console' "$tmp"
echo PASS
