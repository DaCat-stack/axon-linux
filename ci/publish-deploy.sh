#!/usr/bin/env bash
# Публикует каталог сайта в gh-pages репозитория axon-repo одним коммитом (история не копится,
# Pages переключает сайт целиком) и ждёт, пока GitHub Pages начнёт отдавать новую версию.
# Использование (на раннере): ci/publish-deploy.sh <каталог сайта> <подпись коммита>
set -euo pipefail
SITE="${1:?сайт}"; MSG="${2:?сообщение}"
BASE="${BASE:-https://dacat-stack.github.io/axon-repo}"
sudo chown -R "$(id -u):$(id -g)" "$SITE"      # контейнер мог сменить владельца файлов
cd "$SITE"
stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ) $MSG"
echo "$stamp" > stamp.txt
git checkout -q --orphan publish
git add -A
git -c user.name=axon-ci -c user.email=ci@axon-project.ru commit -qm "$stamp"
git branch -D gh-pages >/dev/null 2>&1 || true
git branch -m gh-pages
git push -q -f origin gh-pages

for _ in $(seq 1 60); do
    [ "$(curl -fs "$BASE/stamp.txt?$RANDOM" || true)" = "$stamp" ] && { echo "опубликовано: $stamp"; exit 0; }
    sleep 10
done
echo "::error::Pages не обновился за 10 минут"; exit 1
