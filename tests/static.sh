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
BR=pkgsrc/axon-branding
WP=$BR/usr/share/wallpapers/AXON
check "обои 3840x2160" png_size $WP/contents/images/3840x2160.png 3840 2160
check "обои 1920x1080" png_size $WP/contents/images/1920x1080.png 1920 1080
check "превью обоев 400x225" png_size $WP/contents/screenshot.png 400 225
check "обои metadata.json" json_id $WP/metadata.json AXON

has() { grep -q -- "$2" "$1"; }   # has <файл> <строка>

# --- Plymouth ---
PT=$BR/usr/share/plymouth/themes/axon
for f in axon.plymouth axon.script blue.png white.png glow.png dot.png field.png sheen-00.png sheen-11.png; do
    check "plymouth: $f" test -s "$PT/$f"
done
check "plymouth: модуль script" has $PT/axon.plymouth "ModuleName=script"
check "plymouth: ImageDir" has $PT/axon.plymouth "ImageDir=/usr/share/plymouth/themes/axon"
check "plymouth: ScriptFile" has $PT/axon.plymouth "ScriptFile=/usr/share/plymouth/themes/axon/axon.script"
check "plymouth: тема axon ставится пакетом" has packages/axon-branding/axon-branding.install "plymouth-set-default-theme axon"
check "plymouthd.conf не в airootfs (он от пакета plymouth)" test ! -e $AIR/etc/plymouth/plymouthd.conf
check "plymouth: размер от высоты экрана" has $PT/axon.script "Window.GetHeight()"
check "plymouth: окно пароля" has $PT/axon.script "SetDisplayPasswordFunction"
check "plymouth: пакет в списке" grep -qx plymouth profile/packages.x86_64
check "build.sh: хук plymouth" has build.sh "add-plymouth-hook.sh"
check "хук plymouth на реальном конфиге releng" tests/test_plymouth_hook.sh
check "build.sh: quiet splash" has build.sh "quiet splash"

# --- SDDM ---
ST=$BR/usr/share/sddm/themes/axon
for f in metadata.desktop theme.conf Main.qml TopBar.qml LoginCard.qml PowerBar.qml Avatar.qml background.png logo.png icons/arrow.svg; do
    check "sddm: $f" test -s "$ST/$f"
done
check "sddm: Qt6" has $ST/metadata.desktop "QtVersion=6"
check "sddm: MainScript" has $ST/metadata.desktop "MainScript=Main.qml"
check "sddm: карточка только на основном экране" has $ST/Main.qml "primaryScreen"
check "sddm: «Введите пароль»" has $ST/LoginCard.qml "Введите пароль"
for w in Сон Перезагрузка Выключение; do check "sddm: «${w}»" has $ST/PowerBar.qml "$w"; done
check "sddm: раскладка в верхней панели" has $ST/TopBar.qml "keyboard.currentLayout"
check "sddm: тема включена" has $BR/etc/sddm.conf.d/10-axon-theme.conf "Current=axon"
check "sddm: автовход только в live" has $AIR/etc/sddm.conf.d/zz-live.conf "User=axon"
check "cleanup убирает автовход live" has $AIR/usr/share/axon/target/cleanup.sh "zz-live.conf"
check "sddm: шрифт Inter" grep -qx inter-font profile/packages.x86_64

# --- пресеты рабочего стола ---
LNF=$BR/usr/share/plasma/look-and-feel
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
check "по умолчанию пресет A" has $BR/etc/xdg/kdeglobals "LookAndFeelPackage=org.axon.desktop.a"
check "иконки Papirus-Dark" has $BR/etc/xdg/kdeglobals "Theme=Papirus-Dark"
check "лого в pixmaps" test -s $BR/usr/share/pixmaps/axon-logo.png
for p in papirus-icon-theme discord; do check "пакет $p" grep -qx $p profile/packages.x86_64; done

