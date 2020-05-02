import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:video_player/video_player.dart';

import 'TVPlayerController.dart';
import 'custom_chewie_player.dart';

class CustomCupertinoVideoProgressBar extends StatefulWidget {
  CustomCupertinoVideoProgressBar(
    this.flutterPlayerController,
    this.tvPlayerController, {
    ChewieProgressColors colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
  }) : colors = colors ?? ChewieProgressColors();

  final VideoPlayerController flutterPlayerController;
  final TvPlayerController tvPlayerController;
  final ChewieProgressColors colors;
  final Function() onDragStart;
  final Function() onDragEnd;
  final Function() onDragUpdate;

  @override
  _VideoProgressBarState createState() {
    return _VideoProgressBarState();
  }
}

class _VideoProgressBarState extends State<CustomCupertinoVideoProgressBar> {
  final Logger logger = new Logger('VideoProgressBar');
  CustomChewieController chewieController;
  // used to determine which value to consider for the progress bar painting
  // use the flutter player position when scrubbing while being connected to the TV
  bool isScrubbing = false;

  _VideoProgressBarState() {
    listener = () {
      setState(() {});
    };
  }

  VoidCallback listener;
  bool _controllerWasPlaying = false;

  VideoPlayerController get flutterPlayerController =>
      widget.flutterPlayerController;

  TvPlayerController get tvPlayerController => widget.tvPlayerController;

  @override
  void initState() {
    super.initState();
    // react on value changes (e.g position) on both the flutter as well as the Tv player
    flutterPlayerController.addListener(listener);
    tvPlayerController.addListener(listener);
  }

  @override
  void deactivate() {
    flutterPlayerController.removeListener(listener);
    tvPlayerController.removeListener(listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    chewieController = CustomChewieController.of(context);

    void seekToRelativePosition(Offset globalPosition) {
      final box = context.findRenderObject() as RenderBox;
      final Offset tapPos = box.globalToLocal(globalPosition);
      final double relative = tapPos.dx / box.size.width;
      // TV controller does not store the duration itself
      final Duration position =
          flutterPlayerController.value.duration * relative;

      flutterPlayerController.seekTo(position);
    }

    _ProgressBarPainter painter;
    if (tvPlayerController.value.playbackOnTvStarted && !isScrubbing) {
      painter = _ProgressBarPainter(
        flutterPlayerController.value.initialized,
        tvPlayerController.value.position,
        new List<DurationRange>(),
        flutterPlayerController.value.duration,
        widget.colors,
      );
    } else {
      painter = _ProgressBarPainter(
        flutterPlayerController.value.initialized,
        flutterPlayerController.value.position,
        flutterPlayerController.value.buffered,
        flutterPlayerController.value.duration,
        widget.colors,
      );
    }

    return GestureDetector(
      child: Center(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Colors.transparent,
          child: CustomPaint(
            painter: painter,
          ),
        ),
      ),
      onHorizontalDragStart: (DragStartDetails details) {
        logger.info("On Drag start");
        isScrubbing = true;

        if (!flutterPlayerController.value.initialized) {
          return;
        }
        _controllerWasPlaying = tvPlayerController.value.isPlaying ||
            flutterPlayerController.value.isPlaying;

        // pause the player when scrubbing
        if (tvPlayerController.value.isPlaying) {
          tvPlayerController.pause();
        } else if (flutterPlayerController.value.isPlaying) {
          flutterPlayerController.pause();
        }

        if (widget.onDragStart != null) {
          widget.onDragStart();
        }
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (!flutterPlayerController.value.initialized) {
          return;
        }
        seekToRelativePosition(details.globalPosition);

        if (widget.onDragUpdate != null) {
          widget.onDragUpdate();
        }
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        isScrubbing = false;

        logger.info("On Drag end");
        if (_controllerWasPlaying) {
          logger.info("On Drag end - was playing");
          if (tvPlayerController.value.playbackOnTvStarted) {
            logger.info("On Drag end - play tv");
            tvPlayerController.resume();
          } else if (!flutterPlayerController.value.isPlaying) {
            logger.info("On Drag end - play flutter");
            flutterPlayerController.play();
          }
        }

        if (tvPlayerController.value.playbackOnTvStarted) {
          tvPlayerController.seekTo(flutterPlayerController.value.position);
        }

        if (widget.onDragEnd != null) {
          widget.onDragEnd();
        }
      },
      onTapDown: (TapDownDetails details) {
        if (!flutterPlayerController.value.initialized) {
          return;
        }
        seekToRelativePosition(details.globalPosition);
      },
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter(this.isFlutterVideoPlayerInitialized, this.position,
      this.buffered, this.totalDuration, this.colors);

  ChewieProgressColors colors;
  bool isFlutterVideoPlayerInitialized;
  Duration position;
  Duration totalDuration;
  List<DurationRange> buffered;

  @override
  bool shouldRepaint(CustomPainter painter) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final barHeight = 6.0;
    final handleHeight = 11.0;
    final baseOffset = size.height / 2 - barHeight / 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, baseOffset),
          Offset(size.width, baseOffset + barHeight),
        ),
        Radius.circular(4.0),
      ),
      colors.backgroundPaint,
    );
    if (!isFlutterVideoPlayerInitialized) {
      return;
    }
    final double playedPartPercent =
        position.inMilliseconds / totalDuration.inMilliseconds;
    final double playedPart =
        playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
    for (DurationRange range in buffered) {
      final double start = range.startFraction(totalDuration) * size.width;
      final double end = range.endFraction(totalDuration) * size.width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            Offset(start, baseOffset),
            Offset(end, baseOffset + barHeight),
          ),
          Radius.circular(4.0),
        ),
        colors.bufferedPaint,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, baseOffset),
          Offset(playedPart, baseOffset + barHeight),
        ),
        Radius.circular(4.0),
      ),
      colors.playedPaint,
    );

    final shadowPath = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(playedPart, baseOffset + barHeight / 2),
          radius: handleHeight));

    canvas.drawShadow(shadowPath, Colors.black, 0.2, false);
    canvas.drawCircle(
      Offset(playedPart, baseOffset + barHeight / 2),
      handleHeight,
      colors.handlePaint,
    );
  }
}
