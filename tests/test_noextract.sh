#!/usr/bin/env bash
# NoExtract для автозапуска помощника KDE встаёт в [options] настоящего pacman.conf из releng.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
cp tests/fixtures/releng-pacman.conf "$tmp"
ci/pacman-noextract.sh "$tmp"
awk '/^\[options\]/{o=1;next} /^\[/{o=0} o && /^NoExtract = etc\/xdg\/autostart\/org.kde.plasma-welcome.desktop$/{f=1} END{exit !f}' "$tmp"
ci/pacman-noextract.sh "$tmp"   # повторно — без дублей
[ "$(grep -c 'org.kde.plasma-welcome.desktop' "$tmp")" = 1 ]
echo PASS