# --- окно приветствия ---
WR=pkgsrc/axon-welcome
WL=$WR/usr/lib/axon-welcome/axon_welcome
check "приветствие: юнит-тесты" python3 -m unittest tests/test_presets.py
for f in $WL/main.py $WL/Main.qml $WR/usr/bin/axon-welcome $WR/usr/share/applications/axon-welcome.desktop $WR/etc/xdg/autostart/axon-welcome.desktop; do
    check "приветствие: ${f#$WR}" test -s "$f"
done
check "приветствие: пакет ставит запуск с правами 755" has packages/axon-welcome/PKGBUILD "install -Dm755 .*usr/bin/axon-welcome"
check "приветствие: автозапуск с --autostart" has $WR/etc/xdg/autostart/axon-welcome.desktop "axon-welcome --autostart"
check "приветствие: заголовок" has $WL/Main.qml "Выбери свой стиль"
check "приветствие: кнопка «Позже»" has $WL/Main.qml "Позже"
check "приветствие: python синтаксис" python3 -m py_compile $WL/main.py
check "пакет pyside6" grep -qx pyside6 profile/packages.x86_64

# --- установщик Calamares ---
CA=$AIR/etc/calamares
yaml_has() { grep -Eq -- "$2" "$1"; }
check "calamares: settings.conf" test -s $CA/settings.conf
check "calamares: шаги показа" python3 tests/calamares_sequence.py $CA/settings.conf
check "calamares: по умолчанию «рядом»" yaml_has $CA/modules/partition.conf '^initialPartitioningChoice: *alongside'
check "calamares: GRUB для EFI" yaml_has $CA/modules/bootloader.conf '^efiBootLoader: *"grub"'
check "calamares: os-prober включён" yaml_has $CA/modules/grubcfg.conf 'GRUB_DISABLE_OS_PROBER: *false'
check "calamares: quiet splash" yaml_has $CA/modules/grubcfg.conf 'splash'
for f in /etc/sudoers.d/axon-live axon-live-user.service /etc/skel/Desktop/axon-install.desktop mkinitcpio.conf.d/archiso.conf etc-pacman.d-gnupg.mount do-not-suspend.conf; do
    check "calamares: чистка $f" has $AIR/usr/share/axon/target/cleanup.sh "$f"
done
for f in branding.desc show.qml stylesheet.qss logo.png; do check "calamares: брендинг $f" test -s $CA/branding/axon/$f; done
check "calamares: чистка запускается" has $CA/modules/shellprocess-cleanup.conf "cleanup.sh"
check "calamares: root заблокирован" has $AIR/usr/share/axon/target/cleanup.sh "passwd -l root"
for t in "Игры из Steam" "Программы Windows" "Твой стиль" "Магазин приложений"; do
    check "calamares: слайд «${t}»" has $CA/branding/axon/show.qml "$t"
done
check "calamares: ярлык в live" test -s $AIR/etc/skel/Desktop/axon-install.desktop
for p in calamares grub os-prober efibootmgr ntfs-3g; do check "пакет $p" grep -qx $p profile/packages.x86_64; done

# --- btrfs и снимки ---
check "снимки: тест скрипта" tests/test_snapshots.sh
check "установщик: btrfs по умолчанию" yaml_has $CA/modules/partition.conf '^defaultFileSystemType: *"btrfs"'
for sv in "/@" "/@home" "/@cache" "/@log" "/@snapshots"; do check "подтом $sv" yaml_has $CA/modules/mount.conf "subvolume: *$sv\$"; done
check "снимки: шаг Calamares" has $CA/modules/shellprocess-snapshots.conf "snapshots.sh"
for p in snapper snap-pac grub-btrfs inotify-tools btrfs-progs; do check "пакет $p" grep -qx $p profile/packages.x86_64; done

