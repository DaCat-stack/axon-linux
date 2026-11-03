# Ключ подписи пакетов AXON

| | |
|---|---|
| Владелец | `AXON Linux <packages@axon-project.ru>` |
| Главный ключ (только сертификация, на маке владельца) | `98546F93C7C579F0A058B5F712B7AFBC4F2420BE`, до 2031-11-02 |
| Подключ подписи (в GitHub Actions) | `121FFA1C4FB714C2FAD5006D15386E89DAE98A01`, до 2028-11-02 |

- Пароль главного ключа — в Связке ключей macOS, запись `axon-gpg`:
  `security find-generic-password -s axon-gpg -w`
- Резервная копия: `~/Documents/axon-keys/` (секретный ключ, сертификат отзыва, публичный ключ).
  Скопировать на флешку/в надёжное место — если пропадут и мак, и копия, придётся выпускать новый ключ.
- Секреты в `DaCat-stack/axon-linux`: `AXON_SIGN_SUBKEY` (только подключ), `AXON_SIGN_PASS`, `AXON_KEY_FPR`,
  `AXON_REPO_DEPLOY_KEY` (запись в `DaCat-stack/axon-repo`).

## Продлить подключ (до 2028-11-02)
`gpg --quick-set-expire 98546F93C7C579F0A058B5F712B7AFBC4F2420BE 2y 121FFA1C4FB714C2FAD5006D15386E89DAE98A01`,
затем заново экспортировать публичный ключ в `packages/axon-keyring/axon.gpg` и выпустить `axon-keyring`.

## Если подключ утёк
1. Отозвать подключ на маке (`gpg --edit-key …` → `key 1` → `revkey`), создать новый подключ подписи.
2. Обновить `packages/axon-keyring/axon.gpg`, выпустить `axon-keyring` (подписав уже новым подключом).
3. Заменить секреты `AXON_SIGN_SUBKEY` / `AXON_SIGN_PASS`.
