import 'package:flutter_ws/manager/downloadManager.dart';

class DownloadStatus{

  String id;
  DownloadStatusText status;
  double progress;
  int totalActiveCount;
  int totalQueuedCount;
  String message;
  String filePath;
  String mimeType;


  DownloadStatus(this.id, {this.progress,
      this.totalActiveCount, this.totalQueuedCount, this.message, this.filePath, this.mimeType});
}