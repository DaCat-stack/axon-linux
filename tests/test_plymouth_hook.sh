#!/usr/bin/env bash
# Хук plymouth должен встать после kms (и kms должен появиться, если его не было) — на реальном конфиге releng.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
cp tests/fixtures/releng-archiso.conf "$tmp"
ci/add-plymouth-hook.sh "$tmp"
grep -Eq '^HOOKS=\(base udev microcode modconf kms plymouth memdisk archiso ' "$tmp"
