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

# Chrome flags for fullscreen recording + certificate bypass
COPY custom-jibri.conf /defaults/custom-jibri.conf

# Finalize script for uploading recordings
COPY finalize.sh /defaults/finalize.sh
RUN chmod +x /defaults/finalize.sh

# Remove watermark
RUN echo '<svg xmlns="http://www.w3.org/2000/svg"/>' > /usr/share/jitsi-meet/images/watermark.svg 2>/dev/null || true

USER jibri
