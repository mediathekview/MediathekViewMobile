import 'package:flutter/material.dart';
import 'package:flutter_ws/util/text_styles.dart';
import 'package:flutter_ws/widgets/videolist/circular_progress_with_text.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

class StatusBar extends StatelessWidget {
  final Logger logger = new Logger('VideoWidget');
  final bool videoListIsEmpty;
  final bool websocketInitError;
  final bool firstAppStartup;
  final int lastAmountOfVideosRetrieved;

  StatusBar(
      {Key key,
      @required this.websocketInitError,
      @required this.firstAppStartup,
      @required this.videoListIsEmpty,
      @required this.lastAmountOfVideosRetrieved})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    logger.fine("Rendering Status bar. videoListIsEmpty: " +
        videoListIsEmpty.toString() +
        " websocketInitError: " +
        websocketInitError.toString() +
        " firstAppStartup: " +
        firstAppStartup.toString() +
        " lastAmountOfVideosRetrieved: " +
        lastAmountOfVideosRetrieved.toString());

    if (websocketInitError) {
      return new CircularProgressWithText(
        new Text("Keine Verbindung", style: connectionLostTextStyle),
        new Color(0xffffbf00),
        new Color(0xffffbf00),
        height: 30.0,
      );
    }

    return new Container();
  }
}
