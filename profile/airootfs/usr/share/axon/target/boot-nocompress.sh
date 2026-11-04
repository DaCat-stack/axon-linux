#!/bin/sh
# AXON: на btrfs выключаем сжатие для /boot — до того, как туда запишутся ядро, initramfs и GRUB.
# Иначе GRUB не дочитывает ядро («premature end of file /@/boot/vmlinuz-linux») и система не грузится.
# chattr +m (NOCOMPRESS) наследуют новые файлы; property — то же для btrfs-progs.
ROOT="${ROOT:-/}"
[ "$(findmnt -no FSTYPE /)" = btrfs ] || exit 0
B="${ROOT%/}/boot"
mkdir -p "$B"
chattr +m "$B"
btrfs property set "$B" compression none
exit 0