# --- тема меню загрузки GRUB ---
GT=$BR/usr/share/grub/themes/axon
check "grub: theme.txt" test -s $GT/theme.txt
theme_files_exist() {  # каждая картинка из theme.txt существует
    local f
    for f in $(grep -oE '"[^"]+\.png"' $GT/theme.txt | tr -d '"' | sed 's/\*/c/'); do test -s "$GT/$f" || return 1; done
}
check "grub: все картинки темы на месте" theme_files_exist
for n in nw n ne e se s sw w c; do check "grub: select_$n.png" test -s $GT/select_$n.png; done
for i in axon windows efi; do check "grub: иконка $i" test -s $GT/icons/$i.png; done
check "grub: шрифты собираются при сборке пакета" has packages/axon-branding/PKGBUILD "grub-mkfont"
grub_ranges_ok() {  # grub-mkfont -r принимает только пары a-b
    local r; r=$(grep -oE 'ranges=[^ ]+' packages/axon-branding/PKGBUILD | cut -d= -f2)
    [ -n "$r" ] && ! tr ',' '\n' <<<"$r" | grep -vqE '^0x[0-9A-Fa-f]+-0x[0-9A-Fa-f]+$'
}
check "grub: диапазоны шрифта в формате grub-mkfont" grub_ranges_ok
check "grub: в шрифтах есть кириллица" has packages/axon-branding/PKGBUILD "0x400-0x4FF"
check "grub: тема включена в установленной системе" yaml_has $CA/modules/grubcfg.conf 'GRUB_THEME: *"/usr/share/grub/themes/axon/theme.txt"'
check "grub: графический режим (не console)" sh -c "! grep -q 'GRUB_TERMINAL_OUTPUT: *\"console\"' $CA/modules/grubcfg.conf"
check "grub: снимки в меню по-русски" has $AIR/usr/share/axon/target/snapshots.sh "GRUB_BTRFS_SUBMENUNAME"

# --- меню флешки: GRUB с темой AXON ---
check "флешка: UEFI грузится через GRUB" has build.sh "uefi.systemd-boot/uefi.grub"
check "флешка: тема берётся из пакета axon-branding" has build.sh "usr/share/grub/themes/axon"
check "флешка: графический режим и тема в grub.cfg" has build.sh "grub-theme-cfg.sh"
check "флешка: правка grub.cfg на настоящем releng" tests/test_grub_theme_cfg.sh
check "CI: загрузка как с флешки (UEFI, диск, 8 ГБ)" has ci/smoke-qemu.sh "OVMF"
check "CI: журнал гостя для разбора ошибок" has ci/smoke-qemu.sh "guest-exec"

check "BIOS-меню: заставка AXON" png_size branding/syslinux-splash.png 640 480
check "BIOS-меню: заставка подменяется при сборке" has build.sh "syslinux-splash.png"

# --- устойчивость CI к сбоям зеркал Arch ---
check "CI: список зеркал с запасными" sh -c 'test "$(grep -c "^Server" ci/use-mirrors.sh)" -ge 4'
for f in build.sh ci/greeter-shot.sh ci/publish-build.sh ci/publish-promote.sh ci/e2e-repo.sh; do
    check "CI: $f берёт запасные зеркала" has $f "use-mirrors.sh"
done

# --- исправления после ревью ---
CL=$AIR/usr/share/axon/target/cleanup.sh
check "fix1: unpackfs не зависит от флешки (copytoram)" sh -c "! grep -q bootmnt $CA/modules/unpackfs.conf"
check "fix1: ядро берётся из /usr/lib/modules" has $CL "/usr/lib/modules"
check "fix2: ярлык установки убран и из домашних папок" has $CL "/home/\*/Desktop/axon-install.desktop"
check "fix2: команда axon-install убрана" has $CL "rm -f /usr/local/bin/axon-install"
check "fix3: зеркала pacman в установленной системе" has $CL "/etc/pacman.d/mirrorlist"
check "fix3: в mirrorlist есть сервер" grep -q "^Server = " $AIR/usr/share/axon/target/mirrorlist
check "fix4: обои AXON на экране блокировки" has $BR/etc/xdg/kscreenlockerrc "Image=file:///usr/share/wallpapers/AXON"
check "fix5: Binding не восстанавливает старое имя" test "$(grep -c 'restoreMode: Binding.RestoreNone' $ST/LoginCard.qml)" -eq 3
check "fix6: заставка KDE отключена системно" has $BR/etc/xdg/ksplashrc "Engine=none"
check "fix7: без GRUB_SAVEDEFAULT (btrfs)" sh -c "! grep -q SAVEDEFAULT $CA/modules/grubcfg.conf"

