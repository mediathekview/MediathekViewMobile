class TvStatus {
  static const String IS_SUPPORTED = "ready";
  static const String UNSUPPORTED = "not_ready";
  static const String CURRENTLY_CHECKING = "currently_checking";
  static const String NOT_YET_CHECKED = "not_yet_checked";

  static Iterable<String> getValues() {
    return [IS_SUPPORTED, UNSUPPORTED, CURRENTLY_CHECKING];
  }
}
