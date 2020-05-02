import 'package:flutter_ws/enum/tv_status.dart';

class TvVideoPlayerValue {
  TvVideoPlayerValue({
    this.position = const Duration(),
    this.isPlaying = false,
    this.playbackOnTvStarted = false,
    this.isStopped = false,
    this.isDisconnected = false,
    this.volume = 1.0,
    this.errorDescription,
    this.tvStatus = TvStatus.NOT_YET_CHECKED,
    this.availableTvs = const [],
  });

  TvVideoPlayerValue.uninitialized() : this();

  TvVideoPlayerValue.erroneous(String errorDescription)
      : this(errorDescription: errorDescription);

  /// The current playback position.
  final Duration position;

  /// True if the video is playing. False if it's paused.
  final bool isPlaying;

  // isStopped means that the TV Player (DefaultMediaPlayer) is stopped (still connected to TV)
  final bool isStopped;

  // isDisconnected means that the TV Player (DefaultMediaPlayer) is not running on the TV
  final bool isDisconnected;

  /// True if the video has been successfully initially casted to the TV, false if not.
  /// once video has been started on the TV it can be paused, resumed ...
  final bool playbackOnTvStarted;

  final String tvStatus;

  /// The current volume of the playback.
  final double volume;

  /// A description of the error if present.
  ///
  /// If [hasError] is false this is [null].
  final String errorDescription;

  // List of discovered TVs
  final List<String> availableTvs;

  /// Indicates whether or not the video is in an error state. If this is true
  /// [errorDescription] should have information about the problem.
  bool get hasError => errorDescription != null;

  bool get isCurrentlyCheckingTV => tvStatus == TvStatus.CURRENTLY_CHECKING;

  bool get isTvSupported => tvStatus == TvStatus.IS_SUPPORTED;

  bool get isTvUnsupported => tvStatus == TvStatus.UNSUPPORTED;

  bool get hasAlreadyCheckedTv => tvStatus != TvStatus.NOT_YET_CHECKED;

  /// Returns a new instance that has the same values as this current instance,
  /// except for any overrides passed in as arguments to [copyWidth].
  TvVideoPlayerValue copyWith({
    Duration duration,
    Duration position,
    bool playbackOnTvStarted,
    bool isPlaying,
    bool isStopped,
    bool isDisconnected,
    String tvStatus,
    double volume,
    String errorDescription,
    List<String> availableTvs,
  }) {
    return TvVideoPlayerValue(
      position: position ?? this.position,
      playbackOnTvStarted: playbackOnTvStarted ?? this.playbackOnTvStarted,
      isPlaying: isPlaying ?? this.isPlaying,
      isStopped: isStopped ?? this.isStopped,
      isDisconnected: isDisconnected ?? this.isDisconnected,
      tvStatus: tvStatus ?? this.tvStatus,
      volume: volume ?? this.volume,
      errorDescription: errorDescription ?? this.errorDescription,
      availableTvs: availableTvs ?? this.availableTvs,
    );
  }
}