# --- пакеты AXON ---
pkgbuild_ok() {  # pkgbuild_ok <PKGBUILD>
    bash -n "$1" && (source "$1" && [[ "$pkgname" == axon-* ]] && [[ " ${arch[*]} " =~ \ (any|x86_64)\  ]])
}
check "есть пакет axon-keyring" test -s packages/axon-keyring/PKGBUILD
for pb in packages/*/PKGBUILD; do
    [ -e "$pb" ] && check "PKGBUILD ${pb#packages/}" pkgbuild_ok "$pb"
done
for n in axon-branding axon-welcome; do check "есть пакет $n" test -s packages/$n/PKGBUILD; done
for pb in packages/*/PKGBUILD; do check "версия из git: ${pb#packages/}" has "$pb" 'pkgver=${AXON_PKGVER:-0}'; done
arch_owned() { ! find pkgsrc -path '*/etc/plymouth/plymouthd.conf' -o -path '*/etc/pacman.conf' -o -path '*/etc/sddm.conf' -o -path '*/etc/mkinitcpio.conf' | grep -q .; }
check "пакеты не трогают файлы пакетов Arch" arch_owned
for p in axon-keyring axon-branding axon-welcome; do check "в ISO пакет $p" grep -qx $p profile/packages.x86_64; done
check "сборка ISO берёт полную историю git" has .github/workflows/build-iso.yml "fetch-depth: 0"
check "свои пакеты собираются без проверки зависимостей" has ci/build-packages.sh "makepkg -d"
check "скриншоты окна входа смотрят в pkgsrc" has ci/greeter-shot.sh "pkgsrc/axon-branding/usr/share/sddm/themes/axon"
check "уведомление об обновлениях: тест" tests/test_update_age.sh
check "уведомление: скрипт с правами 755" has packages/axon-branding/PKGBUILD "install -Dm755 .*usr/lib/axon/check-updates-age"
check "уведомление: таймер включён для всех" has packages/axon-branding/PKGBUILD "timers.target.wants/axon-update-age.timer"
check "уведомление: зависимость libnotify" has packages/axon-branding/PKGBUILD "libnotify"
for f in ci/repo-add-channel.sh ci/publish-build.sh ci/publish-promote.sh ci/publish-deploy.sh ci/e2e-repo.sh; do check "$f исполняемый" test -x $f; done
check "публикация: workflow пакетов" has .github/workflows/packages.yml "ci/e2e-repo.sh"
check "ISO: в pacman.conf установленной системы есть [axon]" has build.sh "Server = https://dacat-stack.github.io/axon-repo/axon/"
check "ISO: [axon] только с подписью" has build.sh "SigLevel = Required DatabaseRequired"
check "live: ключ AXON при старте" has $AIR/etc/systemd/system/pacman-init.service.d/axon.conf "pacman-key --populate axon"
check "установка: ключ AXON в связке" has $AIR/usr/share/axon/target/cleanup.sh "pacman-key --populate archlinux axon"
check "комплект axon-desktop тянет все части" sh -c 'grep -q "axon-branding" packages/axon-desktop/PKGBUILD && grep -q "axon-welcome" packages/axon-desktop/PKGBUILD && grep -q "axon-keyring" packages/axon-desktop/PKGBUILD'
check "в ISO стоит комплект axon-desktop" grep -qx axon-desktop profile/packages.x86_64
check "e2e проверяет комплект" has .github/workflows/packages.yml "axon-desktop"
check "ci/build-packages.sh существует" test -x ci/build-packages.sh
check "build.sh собирает пакеты AXON" has build.sh "build-packages.sh"

# --- права: mkarchiso копирует airootfs без прав, исполняемые файлы надо перечислить ---
while IFS= read -r f; do
    check "права в profiledef: ${f#$AIR}" grep -qF "[\"${f#$AIR}\"]=\"0:0:755\"" build.sh
done < <(find $AIR -type f -perm -u+x)

exit "$FAILED"
