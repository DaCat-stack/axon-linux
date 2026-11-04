#!/usr/bin/env bash
# boot-nocompress.sh: на btrfs выключает сжатие для /boot (GRUB не читает ядро, сжатое btrfs поверх
# своего сжатия: «premature end of file /@/boot/vmlinuz-linux»); на ext4/xfs ничего не делает.
set -euo pipefail
cd "$(dirname "$0")/.."
SCRIPT=$PWD/profile/airootfs/usr/share/axon/target/boot-nocompress.sh
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/bin"
printf '#!/bin/sh\necho "$FAKE_FS"\n' > "$tmp/bin/findmnt"
printf '#!/bin/sh\necho "chattr $*" >> "$LOG"\n' > "$tmp/bin/chattr"
printf '#!/bin/sh\necho "btrfs $*" >> "$LOG"\n' > "$tmp/bin/btrfs"
chmod +x "$tmp/bin/"*
export PATH="$tmp/bin:$PATH" LOG="$tmp/log"

: > "$LOG"; mkdir -p "$tmp/root/boot"
FAKE_FS=ext4 ROOT="$tmp/root" bash "$SCRIPT"
[ ! -s "$LOG" ] || { echo "ext4: ничего не должно меняться"; exit 1; }

: > "$LOG"
FAKE_FS=btrfs ROOT="$tmp/root" bash "$SCRIPT"
grep -qx "chattr +m $tmp/root/boot" "$LOG" || { echo "btrfs: нет chattr +m /boot"; exit 1; }
grep -qx "btrfs property set $tmp/root/boot compression none" "$LOG" || { echo "btrfs: нет compression none"; exit 1; }
echo PASS
