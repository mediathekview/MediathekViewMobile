class TvPlayerStatus {
  static const String PLAYING = "playing";
  static const String PAUSED = "paused";
  static const String STOPPED = "stopped";
  static const String MUTED = "muted";
  static const String UNMUTED = "unmuted";
  static const String DISCONNECTED = "disconnected";

  static Iterable<String> getValues() {
    return [PLAYING, PAUSED, STOPPED, DISCONNECTED];
  }
}
