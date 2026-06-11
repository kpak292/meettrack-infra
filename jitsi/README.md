# Jitsi (igore-d02)

Деплой: `/opt/meettrack/meettrack-infra/jitsi/` на d02, `docker compose up -d`.
Живой `.env` лежит рядом с compose (не в git), ключи — см. `.env.example`.

## config/ — кастомные конфиги (вне docker-compose)

Контейнеры монтируют `${CONFIG}` (= `/root/.jitsi-meet-cfg` на d02). Файлы из
`config/` нужно вручную раскладывать по этим путям при настройке нового сервера:

| Файл в репо | Путь на сервере |
|---|---|
| `config/web/custom-config.js` | `${CONFIG}/web/custom-config.js` |
| `config/web/custom-interface_config.js` | `${CONFIG}/web/custom-interface_config.js` |
| `config/jicofo/custom-jicofo.conf` | `${CONFIG}/jicofo/custom-jicofo.conf` |
| `config/prosody/prosody-plugins-custom/mod_muc_hidden_occ.lua` | `${CONFIG}/prosody/prosody-plugins-custom/mod_muc_hidden_occ.lua` |

ВАЖНО: стартовый скрипт jitsi-web при каждом запуске контейнера ПЕРЕГЕНЕРИРУЕТ
`${CONFIG}/web/config.js` и дописывает в конец содержимое `custom-config.js`.
Поэтому любые правки конференс-конфига делать ТОЛЬКО в `custom-config.js`
(и коммитить сюда), а не в сгенерированный `config.js` — иначе фикс
пропадёт при первом рестарте jitsi-web.
