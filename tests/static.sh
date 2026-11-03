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

exit "$FAILED"
