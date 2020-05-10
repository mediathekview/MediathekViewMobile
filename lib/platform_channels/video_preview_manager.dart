import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:logging/logging.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoPreviewManager {
  final Logger logger = new Logger('VideoPreviewManager');
  AppSharedState _appWideState;
  Map<String, bool> requestedVideoPreview = new Map();

  VideoPreviewManager(BuildContext context) {
    _appWideState = AppSharedStateContainer.of(context);
  }

  Future<Image> startPreviewGeneration(String videoId, String url) async {
    if (_appWideState.videoListState.previewImages.containsKey(videoId)) {
      return null;
    }

    if (requestedVideoPreview.containsKey(videoId)) {
      return null;
    }

    requestedVideoPreview.putIfAbsent(videoId, () {
      return true;
    });

    logger.fine("Request preview for: " + url);
    return await _createPreview(videoId, url);
  }

  Future<Image> _createImage(Uint8List pictureRaw) async {
    final Codec codec = await instantiateImageCodec(pictureRaw);
    final FrameInfo frameInfo = await codec.getNextFrame();
    int height = frameInfo.image.height;
    int width = frameInfo.image.width;

    return new Image.memory(pictureRaw,
        fit: BoxFit.cover, height: height.toDouble(), width: width.toDouble());
  }

  Future<Image> _createPreview(String videoId, String url) async {
    // TODO: only save the temp file names of the thumbnail in memory (use Image.from)
    Uint8List uint8list;
    try {
      uint8list = await VideoThumbnail.thumbnailData(
        video: url,
        //thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.PNG,
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
    logger.info("Received image for " +
        url +
        " with size: " +
        uint8list.length.toString());

    Image image = await _createImage(uint8list);
    _appWideState.addImagePreview(videoId, image);
    return image;
  }
}
