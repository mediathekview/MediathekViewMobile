import 'package:flutter_downloader/flutter_downloader.dart';

class DownloadValue {
  DownloadValue(
      {this.videoId,
      this.progress = -1,
      this.status = DownloadTaskStatus.undefined});

  DownloadValue.uninitialized() : this();

  final String videoId;

  final double progress;

  final DownloadTaskStatus status;

  bool get isDownloading => status == DownloadTaskStatus.running;
  bool get isPaused => status == DownloadTaskStatus.paused;
  bool get isEnqueued => status == DownloadTaskStatus.enqueued;

  DownloadValue copyWith({
    String videoId,
    double progress,
    DownloadTaskStatus status,
    bool isDownloading,
  }) {
    return DownloadValue(
      videoId: videoId ?? this.videoId,
      progress: progress ?? this.progress,
      status: status ?? this.status,
    );
  }
}
