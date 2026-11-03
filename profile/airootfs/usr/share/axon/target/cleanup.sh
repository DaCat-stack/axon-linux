#!/bin/sh
# AXON: чистка установленной системы от всего, что нужно только live-режиму.
# Запускает Calamares (shellprocess@cleanup) внутри chroot новой системы.
T=/usr/share/axon/target

# --- live-пользователь и установщик ---
rm -f /etc/sudoers.d/axon-live
rm -f /etc/systemd/system/axon-live-user.service /etc/systemd/system/multi-user.target.wants/axon-live-user.service
rm -f /etc/skel/Desktop/axon-install.desktop /home/*/Desktop/axon-install.desktop
rm -f /usr/share/applications/axon-install.desktop /usr/share/applications/calamares.desktop
rm -f /usr/local/bin/axon-install
rm -f /etc/sddm.conf.d/zz-live.conf                       # автовход live; тема — в пакете axon-branding

# --- ядро: archiso убирает его из /boot, берём из пакета linux ---
set -- /usr/lib/modules/*/vmlinuz
[ "$#" -eq 1 ] || { echo "ожидалось одно ядро в /usr/lib/modules, найдено: $*" >&2; exit 1; }
install -Dm644 "$1" /boot/vmlinuz-linux

# --- зеркала pacman (в live их заполнял reflector во временном слое) ---
cp "$T/mirrorlist" /etc/pacman.d/mirrorlist

# --- остатки шаблона archiso (releng) ---
rm -f /etc/mkinitcpio.conf.d/archiso.conf
cp "$T/linux.preset" /etc/mkinitcpio.d/linux.preset
rm -f /etc/systemd/system/etc-pacman.d-gnupg.mount          # в live ключи pacman в tmpfs
rm -f /etc/systemd/logind.conf.d/do-not-suspend.conf
rm -f /etc/systemd/journald.conf.d/volatile-storage.conf
rm -f /etc/systemd/resolved.conf.d/archiso.conf /etc/ssh/sshd_config.d/10-archiso.conf
find /etc/systemd/system \( -name 'pacman-init.service' -o -name 'livecd-*' -o -name 'choose-mirror.service' \
    -o -name 'reflector.service' -o -name 'qemu-guest-agent.service' -o -name 'vbox*.service' \
    -o -name 'vmtoolsd.service' -o -name 'vmware-*.service' -o -name 'hv_*.service' \) -delete
rm -rf /root/.automated_script.sh /root/.zlogin /etc/motd \
    /usr/local/bin/choose-mirror /usr/local/bin/livecd-sound /usr/local/bin/Installation_guide /usr/local/share/livecd-sound

# --- безопасность: в шаблоне у root пустой пароль ---
passwd -l root

# --- ключи pacman (в live они были во временной памяти) ---
pacman-key --init
pacman-key --populate archlinux axon
exit 0
