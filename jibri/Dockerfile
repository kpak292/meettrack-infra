FROM jitsi/jibri:stable-9823

# Install dbus for Chrome audio (openfun approach)
USER root
RUN apt-get update && apt-get install -y dbus dbus-x11 rtkit && rm -rf /var/lib/apt/lists/*
RUN adduser jibri rtkit 2>/dev/null || true

# PulseAudio config: create virtual sink v1 as default
# Chrome will output audio here, FFmpeg captures from v1.monitor
RUN mkdir -p /home/jibri/.config/pulse
COPY pulse-default.pa /home/jibri/.config/pulse/default.pa
RUN chown -R jibri:jibri /home/jibri/.config/pulse

# Chrome flags - patch the template to include --ignore-certificate-errors
# The init script generates /etc/jitsi/jibri/jibri.conf from /defaults/jibri.conf
# We modify the template to add our flags
RUN sed -i 's|"--use-fake-ui-for-media-stream"|"--use-fake-ui-for-media-stream",\n            "--ignore-certificate-errors",\n            "--kiosk",\n            "--start-fullscreen",\n            "--disable-infobars"|' /defaults/jibri.conf || true

# Also copy custom-jibri.conf to multiple locations to ensure include works
COPY custom-jibri.conf /defaults/custom-jibri.conf
COPY custom-jibri.conf /etc/jitsi/jibri/custom-jibri.conf

# Finalize script for uploading recordings
COPY finalize.sh /defaults/finalize.sh
RUN chmod +x /defaults/finalize.sh

# Note: s6-overlay needs root, don't switch USER
