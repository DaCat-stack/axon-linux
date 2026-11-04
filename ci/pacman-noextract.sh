#!/usr/bin/env bash
# Не распаковывать автозапуск стандартного помощника первого запуска KDE (plasma-welcome):
# у AXON своё окно приветствия. Сам помощник остаётся в меню.
# Использование: ci/pacman-noextract.sh <pacman.conf>
set -euo pipefail
f="$1"
line='NoExtract = etc/xdg/autostart/org.kde.plasma-welcome.desktop'
grep -qxF "$line" "$f" && exit 0
awk -v l="$line" '{ print } !d && /^\[options\]/ { print l; d=1 }' "$f" > "$f.new"
mv "$f.new" "$f"
