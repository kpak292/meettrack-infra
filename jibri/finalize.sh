#!/bin/bash
RECORDING_DIR="$1"
WEBHOOK_SECRET="wh00k_s3cr3t_2026"
API_URL="https://157.22.128.243/api/v1/recordings/upload"

VIDEO_FILE=$(find "$RECORDING_DIR" -name "*.mp4" | head -1)
if [ -z "$VIDEO_FILE" ]; then
    exit 0
fi

# Get room name from metadata
ROOM_NAME=""
if [ -f "$RECORDING_DIR/metadata.json" ]; then
    ROOM_NAME=$(python3 -c "
import json
d = json.load(open('$RECORDING_DIR/metadata.json'))
url = d.get('meeting_url', '')
print(url.split('/')[-1].split('?')[0])
" 2>/dev/null)
fi

# Upload video
curl -sk -X POST "$API_URL" \
    -H "X-Webhook-Secret: $WEBHOOK_SECRET" \
    -F "file=@$VIDEO_FILE" \
    -F "type=Video" \
    -F "roomName=$ROOM_NAME" \
    --max-time 300

# Extract and upload audio
AUDIO_FILE="${RECORDING_DIR}/audio.mp3"
ffmpeg -i "$VIDEO_FILE" -vn -acodec libmp3lame -q:a 4 "$AUDIO_FILE" 2>/dev/null

if [ -f "$AUDIO_FILE" ]; then
    curl -sk -X POST "$API_URL" \
        -H "X-Webhook-Secret: $WEBHOOK_SECRET" \
        -F "file=@$AUDIO_FILE" \
        -F "type=Audio" \
        -F "roomName=$ROOM_NAME" \
        --max-time 300
fi
