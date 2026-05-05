#!/bin/bash
RECORDING_DIR="$1"
WEBHOOK_SECRET="wh00k_s3cr3t_2026"
API_URL="https://157.22.128.243/api/v1/recordings/upload"
LOG_FILE="/tmp/jibri-finalize.log"

log() {
    echo "[$(date -Iseconds)] $*" | tee -a "$LOG_FILE"
}

VIDEO_FILE=$(find "$RECORDING_DIR" -name "*.mp4" | head -1)
if [ -z "$VIDEO_FILE" ]; then
    log "no .mp4 found in $RECORDING_DIR, exiting"
    exit 0
fi

ROOM_NAME=""
if [ -f "$RECORDING_DIR/metadata.json" ]; then
    ROOM_NAME=$(python3 -c "
import json
d = json.load(open('$RECORDING_DIR/metadata.json'))
url = d.get('meeting_url', '')
print(url.split('/')[-1].split('?')[0])
" 2>/dev/null)
fi

upload() {
    local file="$1" type="$2"
    local size_mb attempt http_code
    size_mb=$(du -m "$file" | cut -f1)
    log "uploading $type ($size_mb MB) for room=$ROOM_NAME from $file"
    for attempt in 1 2 3; do
        http_code=$(curl -sk -w '%{http_code}' -o /tmp/jibri-upload.out -X POST "$API_URL" \
            -H "X-Webhook-Secret: $WEBHOOK_SECRET" \
            -F "file=@$file" \
            -F "type=$type" \
            -F "roomName=$ROOM_NAME" \
            --max-time 1200)
        if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
            log "  attempt $attempt: HTTP $http_code (ok)"
            return 0
        fi
        log "  attempt $attempt: HTTP $http_code, body=$(head -c 200 /tmp/jibri-upload.out)"
        sleep $((attempt * 5))
    done
    log "FAILED $type after 3 attempts"
    return 1
}

upload "$VIDEO_FILE" "Video"

AUDIO_FILE="${RECORDING_DIR}/audio.mp3"
ffmpeg -y -i "$VIDEO_FILE" -vn -acodec libmp3lame -q:a 4 "$AUDIO_FILE" 2>>"$LOG_FILE"

if [ -f "$AUDIO_FILE" ]; then
    upload "$AUDIO_FILE" "Audio"
fi
