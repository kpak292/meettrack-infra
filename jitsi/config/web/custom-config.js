config.channelLastN = 6;
config.resolution = 480;
config.constraints = { video: { height: { ideal: 480, max: 720, min: 240 } } };
config.enableLayerSuspension = true;
config.disableSimulcast = false;
config.p2p = { enabled: true, useStunTurn: true };

// NO pre-join, NO name prompt
config.prejoinConfig = { enabled: false };
config.prejoinPageEnabled = false;
config.requireDisplayName = false;
config.enableUserRolesBasedOnToken = true;

// UI
config.startWithAudioMuted = false;
config.startWithVideoMuted = false;
config.disableDeepLinking = true;
config.defaultLanguage = "ru";
config.hideConferenceSubject = true;
config.disableInviteFunctions = true;
config.toolbarButtons = [
    "camera", "chat", "desktop", "fullscreen",
    "hangup", "microphone", "participants-pane", "raisehand",
    "settings", "tileview", "toggle-camera"
];

// Hide Jibri recorder from participant list
config.hiddenDomain = "hidden.meet.jitsi";
config.autoRecord = true;
config.fileRecordingsServiceEnabled = true;

// === MeetTrack override 2026-06-05: отключить авто-выключение камеры/микрофона ===
// Жалоба пользователей: у 6-го+ участника камера/микрофон сами выключаются (startVideoMuted=5).
config.startAudioMuted = 1000;
config.startVideoMuted = 1000;
config.startWithAudioMuted = false;
config.startWithVideoMuted = false;

// === MeetTrack 2026-06-07: отключить AV1 (баг JVB Av1DDAdaptiveSourceProjectionContext -> NPE) ===
config.videoQuality = config.videoQuality || {};
config.videoQuality.codecPreferenceOrder = ['VP9', 'VP8', 'H264'];
config.videoQuality.mobileCodecPreferenceOrder = ['VP8', 'VP9', 'H264'];
config.p2p = config.p2p || {};
config.p2p.codecPreferenceOrder = ['VP9', 'VP8', 'H264'];
config.enableAv1Support = false;
