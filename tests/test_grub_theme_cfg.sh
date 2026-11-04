#!/usr/bin/env bash
# На настоящем grub.cfg из releng:
#  - тема включается только если её файлы нашлись (под Ventoy своя GRUB, ARCHISO_HINT может быть пуст);
#  - ни одна команда оформления не стоит «голой» — ошибка не должна останавливать загрузку;
#  - есть пункт «безопасный режим» с nomodeset и без quiet splash.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
cp tests/fixtures/releng-grub.cfg "$tmp"
ci/grub-theme-cfg.sh "$tmp"
ci/grub-safe-entry.sh "$tmp"
# то же, что делает build.sh для обычных пунктов
sed -i.bak '/archisobasedir=/{/accessibility/!{/nomodeset/!s/$/ quiet splash/;};}' "$tmp"; rm -f "$tmp.bak"

fail() { echo "FAIL: $*"; exit 1; }
grep -q 'search --no-floppy --set=axon_dev --file /boot/grub/themes/axon/theme.txt' "$tmp" || fail "нет поиска темы"
grep -q 'if \[ -n "${axon_dev}" \]' "$tmp" || fail "тема не под условием"
grep -q 'set theme=(${axon_dev})/boot/grub/themes/axon/theme.txt' "$tmp" || fail "нет set theme"
! grep -qE '^\s*loadfont \(' "$tmp" || fail "loadfont без if"
grep -q 'if loadfont (${axon_dev})/boot/grub/themes/axon/inter-bold-20.pf2' "$tmp" || fail "шрифт bold не под if"
! grep -q 'ARCHISO_HINT})/boot/grub/themes' "$tmp" || fail "остался путь через ARCHISO_HINT"
# безопасный режим
grep -q 'menuentry "AXON Linux — безопасный режим графики' "$tmp" || fail "нет пункта безопасного режима"
safe=$(awk '/безопасный режим графики/{f=1} f&&/linux \//{print; exit}' "$tmp")
[[ "$safe" == *nomodeset* ]] || fail "в безопасном режиме нет nomodeset"
[[ "$safe" != *splash* ]] || fail "в безопасном режиме есть splash"
echo PASS
