import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class PlaybackProgressBar extends StatelessWidget {
  final Logger logger = new Logger('PlaybackProgressBar');

  int playbackProgressInMilliseconds;
  int totalVideoLengthInSeconds;
  bool backgroundIsTransparent;

  PlaybackProgressBar(this.playbackProgressInMilliseconds,
      this.totalVideoLengthInSeconds, this.backgroundIsTransparent);

  @override
  Widget build(BuildContext context) {
    if (totalVideoLengthInSeconds == null) {
      return new Container();
    }

    return new Container(
        constraints: BoxConstraints.expand(height: 10.0),
        child: new LinearProgressIndicator(
            value: calculateProgress(
                playbackProgressInMilliseconds, totalVideoLengthInSeconds),
            valueColor: new AlwaysStoppedAnimation<Color>(Colors.red[900]),
            backgroundColor: backgroundIsTransparent
                ? Colors.transparent
                : Colors.red[100]));
  }

  double calculateProgress(
      int playbackProgressInMilliseconds, int totalVideoLengthInSeconds) {
    return 1 /
        ((totalVideoLengthInSeconds * 1000) / playbackProgressInMilliseconds);
  }
}
