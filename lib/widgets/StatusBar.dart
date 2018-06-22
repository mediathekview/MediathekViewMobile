import 'package:flutter/material.dart';
import 'package:flutter_ws/util/textStyles.dart';
import 'package:flutter_ws/widgets/reuse/circularProgressWithText.dart';
import 'package:meta/meta.dart';

class StatusBar extends StatelessWidget {
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
    print("Rendering Status bar. videoListIsEmpty: " +
        videoListIsEmpty.toString() +
        " websocketInitError: " +
        websocketInitError.toString() +
        " firstAppStartup: " +
        firstAppStartup.toString() +
        " lastAmountOfVideosRetrieved: " +
        lastAmountOfVideosRetrieved.toString());

//    if (videoListIsEmpty && firstAppStartup) {
//      print("Waiting for first results: returning Progress Indicator.");
//      return new CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(new Color(0xffffbf00)),strokeWidth: 5.0,backgroundColor: Colors.white);
//    }

    if (websocketInitError) {
      print("Websocket Channel lost server connection");
      return new CircularProgressWithText(
          new Text("Keine Verbindung", style: connectionLostTextStyle), new Color(0xffffbf00), Colors.white);
    }

    //TODO verschönern & ein icon zurückgeben- komisch, was suchst du für Sachen?
//    if (lastAmountOfVideosRetrieved == 0 && videoListIsEmpty) {
//      print("Could not find fitting videos");
//      return new Text('Oops - keine passenden Videos gefunden :(',
//          style: connectionLostTextStyle);
//    }

    return new Container();
  }
}
