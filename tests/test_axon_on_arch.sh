#!/usr/bin/env bash
# tools/axon-on-arch.sh: блок [axon] вставляется в настоящий pacman.conf CachyOS перед первым
# репозиторием, с обязательной подписью, и повторный запуск его не дублирует.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
cp tests/fixtures/cachyos-pacman.conf "$tmp"
AXON_ONLY_PACMAN_CONF="$tmp" bash tools/axon-on-arch.sh
AXON_ONLY_PACMAN_CONF="$tmp" bash tools/axon-on-arch.sh
fail() { echo "FAIL: $*"; exit 1; }
[ "$(grep -c '^\[axon\]' "$tmp")" = 1 ] || fail "[axon] не ровно один раз"
first=$(grep -E '^\[[a-z]' "$tmp" | grep -v '^\[options\]' | head -1)
[ "$first" = "[axon]" ] || fail "[axon] не первый репозиторий (первый: $first)"
awk '/^\[axon\]/{f=1;next} f&&/^\[/{exit} f' "$tmp" | grep -qx 'SigLevel = Required DatabaseRequired' || fail "нет обязательной подписи"
awk '/^\[axon\]/{f=1;next} f&&/^\[/{exit} f' "$tmp" | grep -qx 'Server = https://dacat-stack.github.io/axon-repo/axon/$arch' || fail "нет сервера"
grep -q '^\[cachyos-v3\]' "$tmp" || fail "сломан остальной конфиг"
echo PASS
