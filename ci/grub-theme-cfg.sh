#!/usr/bin/env bash
# Включает тему AXON в grub.cfg флешки — так, чтобы она НИКОГДА не мешала загрузке:
# тема ищется по файлу (под Ventoy своя GRUB, переменные archiso могут быть пусты),
# всё под условиями; не нашлась — остаётся обычное текстовое меню без ошибок.
# Использование: ci/grub-theme-cfg.sh <grub.cfg>
set -euo pipefail
f="$1"
T='(${axon_dev})/boot/grub/themes/axon'
block="search --no-floppy --set=axon_dev --file /boot/grub/themes/axon/theme.txt
    if [ -n \"\${axon_dev}\" ]; then
        if loadfont $T/inter-regular-14.pf2; then true; fi
        if loadfont $T/inter-regular-16.pf2; then true; fi
        if loadfont $T/inter-regular-20.pf2; then true; fi
        if loadfont $T/inter-bold-20.pf2; then
            insmod gfxterm
            insmod png
            terminal_output gfxterm
            set theme=$T/theme.txt
        fi
    fi"
B="$block" awk '!done && /terminal_output console/ { print; print "    " ENVIRON["B"]; done=1; next } { print }' "$f" > "$f.new"
mv "$f.new" "$f"
grep -q 'set theme=' "$f"
