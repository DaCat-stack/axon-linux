#!/usr/bin/env bash
# Загружает ISO в QEMU и снимает экран. Два прогона:
#   bios-*  — BIOS, ISO как CD (boot.png — анимация, desktop.png — рабочий стол);
#   uefi-*  — UEFI (OVMF), ISO как диск и 8 ГБ памяти — как флешка на игровом ПК:
#             uefi-menu.png — меню GRUB с темой AXON, uefi-desktop.png — рабочий стол
#             (на этом пути archiso копирует систему в память и отмонтирует носитель).
# Использование: ci/smoke-qemu.sh <iso> <каталог для скриншотов>
# Скриншоты нужны для глаз, поэтому скрипт не падает, если гость медленный.
set -uo pipefail
ISO="${1:?iso}"; OUT="${2:?outdir}"
mkdir -p "$OUT"

if [ ! -w /dev/kvm ]; then
    echo "::warning::/dev/kvm недоступен — пропускаю загрузку в QEMU"
    exit 0
fi

QMP=/tmp/axon-qmp.sock

shot() {  # shot <имя> — снимок экрана через QMP screendump
    python3 - "$QMP" "$OUT/$1.ppm" <<'PY'
import json, socket, sys
s = socket.socket(socket.AF_UNIX); s.connect(sys.argv[1]); f = s.makefile("rw")
def cmd(c, **a):
    f.write(json.dumps({"execute": c, "arguments": a} if a else {"execute": c}) + "\n"); f.flush()
    while True:
        r = json.loads(f.readline())
        if "return" in r or "error" in r: return r
json.loads(f.readline())            # приветствие QMP
cmd("qmp_capabilities")
print(cmd("screendump", filename=sys.argv[2]))
PY
    convert "$OUT/$1.ppm" "$OUT/$1.png" && rm -f "$OUT/$1.ppm"
}

run() {  # run <мс до 1-го снимка> <имя1> <мс до 2-го> <имя2> <аргументы qemu...>
    local t1=$1 n1=$2 t2=$3 n2=$4; shift 4
    rm -f "$QMP"
    qemu-system-x86_64 -enable-kvm -cpu host -smp 4 -vga virtio -display none \
        -qmp "unix:$QMP,server,nowait" "$@" &
    local pid=$!
    sleep "$t1"; shot "$n1"
    sleep "$t2"; shot "$n2"
    kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
}

# 1) BIOS, как CD
run 35 boot 115 desktop -m 6G -cdrom "$ISO" -boot d

# 2) UEFI, как флешка
OVMF_CODE=$(ls /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd 2>/dev/null | head -1)
OVMF_VARS=$(ls /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd 2>/dev/null | head -1)
if [ -n "$OVMF_CODE" ] && [ -n "$OVMF_VARS" ]; then
    cp "$OVMF_VARS" /tmp/axon-ovmf-vars.fd
    run 6 uefi-menu 150 uefi-desktop -m 8G \
        -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
        -drive if=pflash,format=raw,file=/tmp/axon-ovmf-vars.fd \
        -drive file="$ISO",format=raw,if=virtio,readonly=on
else
    echo "::warning::OVMF не найден — пропускаю UEFI-прогон"
fi

ls -l "$OUT"
exit 0
