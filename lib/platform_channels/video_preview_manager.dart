import 'dart:async';
import 'dart:io';
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
    String thumbnailPath = _appWideState.appState.localDirectory.path +
        "/MediathekView/thumbnails/" +
        videoId;
    var file = io.File(thumbnailPath);
    if (!await file.exists()) {
      return null;
    }

    return Image.file(file, fit: BoxFit.cover);
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
    _createThumbnail(context, videoId, url).then((filepath) {
      // update each widget that waited for the preview
      videoIdToPreviewReceived[videoId].forEach((triggerReload) {
        triggerReload(filepath);
      });
      videoIdToPreviewReceived.remove(videoId);
    });
  }

  Future<Image> _createImage(Uint8List pictureRaw) async {
    final Codec codec = await instantiateImageCodec(pictureRaw);
    final FrameInfo frameInfo = await codec.getNextFrame();
    int height = frameInfo.image.height;
    int width = frameInfo.image.width;

    return new Image.memory(pictureRaw,
        fit: BoxFit.cover, height: height.toDouble(), width: width.toDouble());
  }

  Future<Image> _createPreview(
      BuildContext context, String videoId, String url) async {
    // TODO: only save the temp file names of the thumbnail in memory (use Image.from)
    Uint8List uint8list;
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
    logger.fine("Received image for " +
        url +
        " with size: " +
        uint8list.length.toString());

    Image image = await _createImage(uint8list);
    _appWideState.addImagePreview(videoId, image);
    return image;
  }

  // generate a preview under a well defined path
  // before generating a new preview, it should always be checked if there is already a thumbnail file
  Future<String> _createThumbnail(
      BuildContext context, String videoId, String url) async {
    String filepath;
    try {
      Directory directory = _appWideState.appState.localDirectory;

      String thumbnailPath =
          directory.path + "/MediathekView/thumbnails/" + videoId + ".jpeg";
      logger.info("Requesting preview for url " + url);
      logger.info("Requesting preview for thumbnail path " + thumbnailPath);
      filepath = await VideoThumbnail.thumbnailFile(
        video: url,
        // thumbnailPath: thumbnailPath,
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
    return filepath;
  }
}
