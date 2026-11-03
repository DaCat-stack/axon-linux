#!/usr/bin/env bash
# На настоящем grub.cfg из releng: тема включается, console меняется на gfxterm ровно один раз.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
cp tests/fixtures/releng-grub.cfg "$tmp"
ci/grub-theme-cfg.sh "$tmp"
grep -q 'set theme=${prefix}/themes/axon/theme.txt' "$tmp"
grep -q 'loadfont ${prefix}/themes/axon/inter-bold-20.pf2' "$tmp"
[ "$(grep -c 'terminal_output gfxterm' "$tmp")" = 1 ]
! grep -q 'terminal_output console' "$tmp"
echo PASS
