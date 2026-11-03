#!/usr/bin/env bash
# check-updates-age: молчит при свежей базе, уведомляет при старой (>14 дней) и отсутствующей.
set -euo pipefail
cd "$(dirname "$0")/.."
SCRIPT=pkgsrc/axon-branding/usr/lib/axon/check-updates-age
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/bin"
cat > "$tmp/bin/notify-send" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >> "$NOTIFY_LOG"
SH
chmod +x "$tmp/bin/notify-send"
export PATH="$tmp/bin:$PATH" NOTIFY_LOG="$tmp/log"

run() { : > "$NOTIFY_LOG"; bash "$SCRIPT" "$1" 14; }

touch "$tmp/fresh.db"; run "$tmp/fresh.db"
[ ! -s "$NOTIFY_LOG" ] || { echo "свежая база: уведомлять не должно"; exit 1; }

touch -t "$(date -v-20d +%Y%m%d%H%M 2>/dev/null || date -d '20 days ago' +%Y%m%d%H%M)" "$tmp/old.db"; run "$tmp/old.db"
grep -qx "Обновления AXON не приходят" "$NOTIFY_LOG" || { echo "старая база: нет уведомления"; exit 1; }

run "$tmp/missing.db"
grep -qx "Обновления AXON не приходят" "$NOTIFY_LOG" || { echo "нет базы: нет уведомления"; exit 1; }
echo PASS
