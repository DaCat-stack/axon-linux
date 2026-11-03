# AXON Linux

Игровой дистрибутив на базе Arch Linux + KDE Plasma 6.

## Как собирается
ISO собирает GitHub Actions (`.github/workflows/build-iso.yml`) при каждом пуше в `main`.
Скрипт `build.sh` берёт официальный профиль archiso `releng` и накладывает поверх него `profile/`:

- `profile/packages.x86_64` — дополнительные пакеты;
- `profile/airootfs/` — файлы, которые попадут в систему (конфиги, сервисы).

Готовый ISO: вкладка **Actions** → последний запуск → артефакт `axon-linux-iso`.

## Live-сессия
Автовход в KDE под пользователем `axon` (без пароля, sudo без пароля).
Раскладка: us/ru, переключение Alt+Shift.
