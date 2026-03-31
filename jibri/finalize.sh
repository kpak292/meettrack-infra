#!/bin/bash
# Jibri recording finalization script
# Called when recording is complete
# $1 = recording directory path

RECORDING_DIR="$1"
RECORDING_FILE=$(find "$RECORDING_DIR" -name "*.mp4" | head -1)

if [ -z "$RECORDING_FILE" ]; then
    echo "No recording file found in $RECORDING_DIR"
    exit 1
fi

# Extract meeting ID from directory name
MEETING_ID=$(basename "$RECORDING_DIR")

echo "Finalizing recording for meeting: $MEETING_ID"
echo "File: $RECORDING_FILE"

# Upload to API
curl -X POST "http://meettrack-api:8080/api/v1/recordings/upload" \
    -F "file=@$RECORDING_FILE" \
    -F "meetingId=$MEETING_ID" \
    -F "type=Video" \
    -H "Authorization: Bearer ${API_SERVICE_TOKEN}" \
    --max-time 300

# Extract and upload audio
AUDIO_FILE="${RECORDING_DIR}/audio.mp3"
ffmpeg -i "$RECORDING_FILE" -vn -acodec libmp3lame -q:a 4 "$AUDIO_FILE" 2>/dev/null

if [ -f "$AUDIO_FILE" ]; then
    curl -X POST "http://meettrack-api:8080/api/v1/recordings/upload" \
        -F "file=@$AUDIO_FILE" \
        -F "meetingId=$MEETING_ID" \
        -F "type=Audio" \
        -H "Authorization: Bearer ${API_SERVICE_TOKEN}" \
        --max-time 300
fi

# Cleanup local files
rm -rf "$RECORDING_DIR"

echo "Recording finalized successfully"
