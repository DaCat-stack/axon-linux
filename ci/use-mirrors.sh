#!/usr/bin/env bash
# Внутри контейнера archlinux: несколько зеркал Arch вместо одного — если одно перестаёт
# отдавать файлы, pacman сам берёт следующее. Плюс повторы загрузки.
set -euo pipefail
cat > /etc/pacman.d/mirrorlist <<'LIST'
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://fastly.mirror.pkgbuild.com/$repo/os/$arch
Server = https://arch.mirror.constant.com/$repo/os/$arch
LIST
grep -q '^ParallelDownloads' /etc/pacman.conf && sed -i 's/^ParallelDownloads.*/ParallelDownloads = 3/' /etc/pacman.conf
