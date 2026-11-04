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

# нет базы на свежей установке (machine-id моложе 14 дней) — ещё рано тревожить
touch "$tmp/machine-id"; export AXON_MACHINE_ID="$tmp/machine-id"
run "$tmp/missing.db"
[ ! -s "$NOTIFY_LOG" ] || { echo "свежая установка без базы: уведомлять рано"; exit 1; }

# нет базы, а система стоит уже 20 дней — предупреждаем
touch -t "$(date -v-20d +%Y%m%d%H%M 2>/dev/null || date -d '20 days ago' +%Y%m%d%H%M)" "$tmp/machine-id"
run "$tmp/missing.db"
grep -qx "Обновления AXON не приходят" "$NOTIFY_LOG" || { echo "нет базы 20 дней: нет уведомления"; exit 1; }
echo PASS
