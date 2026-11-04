#!/usr/bin/env bash
# Закрепляет git-источник в PKGBUILD на точном коммите: «git+URL[#branch=…]» → «git+URL#commit=SHA».
# Так в подписанный репозиторий AXON попадает ровно просмотренная версия исходников, а не их новый HEAD.
# Использование: ci/aur-pin-source.sh <PKGBUILD> <sha>
set -euo pipefail
f="$1"; sha="$2"
[[ "$sha" =~ ^[0-9a-f]{40}$ ]] || { echo "неверный коммит: $sha" >&2; exit 1; }
grep -q 'git+' "$f" || { echo "в $f нет git-источника — закреплять нечего" >&2; exit 1; }
# убираем старый фрагмент (#branch=…, #tag=…, #commit=…) и ставим наш коммит
sed -E -i.bak "/^source=/ s/(git\+[^\"'#) ]+)(#[^\"') ]*)?/\1#commit=$sha/" "$f"
rm -f "$f.bak"
grep -q "#commit=$sha" "$f"
