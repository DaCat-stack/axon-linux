#!/usr/bin/env bash
# Вставляет хук plymouth в HOOKS конфига mkinitcpio. Использование: ci/add-plymouth-hook.sh <файл>
# plymouth нужен сразу после kms; в releng kms нет — тогда ставим «kms plymouth» после modconf.
set -euo pipefail
f="$1"
if grep -Eq '^HOOKS=\(.*[ (]kms[ )]' "$f"; then
    sed -i.bak -E '/^HOOKS=/ s/([ (])kms([ )])/\1kms plymouth\2/' "$f"
else
    sed -i.bak -E '/^HOOKS=/ s/([ (])modconf([ )])/\1modconf kms plymouth\2/' "$f"
fi
rm -f "$f.bak"
grep -Eq '^HOOKS=\(.* kms plymouth[ )]' "$f"
