#!/usr/bin/env bash
# Загружает ISO в QEMU и снимает экран: boot.png (Plymouth) и desktop.png (рабочий стол).
# Использование: ci/smoke-qemu.sh <iso> <каталог для скриншотов>
# Скриншоты нужны для глазами, поэтому скрипт не падает, если гость медленный.
set -uo pipefail
ISO="${1:?iso}"; OUT="${2:?outdir}"
mkdir -p "$OUT"

if [ ! -w /dev/kvm ]; then
    echo "::warning::/dev/kvm недоступен — пропускаю загрузку в QEMU"
    exit 0
fi

QMP=/tmp/axon-qmp.sock
rm -f "$QMP"
qemu-system-x86_64 -enable-kvm -cpu host -m 6G -smp 4 \
    -vga virtio -display none \
    -cdrom "$ISO" -boot d \
    -qmp "unix:$QMP,server,nowait" &
QEMU_PID=$!

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

sleep 35;  shot boot
sleep 115; shot desktop
kill "$QEMU_PID" 2>/dev/null
ls -l "$OUT"
exit 0
