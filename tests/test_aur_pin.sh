#!/usr/bin/env bash
# ci/aur-pin-source.sh: git-источник PKGBUILD закрепляется на точном коммите (вместо ветки/HEAD).
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
SHA=0feee613b574f507ac0d6ef3ec8c7481cc9f4864
fail() { echo "FAIL: $*"; exit 1; }

cp tests/fixtures/aur-sweet-PKGBUILD "$tmp/a"
ci/aur-pin-source.sh "$tmp/a" "$SHA"
grep -q "source=(\"\$_pkgname::git+\$url.git#commit=$SHA\")" "$tmp/a" || fail "sweet: ветка не заменена коммитом"
! grep -q "branch=" "$tmp/a" || fail "sweet: осталась ветка"

cp tests/fixtures/aur-candy-PKGBUILD "$tmp/b"
ci/aur-pin-source.sh "$tmp/b" "$SHA"
grep -q "source=(\"git+\${url}.git#commit=$SHA\")" "$tmp/b" || fail "candy: коммит не добавлен"

# PKGBUILD без git-источника — ошибка (закреплять нечего, а мы просили)
printf 'source=("x.tar.gz::https://e/x.tar.gz")\n' > "$tmp/c"
! ci/aur-pin-source.sh "$tmp/c" "$SHA" 2>/dev/null || fail "нет git-источника — должно быть ошибкой"
echo PASS
