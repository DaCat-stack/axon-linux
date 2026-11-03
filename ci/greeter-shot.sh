#!/usr/bin/env bash
# Проверка QML окна входа и его скриншоты (1920x1080 и 3840x2160).
# Запускается внутри контейнера archlinux от root: ci/greeter-shot.sh <каталог для скриншотов>
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:?outdir}"
THEME="$ROOT/pkgsrc/axon-branding/usr/share/sddm/themes/axon"
mkdir -p "$OUT"

pacman -Syu --noconfirm --needed sddm qt6-declarative qt6-svg xorg-server-xvfb imagemagick inter-font xkeyboard-config

# синтаксис QML: ошибки валят шаг, предупреждения про контекст SDDM — нет
if /usr/lib/qt6/bin/qmllint "$THEME"/*.qml 2>&1 | tee "$OUT/qmllint.txt" | grep -q '^Error'; then
    echo "qmllint нашёл ошибки"; exit 1
fi

# пользователь, чтобы в окне было кого показывать
id dacat >/dev/null 2>&1 || useradd -m -c DaCat dacat

for res in 1920x1080 3840x2160; do
    Xvfb :9 -screen 0 "${res}x24" & XVFB=$!
    sleep 2
    DISPLAY=:9 QT_QPA_PLATFORM=xcb sddm-greeter-qt6 --test-mode --theme "$THEME" > "$OUT/greeter-$res.log" 2>&1 & G=$!
    sleep 8
    DISPLAY=:9 import -window root "$OUT/greeter-$res.png"
    kill "$G" "$XVFB" 2>/dev/null || true
    wait 2>/dev/null || true
done
ls -l "$OUT"
