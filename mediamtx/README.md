# Broadcast infra — «канал объявлений» (all-hands)

Инфраструктура для трансляции: **медиа только у ведущего**, сотрудники смотрят HLS
и пишут в чат (SignalR). Зрители **не заходят в Jitsi** — узкое место Prosody/JVB
убрано архитектурно.

## Компоненты

```
Админ (браузер) ─ вещает в Jitsi-комнату broadcast<id> (только ведущие)
      │
      ▼
Jibri (d03, STREAMING) ─ RTMP ─▶ MediaMTX (d01 :1935)
                                     │  ffmpeg: транскод в 480p ~1 Mbps → HLS в /hls volume
                                     ▼
                              nginx (meettrack-web, d01) отдаёт /hls/<id>/index.m3u8
                                     ▲
Сотрудники (web/mobile) ─ смотрят HLS, чат через SignalR ─┘
```

**Почему транскод на MediaMTX, а не на Jibri:** Jibri пишет обычные звонки в 1080p.
Понижать разрешение в Jibri — испортить записи. Поэтому Jibri стримит нативно (d03→d01
по внутренней сети 10 Gbit — не жалко), а вниз до 480p транскодит MediaMTX (одна ffmpeg
на активную трансляцию, ~0.5–1 ядро на почти простаивающем d01).

## Поток URL

| Что | URL |
|-----|-----|
| RTMP ingest (Jibri → MediaMTX) | `rtmp://10.120.4.14:1935/<broadcastId>` |
| HLS (зритель ← nginx) | `https://meet-track-dev.ipoint.uz/hls/<broadcastId>/index.m3u8` |

API строит эти URL из `Broadcast__RtmpBaseUrl` / `Broadcast__HlsBaseUrl` (см. compose).

## Деплой (d01)

```bash
# на d01, в каталоге infra
docker compose pull meettrack-mediamtx
docker compose up -d meettrack-mediamtx
docker compose up -d meettrack-web   # подхватит новый nginx.conf + /hls volume
```

Порт **1935** должен быть открыт с d03 на d01 (внутренняя сеть). Наружу 1935 публиковать
не нужно.

## Деплой Jibri (d03)

Пересобрать образ (добавлен `rtmp-allow-list = [".*"]`):

```bash
# на d03
docker compose build jibri && docker compose up -d jibri
```

> ⚠️ **Проверить вживую:** механизм передачи произвольного RTMP-URL в Jibri зависит от
> версии. Мы передаём полный `rtmp://...` в поле `youTubeStreamKey` API `startService`, а
> `rtmp-allow-list=[".*"]` снимает ограничение на YouTube/Facebook. Если Jibri всё равно
> подставляет YouTube-префикс — нужно переопределить конструирование URL (см. jibri
> streaming docs для конкретной версии stable-9823).

## Gate-тест пропускной способности (ОБЯЗАТЕЛЕН до прода)

Egress HLS ложится на аплинк d01. Реальная скорость eth0 неизвестна (VPS отдаёт `-1`).
Замерить перед запуском на аудиторию:

```bash
# на d01
apt-get install -y iperf3     # или docker run networkstatic/iperf3
iperf3 -c <внешний_iperf3_сервер> -t 20
```

Ориентиры egress (373 зрителя):

| Профиль | На зрителя | ×373 | На 1 Gbps |
|---------|-----------|------|-----------|
| 360p | ~0.5 Mbps | ~187 Mbps | ~19% |
| **480p (дефолт)** | ~1 Mbps | ~373 Mbps | ~37% |
| 720p | ~2 Mbps | ~746 Mbps | опасно |

Если аплинк ~1 Gbps — 480p проходит с запасом. Если ~100 Mbps — снизить транскод до 360p
(`-b:v 600k -vf scale=-2:360` в `mediamtx.yml`) или ограничиться audio-only.

## Ограничение

Jibri **один** и делает одну сессию за раз. Во время трансляции обычные звонки **не
пишутся**. Планировать all-hands в окно без активных встреч; API отдаёт 409, если Jibri занят.
