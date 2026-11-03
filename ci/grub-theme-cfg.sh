#!/usr/bin/env bash
# Включает графический режим и тему AXON в grub.cfg флешки (releng: «terminal_output console»).
# Использование: ci/grub-theme-cfg.sh <grub.cfg>
set -euo pipefail
f="$1"
awk '!done && /terminal_output console/ {
        sub(/terminal_output console/, "insmod gfxterm\n    insmod png\n    loadfont ${prefix}/themes/axon/inter-regular-14.pf2\n    loadfont ${prefix}/themes/axon/inter-regular-16.pf2\n    loadfont ${prefix}/themes/axon/inter-regular-20.pf2\n    loadfont ${prefix}/themes/axon/inter-bold-20.pf2\n    terminal_output gfxterm\n    set theme=${prefix}/themes/axon/theme.txt")
        done=1 }
     { print }' "$f" > "$f.new"
mv "$f.new" "$f"
grep -q 'set theme=${prefix}/themes/axon/theme.txt' "$f"
