#!/usr/bin/env bash
# AXON на CachyOS: меню загрузки Limine скрыто (открывается, если зажать клавишу при включении),
# «CachyOS» → «AXON», окно входа — SDDM с темой AXON (Wayland, без X11).
# Изменения входа вступают в силу после перезагрузки. Можно запускать повторно.
#
#   curl -fsSLO https://raw.githubusercontent.com/DaCat-stack/axon-linux/main/tools/axon-boot-login.sh
#   sudo bash axon-boot-login.sh
set -euo pipefail

LIMINE_CONF=/boot/limine.conf

# Глобальные настройки Limine — строки до первой записи («/…»).
limine_edit() {  # limine_edit <limine.conf>
    local f="$1"
    awk '
        BEGIN { head = 1 }
        head && /^\// {
            print "timeout: 2"; print "quiet: yes"; head = 0
        }
        head && /^(timeout|quiet):/ { next }
        head && /^interface_branding:/ { print "interface_branding: AXON"; next }
        !head && /^\/\+?CachyOS[^\/]*$/ { sub(/CachyOS.*/, "AXON") }
        { print }
    ' "$f" > "$f.axon-new"
    # проверка: число записей верхнего уровня не изменилось
    [ "$(grep -c '^/' "$f")" = "$(grep -c '^/' "$f.axon-new")" ] || { rm -f "$f.axon-new"; echo "Limine: правка не сошлась — ничего не меняю"; return 1; }
    cat "$f.axon-new" > "$f" && rm -f "$f.axon-new"
}

if [ "${1:-}" = "--only-limine" ]; then
    limine_edit "$2"
    exit 0
fi

[ "$(id -u)" = 0 ] || { echo "Запусти через sudo: sudo bash $0"; exit 1; }
say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

if [ -f "$LIMINE_CONF" ]; then
    say "Меню загрузки Limine: скрыто, «CachyOS» → «AXON»"
    cp -n "$LIMINE_CONF" "$LIMINE_CONF.before-axon"
    limine_edit "$LIMINE_CONF"
    # генератор записей CachyOS тоже должен называть систему AXON
    if [ -f /etc/default/limine ] && ! grep -q '^TARGET_OS_NAME=' /etc/default/limine; then
        echo 'TARGET_OS_NAME="AXON"' >> /etc/default/limine
    fi
else
    echo "Limine не найден ($LIMINE_CONF) — меню загрузки не трогаю"
fi

say "Окно входа AXON (SDDM)"
pacman -S --needed --noconfirm sddm layer-shell-qt
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/20-axon-wayland.conf <<'CONF'
# AXON: экран входа на Wayland (X11 в системе нет) — через тот же KWin, что и рабочий стол
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1
CONF
[ -f /etc/sddm.conf.d/10-axon-theme.conf ] || printf '[Theme]\nCurrent=axon\n' > /etc/sddm.conf.d/10-axon-theme.conf
systemctl disable plasmalogin.service 2>/dev/null || true
systemctl enable sddm.service

say "Готово. Перезагрузись — будет сразу AXON, без меню, и окно входа AXON."
echo "Вернуть старый вход:  sudo systemctl disable sddm && sudo systemctl enable plasmalogin"
echo "Вернуть меню Limine:  sudo cp $LIMINE_CONF.before-axon $LIMINE_CONF"
