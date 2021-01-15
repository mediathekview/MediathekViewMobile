import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/util/device_information.dart';
import 'package:logging/logging.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

typedef void TriggerStateReloadOnPreviewReceived(String trigger);

class VideoPreviewManager {
  final Logger logger = new Logger('VideoPreviewManager');
  AppSharedState _appWideState;

  //Map<String, bool> requestedVideoPreview = new Map();
  // Maps a video id to a function that reloads the state of the widget that requested the preview
  // THis is needed because, although a video id is unique, there can be multiple widgets requesting previews for the same video id
  // this is the case when the user just watched the video (visible in recently viewed) and also downloads it at the same time
  // the preview should not be requested twice & when the preview is received, both widget should be updated with the preview
  Map<String, List<TriggerStateReloadOnPreviewReceived>>
      videoIdToPreviewReceived = new Map();

  var setStateNecessary;

  VideoPreviewManager(BuildContext context) {
    _appWideState = AppSharedStateContainer.of(context);
  }

  Future<Image> getImagePreview(String videoId) async {
    String thumbnailPath =
        getThumbnailPath(_appWideState.appState.localDirectory, videoId);

    var file = io.File(thumbnailPath);
    if (!await file.exists()) {
      return null;
    }

    var image = Image.file(file, fit: BoxFit.cover);
    _appWideState.addImagePreview(videoId, image);

    return image;
  }

  void startPreviewGeneration(
      BuildContext context,
      String videoId,
      String title,
      String url,
      TriggerStateReloadOnPreviewReceived triggerStateReload) async {
    if (_appWideState.videoListState.previewImages.containsKey(videoId)) {
      return null;
    }

    if (videoIdToPreviewReceived.containsKey(videoId)) {
      logger.info("Preview requested again for " + title);
      videoIdToPreviewReceived.update(videoId, (value) {
        List<TriggerStateReloadOnPreviewReceived> list =
            videoIdToPreviewReceived[videoId];
        list.add(triggerStateReload);
        return list;
      });
      return;
    }

    videoIdToPreviewReceived.putIfAbsent(videoId, () {
      List<TriggerStateReloadOnPreviewReceived> list = new List();
      list.add(triggerStateReload);
      return list;
    });

    logger.info("Request preview for: " + title);
    _createAndPersistThumbnail(context, videoId, url).then((filepath) {
      // update each widget that waited for the preview
      videoIdToPreviewReceived[videoId].forEach((triggerReload) {
        triggerReload(filepath);
      });
      videoIdToPreviewReceived.remove(videoId);
    });
  }

  Future<String> _createAndPersistThumbnail(
      BuildContext context, String videoId, String url) async {
    Uint8List uint8list;

    io.Directory directory = _appWideState.appState.localDirectory;

    String thumbnailPath = getThumbnailPath(directory, videoId);

    if (await io.File(thumbnailPath).exists()) {
      return thumbnailPath;
    }

    try {
      uint8list = await VideoThumbnail.thumbnailData(
        video: url,
        //thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        quality: DeviceInformation.isTablet(context) ? 5 : 3,
      );
    } on PlatformException catch (e) {
      logger.severe("Create preview failed. Reason " + e.toString());
      return null;
    } on MissingPluginException catch (e) {
      logger.severe("Creating preview failed faile for: " +
          url +
          ". Missing Plugin: " +
          e.toString());
      return null;
    }

    if (uint8list == null) {
      logger.severe("Create preview failed. No preview data returned");
      return null;
    }

    logger.info("Received image for " +
        url +
        " with size: " +
        uint8list.length.toString());

    io.File(thumbnailPath)
        .writeAsBytes(uint8list)
        .catchError((error) => logger
            .warning("Failed to persist preview file " + error.toString()))
        .then((file) => logger.info("Wrote preview file to " + file.path));

    Image image = await _createImage(uint8list);
    _appWideState.addImagePreview(videoId, image);
    return thumbnailPath;
  }

  String getThumbnailPath(io.Directory directory, String videoId) {
    String thumbnailPath = directory.path +
        "/MediathekView/thumbnails/" +
        sanitizeVideoId(videoId) +
        ".jpeg";
    return thumbnailPath;
  }

  String sanitizeVideoId(String videoId) {
    return videoId.replaceAll('/', '');
  }

  Future<Image> _createImage(Uint8List pictureRaw) async {
    final Codec codec = await instantiateImageCodec(pictureRaw);
    final FrameInfo frameInfo = await codec.getNextFrame();
    int height = frameInfo.image.height;
    int width = frameInfo.image.width;

    return new Image.memory(pictureRaw,
        fit: BoxFit.cover, height: height.toDouble(), width: width.toDouble());
  }
}
