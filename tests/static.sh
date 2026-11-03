#!/usr/bin/env bash
# Статические проверки профиля AXON. Работают и на маке, и в CI.
# Использование: tests/static.sh   (код выхода 0 — всё хорошо)
set -uo pipefail
cd "$(dirname "$0")/.."
AIR=profile/airootfs
FAILED=0

check() {
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo "ok   $name"
    else
        echo "FAIL $name"
        FAILED=1
    fi
}

symlinks_absolute() {
    local l
    while IFS= read -r l; do
        [[ "$(readlink "$l")" == /* ]] || return 1
    done < <(find "$AIR" -type l)
}

has_entries() { grep -qv '^[[:space:]]*\(#\|$\)' "$1"; }

# --- база ---
check "build.sh синтаксис" bash -n build.sh
check "симлинки в airootfs абсолютные" symlinks_absolute
check "aur/packages.txt не пустой" has_entries aur/packages.txt
for f in ci/*.sh; do check "$f синтаксис" bash -n "$f"; done

png_size() {  # png_size <файл> <ширина> <высота>
    file "$1" | grep -q "PNG image data, $2 x $3"
}
json_id() {   # json_id <файл> <ожидаемый KPlugin.Id>
    python3 -c 'import json,sys; assert json.load(open(sys.argv[1]))["KPlugin"]["Id"]==sys.argv[2]' "$1" "$2"
}

# --- обои ---
WP=$AIR/usr/share/wallpapers/AXON
check "обои 3840x2160" png_size $WP/contents/images/3840x2160.png 3840 2160
check "обои 1920x1080" png_size $WP/contents/images/1920x1080.png 1920 1080
check "превью обоев 400x225" png_size $WP/contents/screenshot.png 400 225
check "обои metadata.json" json_id $WP/metadata.json AXON

has() { grep -q -- "$2" "$1"; }   # has <файл> <строка>

# --- Plymouth ---
PT=$AIR/usr/share/plymouth/themes/axon
for f in axon.plymouth axon.script blue.png white.png glow.png dot.png field.png sheen-00.png sheen-11.png; do
    check "plymouth: $f" test -s "$PT/$f"
done
check "plymouth: модуль script" has $PT/axon.plymouth "ModuleName=script"
check "plymouth: ImageDir" has $PT/axon.plymouth "ImageDir=/usr/share/plymouth/themes/axon"
check "plymouth: ScriptFile" has $PT/axon.plymouth "ScriptFile=/usr/share/plymouth/themes/axon/axon.script"
check "plymouth: тема axon по умолчанию" has $AIR/etc/plymouth/plymouthd.conf "Theme=axon"
check "plymouth: размер от высоты экрана" has $PT/axon.script "Window.GetHeight()"
check "plymouth: окно пароля" has $PT/axon.script "SetDisplayPasswordFunction"
check "plymouth: пакет в списке" grep -qx plymouth profile/packages.x86_64
check "build.sh: хук plymouth" has build.sh "kms plymouth"
check "build.sh: quiet splash" has build.sh "quiet splash"

# --- SDDM ---
ST=$AIR/usr/share/sddm/themes/axon
for f in metadata.desktop theme.conf Main.qml TopBar.qml LoginCard.qml PowerBar.qml Avatar.qml background.png logo.png icons/arrow.svg; do
    check "sddm: $f" test -s "$ST/$f"
done
check "sddm: Qt6" has $ST/metadata.desktop "QtVersion=6"
check "sddm: MainScript" has $ST/metadata.desktop "MainScript=Main.qml"
check "sddm: карточка только на основном экране" has $ST/Main.qml "primaryScreen"
check "sddm: «Введите пароль»" has $ST/LoginCard.qml "Введите пароль"
for w in Сон Перезагрузка Выключение; do check "sddm: «${w}»" has $ST/PowerBar.qml "$w"; done
check "sddm: раскладка в верхней панели" has $ST/TopBar.qml "keyboard.currentLayout"
check "sddm: тема включена" has $AIR/etc/sddm.conf.d/axon.conf "Current=axon"
check "sddm: шрифт Inter" grep -qx inter-font profile/packages.x86_64

# --- пресеты рабочего стола ---
LNF=$AIR/usr/share/plasma/look-and-feel
for v in a b c; do
    P=$LNF/org.axon.desktop.$v
    check "пресет $v: metadata.json" json_id $P/metadata.json org.axon.desktop.$v
    check "пресет $v: defaults" has $P/contents/defaults "ColorScheme=BreezeDark"
    check "пресет $v: превью" test -s $P/contents/previews/preview.png
    check "пресет $v: layout JS синтаксис" node --check $P/contents/layouts/org.kde.plasma.desktop-layout.js
    check "пресет $v: обои AXON" has $P/contents/layouts/org.kde.plasma.desktop-layout.js "/usr/share/wallpapers/AXON"
done
check "пресет a: меню kickoff" has $LNF/org.axon.desktop.a/contents/layouts/org.kde.plasma.desktop-layout.js "org.kde.plasma.kickoff"
check "пресет a: плавающая панель" has $LNF/org.axon.desktop.a/contents/layouts/org.kde.plasma.desktop-layout.js "floating"
check "пресет b: глобальное меню" has $LNF/org.axon.desktop.b/contents/layouts/org.kde.plasma.desktop-layout.js "org.kde.plasma.appmenu"
check "пресет c: док слева" has $LNF/org.axon.desktop.c/contents/layouts/org.kde.plasma.desktop-layout.js '"left"'
check "по умолчанию пресет A" has $AIR/etc/xdg/kdeglobals "LookAndFeelPackage=org.axon.desktop.a"
check "иконки Papirus-Dark" has $AIR/etc/xdg/kdeglobals "Theme=Papirus-Dark"
check "лого в pixmaps" test -s $AIR/usr/share/pixmaps/axon-logo.png
for p in papirus-icon-theme discord; do check "пакет $p" grep -qx $p profile/packages.x86_64; done

exit "$FAILED"
