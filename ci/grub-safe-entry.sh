#!/usr/bin/env bash
# Добавляет в меню флешки пункт «безопасный режим графики»: nomodeset, без анимации —
# если с видеокартой что-то не так, система всё равно загрузится и покажет ошибки текстом.
# Использование: ci/grub-safe-entry.sh <grub.cfg>  (вставляется сразу после первого пункта)
set -euo pipefail
f="$1"
grep -q 'безопасный режим графики' "$f" && exit 0
awk '
    !done && /^menuentry / { inmain=1 }
    { print }
    inmain && /^}/ && !done {
        print ""
        print "menuentry \"AXON Linux — безопасный режим графики (%ARCH%, ${archiso_platform})\" --class arch --class gnu-linux --class gnu --class os --id '"'"'axon-safe'"'"' {"
        print "    set gfxpayload=keep"
        print "    linux /%INSTALL_DIR%/boot/%ARCH%/vmlinuz-linux archisobasedir=%INSTALL_DIR% archisosearchuuid=%ARCHISO_UUID% nomodeset %KERNEL_PARAMS%"
        print "    initrd /%INSTALL_DIR%/boot/%ARCH%/initramfs-linux.img"
        print "}"
        done=1; inmain=0
    }' "$f" > "$f.new"
mv "$f.new" "$f"
grep -q 'безопасный режим графики' "$f"
