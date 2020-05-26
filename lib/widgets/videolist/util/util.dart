import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ws/database/video_entity.dart';
import 'package:flutter_ws/database/video_progress_entity.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/util/show_snackbar.dart';
import 'package:flutter_ws/video_player/flutter_video_player.dart';
import 'package:http/http.dart' as http;

const ERROR_MSG_NOT_AVAILABLE = "Video nicht verfügbar";
const ERROR_MSG_NO_INTERNET = "Keine Internet Verbindung";
const ERROR_MSG_FAILED_PLAYING = "Abspielen fehlgeschlagen.";
const ERROR_MSG_DOWNLOAD_FAILED = "Download fehlgeschlagen";

class Util {
  static Future<bool> playVideoPreChecks(
      BuildContext context, VideoEntity entity, Video video) async {
    if (entity == null) {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        SnackbarActions.showError(context, ERROR_MSG_NO_INTERNET);
        return false;
      }
    }

    //  video has been removed from the Mediathek already
    if (entity == null && video != null && video.url_video != null) {
      final response = await http.head(video.url_video);

      if (response.statusCode >= 300) {
        SnackbarActions.showError(context, ERROR_MSG_NOT_AVAILABLE);
        return false;
      }
    }

    if (video == null && entity == null) {
      SnackbarActions.showError(context, ERROR_MSG_FAILED_PLAYING);
      return false;
    }
    return true;
  }

  static Future playVideoHandler(
      BuildContext context,
      AppSharedState appState,
      VideoEntity entity,
      Video video,
      VideoProgressEntity videoProgressEntity) async {
    // only check for internet connection when video is not downloaded
    bool preChecksSuccessful =
        await Util.playVideoPreChecks(context, entity, video);
    if (!preChecksSuccessful) {
      return;
    }

    return Navigator.of(context).push(new MaterialPageRoute(
        builder: (BuildContext context) {
          return new FlutterVideoPlayer(
              context, appState, video, entity, videoProgressEntity);
        },
        settings: RouteSettings(name: "VideoPlayer"),
        fullscreenDialog: false));
  }
}
