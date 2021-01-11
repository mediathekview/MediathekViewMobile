import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_ws/database/video_entity.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/platform_channels/download_manager_flutter.dart';
import 'package:flutter_ws/section/download_section.dart';
import 'package:flutter_ws/util/cross_axis_count.dart';
import 'package:flutter_ws/util/show_snackbar.dart';
import 'package:flutter_ws/widgets/downloadSection/video_list_item_builder.dart';
import 'package:flutter_ws/widgets/videolist/download/DownloadController.dart';
import 'package:flutter_ws/widgets/videolist/download/DownloadValue.dart';
import 'package:logging/logging.dart';

class CurrentDownloads extends StatefulWidget {
  final Logger logger = new Logger('CurrentDownloads');
  final AppSharedState appWideState;
  var setStateNecessary;
  int downloadManagerIdentifier = 1;

  CurrentDownloads(this.appWideState, this.setStateNecessary);

  @override
  _CurrentDownloadsState createState() => _CurrentDownloadsState();
}

class _CurrentDownloadsState extends State<CurrentDownloads> {
  List<Video> currentDownloads = new List();
  Map<DownloadController, Function> downloadControllerToListener =
      new Map<DownloadController, Function>();
  BuildContext context;

  @override
  void dispose() {
    downloadControllerToListener.forEach((controller, listener) {
      controller.removeListener(listener);
      controller.dispose();
    });
    super.dispose();
  }

  @override
  void initState() {
    updateCurrentDownloads().then((List<Video> videos) {
      videos.forEach((video) {
        subscribeToDownloadUpdates(video.id, video.title,
            widget.appWideState.appState.downloadManager);
      });

      if (videos.isNotEmpty && mounted) {
        widget.logger.fine("There are current downloads, setting state");
        setState(() {});
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    if (currentDownloads.isEmpty) {
      return new SliverToBoxAdapter(child: new Container());
    }

    var videoListItemBuilder = new VideoListItemBuilder.name(
        currentDownloads.toList(), true, true, true,
        onRemoveVideo: cancelCurrentDownload);

    int crossAxisCount = CrossAxisCount.getCrossAxisCount(context);

    SliverGrid downloadList = SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 16 / 9,
        mainAxisSpacing: 1.0,
        crossAxisSpacing: 5.0,
      ),
      delegate: SliverChildBuilderDelegate(videoListItemBuilder.itemBuilder,
          childCount: currentDownloads.length),
    );

    return downloadList;
  }

  void subscribeToDownloadUpdates(
      String videoId, String videoTitle, DownloadManager downloadManager) {
    DownloadController downloadController =
        new DownloadController(videoId, videoTitle, downloadManager);

    var listener = () async {
      DownloadValue value = downloadController.value;

      widget.logger.info("Current download status for video: " +
          videoId +
          value.status.toString());

      if (value.status == DownloadTaskStatus.complete ||
          value.status == DownloadTaskStatus.failed ||
          value.status == DownloadTaskStatus.canceled) {
        updateCurrentDownloads();
      }
    };

    downloadController.addListener(listener);
    downloadController.initialize();
    downloadControllerToListener[downloadController] = listener;
  }

  Future<List<Video>> updateCurrentDownloads() async {
    Set<VideoEntity> downloads = await widget
        .appWideState.appState.downloadManager
        .getCurrentDownloads();

    List<Video> currentDownloads = new List();
    downloads.forEach((entity) {
      var video = Video.fromMap(entity.toMap());
      currentDownloads.add(video);
      widget.logger
          .info("Current download: " + video.id + ". Title: " + video.title);
    });

    widget.setStateNecessary(currentDownloads);
    this.currentDownloads = currentDownloads;

    return currentDownloads;
  }

  //Cancels active download (remove from task schema), removes the file from local storage & deletes the entry in VideoEntity schema
  void cancelCurrentDownload(BuildContext context, String id) {
    widget.logger.info("Canceling download for: " + id);
    widget.appWideState.appState.downloadManager
        .deleteVideo(id)
        .then((bool deletedSuccessfully) {
      if (deletedSuccessfully) {
        currentDownloads.removeWhere((video) {
          return video.id == id;
        });
        if (mounted) {
          SnackbarActions.showSuccess(this.context, "Löschen erfolgreich");
        }
        widget.setStateNecessary(currentDownloads);
        return;
      }
      SnackbarActions.showErrorWithTryAgain(
          this.context,
          ERROR_MSG,
          TRY_AGAIN_MSG,
          widget.appWideState.appState.downloadManager.deleteVideo,
          id);
    });
  }
}
