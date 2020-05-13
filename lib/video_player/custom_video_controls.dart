import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/util/show_snackbar.dart';
import 'package:flutter_ws/video_player/custom_chewie_player.dart';
import 'package:logging/logging.dart';
import 'package:open_iconic_flutter/open_iconic_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

import 'TVPlayerController.dart';
import 'TvVideoPlayerValue.dart';
import 'available_tvs_dialog.dart';
import 'custom_video_progress_bar.dart';

class CustomVideoControls extends StatefulWidget {
  const CustomVideoControls({
    @required this.backgroundColor,
    @required this.iconColor,
  });

  final Color backgroundColor;
  final Color iconColor;

  @override
  State<StatefulWidget> createState() {
    return _CustomVideoControlsState();
  }
}

class _CustomVideoControlsState extends State<CustomVideoControls> {
  AppSharedState _appWideState;

  bool isScrubbing = false;
  bool listeningToPlayerPosition = false;
  bool isWaitingUntilTVPlaybackStarts = false;

  // needed to be able to show a loading spinner if the the video does not
  // progress over a certain amount of time
  DateTime lastVideoPlayerPositionUpdateTime = new DateTime.now();
  var LAGGING_THRESHOLD_IN_MILLISECONDS = 100;
  bool isLagging = false;

  // Samsung TV cast
  StreamSubscription<dynamic> tvConnectionSubscription;
  StreamSubscription<dynamic> tvPlayerSubscription;
  StreamSubscription<dynamic> tvPlaybackPositionSubscription;
  List<String> discoveredTvs = new List();

  final Logger logger = new Logger('CustomVideoControls');
  VideoPlayerValue _latestFlutterPlayerValue;
  TvVideoPlayerValue _latestTvPlayerValue;

  // have Tv volume and flutter volume in sync
  double _latestPlayerVolume;
  bool _hideStuff = true;
  Timer _hideTimer;
  final marginSize = 5.0;
  Timer _expandCollapseTimer;
  Timer _initTimer;

  VideoPlayerController flutterPlayerController;
  CustomChewieController chewieController;
  TvPlayerController tvPlayerController;

  @override
  void initState() {
    super.initState();
  }

  Future<Null> _initialize() async {
    logger.info("custom_video_controls - initialize called");
    flutterPlayerController.addListener(_updateFlutterPlayerState);
    _updateFlutterPlayerState();

    tvPlayerController.addListener(_updateTvPlayerState);
    _updateTvPlayerState();

    // show controls for a short time and then hide
    _cancelAndRestartTimer();
  }

  void _updateFlutterPlayerState() {
    if (_latestFlutterPlayerValue != null &&
        _latestFlutterPlayerValue.position ==
            flutterPlayerController.value.position &&
        flutterPlayerController.value.isPlaying) {
      DateTime now = new DateTime.now();
      var lag =
          now.difference(lastVideoPlayerPositionUpdateTime).inMilliseconds;
      logger.info("Same position detected with lag: " + lag.toString());
      if (lag > LAGGING_THRESHOLD_IN_MILLISECONDS) {
        isLagging = true;
        logger.info("Detected lag of > 100 ms - showing loading indicator!");
        if (mounted) {
          setState(() {});
        }
        return;
      }
    } else {
      isLagging = false;
      lastVideoPlayerPositionUpdateTime = DateTime.now();
    }

    _latestFlutterPlayerValue = flutterPlayerController.value;

    // update position
    final int position = _latestFlutterPlayerValue.position.inMilliseconds;
    logger.info("video playback position:" + position.toString());

    if (mounted) {
      setState(() {});
    }

    // if playing on TV, the position is already inserted into the database
    // avoid inserting the current position twice
    if (tvPlayerController.value.playbackOnTvStarted) {
      return;
    }

    if (_appWideState != null) {
      _appWideState.appState.databaseManager
          .updatePlaybackPosition(chewieController.video, position);
    }
  }

  void _updateTvPlayerState() {
    setState(() {
      if (_latestTvPlayerValue != null &&
          _latestTvPlayerValue.isCurrentlyCheckingTV &&
          tvPlayerController.value.isTvSupported) {
        logger.info("VERBUNDEN");

        flutterPlayerController.pause();
        isWaitingUntilTVPlaybackStarts = true;
        tvPlayerController.startPlayingOnTV(
            startingPosition: flutterPlayerController.value.position);
      }

      // isPlaying is only true if the video has been successfully casted / isPlaying on the TV
      if (_appWideState != null &&
          _latestTvPlayerValue != null &&
          !_appWideState.appState.isCurrentlyPlayingOnTV &&
          chewieController.tvPlayerController.value.isPlaying) {
        _appWideState.appState.isCurrentlyPlayingOnTV = true;
        _appWideState.appState.tvCurrentlyPlayingVideo =
            tvPlayerController.video;
        SnackbarActions.showSuccess(context, "Verbunden");
        // show controls for a short time and then hide
        _cancelAndRestartTimer();
      }

      _latestTvPlayerValue = chewieController.tvPlayerController.value;

      // add available tvs to global state - needed when navigation out of the player screen
      if (_appWideState != null) {
        _appWideState.appState.availableTvs = _latestTvPlayerValue.availableTvs;
      }

      // case: playback on TV manually disconnected. Start playing locally again
      if (tvPlayerController.value.isDisconnected && _appWideState != null) {
        logger.info("PLAY LOCALLY AGAIN");
        _appWideState.appState.isCurrentlyPlayingOnTV = false;
        tvPlayerController.value =
            tvPlayerController.value.copyWith(isDisconnected: false);
        flutterPlayerController
            .seekTo(_latestTvPlayerValue.position)
            .then((value) => flutterPlayerController.play());
        // show controls for a short time and then hide
        _cancelAndRestartTimer();
      }

      if (chewieController.tvPlayerController.value.isTvUnsupported &&
          chewieController.tvPlayerController.value.errorDescription != null) {
        _appWideState.appState.isCurrentlyPlayingOnTV = false;
        SnackbarActions.showError(context, "Verbindung nicht möglich.");
      }

      if (_latestTvPlayerValue.isCurrentlyCheckingTV) {
        SnackbarActions.showInfo(context, "Verbinde...",
            duration: new Duration(seconds: 1));
      }

      if (_latestTvPlayerValue.playbackOnTvStarted &&
          _latestTvPlayerValue.isPlaying) {
        isWaitingUntilTVPlaybackStarts = false;
        flutterPlayerController.pause();
        // also set the TV player positions to the flutter player to be able to continue playing
        // with the same position locally when disconnecting from TV
        _latestFlutterPlayerValue = _latestFlutterPlayerValue.copyWith(
            position: _latestTvPlayerValue.position);
      }
    });
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    logger.info("custom_video_controls - dispose called");
    flutterPlayerController.removeListener(_updateFlutterPlayerState);
    tvPlayerController.removeListener(_updateTvPlayerState);
    _hideTimer?.cancel();
    _expandCollapseTimer?.cancel();
    _initTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    logger.info("didChangeDependencies called");
    final _oldController = chewieController;
    chewieController = CustomChewieController.of(context);
    flutterPlayerController = chewieController.videoPlayerController;
    tvPlayerController = chewieController.tvPlayerController;

    // only initialize again / attach listeners - if chewie controller changed (contains videoPLayerController & tvPlayerController)
    if (_oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    _appWideState = AppSharedStateContainer.of(context);
    chewieController = CustomChewieController.of(context);

    if (_latestFlutterPlayerValue != null &&
        _latestFlutterPlayerValue.hasError) {
      return chewieController.errorBuilder != null
          ? chewieController.errorBuilder(
              context,
              chewieController.videoPlayerController.value.errorDescription,
            )
          : Center(
              child: Icon(
                OpenIconicIcons.ban,
                color: Colors.white,
                size: 42,
              ),
            );
    }

    // set players from CustomChewieController
    chewieController = CustomChewieController.of(context);
    flutterPlayerController = chewieController.videoPlayerController;
    tvPlayerController = chewieController.tvPlayerController;

    final backgroundColor = widget.backgroundColor;
    final iconColor = widget.iconColor;
    final orientation = MediaQuery.of(context).orientation;
    final barHeight = orientation == Orientation.portrait ? 30.0 : 47.0;
    final buttonPadding = orientation == Orientation.portrait ? 16.0 : 24.0;

    final isLoading = isScrubbing ||
        flutterPlayerController == null ||
        flutterPlayerController.value == null ||
        !flutterPlayerController.value.initialized ||
        flutterPlayerController.value.isBuffering ||
        tvPlayerController.value.isCurrentlyCheckingTV ||
        isWaitingUntilTVPlaybackStarts ||
        isLagging;

    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();
      },
      child: AbsorbPointer(
        absorbing: _hideStuff,
        child: Column(
          children: <Widget>[
            _buildTopBar(backgroundColor, iconColor, barHeight, buttonPadding),
            _buildHitArea(isLoading),
            _buildBottomBar(backgroundColor, iconColor, barHeight),
          ],
        ),
      ),
    );
  }

  AnimatedOpacity _buildBottomBar(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
  ) {
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.bottomCenter,
        margin: EdgeInsets.all(marginSize),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: 10.0,
              sigmaY: 10.0,
            ),
            child: Container(
              height: barHeight,
              color: backgroundColor,
              child: chewieController.isLive
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        _buildLive(iconColor),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        _buildPosition(iconColor),
                        _buildProgressBar(),
                        _buildRemaining(iconColor)
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  AnimatedOpacity _buildPlayerCenterControls(bool showLoadingIndicator) {
    var skipBack = _buildSkipBack(60.0);
    var playPause = _buildPlayPause(showLoadingIndicator, 60.0);
    var skipForward = _buildSkipForward(60.0);

    Row playerControlsRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[skipBack, playPause, skipForward],
    );

    return AnimatedOpacity(
      opacity: (isWaitingUntilTVPlaybackStarts || showLoadingIndicator)
          ? 1.0
          : _hideStuff ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
      child: playerControlsRow,
    );
  }

  GestureDetector _buildPlayPause(bool showLoadingIndicator, double height) {
    Widget button;
    if (showLoadingIndicator) {
      button = new CircularProgressIndicator(
        valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
        strokeWidth: 3.0,
      );
    } else {
      button = Icon(
        (_latestFlutterPlayerValue != null &&
                    _latestFlutterPlayerValue.isPlaying ||
                tvPlayerController.value.isPlaying)
            ? OpenIconicIcons.mediaPause
            : OpenIconicIcons.mediaPlay,
        color: Colors.white,
        size: height,
      );
    }

    return GestureDetector(
      onTap: () {
        _playPause();
      },
      child: new Container(
        alignment: Alignment.center,
        child: button,
      ),
    );
  }

  Widget _buildLive(Color iconColor) {
    return Padding(
      padding: EdgeInsets.only(right: 12.0),
      child: Text(
        'LIVE',
        style: TextStyle(color: iconColor, fontSize: 12.0),
      ),
    );
  }

  AnimatedOpacity _buildExitButton(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10.0),
          child: Container(
            height: barHeight,
            padding: EdgeInsets.only(
              left: buttonPadding,
              right: buttonPadding,
            ),
            color: backgroundColor,
            child: Center(
              child: IconButton(
                icon: new Icon(Icons.clear),
                color: iconColor,
                iconSize: 20.0,
                onPressed: () {
                  flutterPlayerController.pause();
                  flutterPlayerController
                      .removeListener(_updateFlutterPlayerState);
                  tvPlayerController.removeListener(_updateTvPlayerState);

                  //chewieController.toggleFullScreen();
                  Navigator.pop(context);
                  Wakelock.disable();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Expanded _buildHitArea(bool showLoadingIndicator) {
    Container backGroundContainer = Container(
      color: Colors.transparent,
      child: _buildPlayerCenterControls(showLoadingIndicator),
    );
    // set static picture as background
    if (tvPlayerController.value.playbackOnTvStarted) {
      backGroundContainer = new Container(
        child: new ClipRect(
          child: new BackdropFilter(
            filter: new ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: new Padding(
              padding: const EdgeInsets.only(left: 30.0, right: 10.0, top: 10),
              child: new Container(
                decoration: new BoxDecoration(
                  borderRadius: new BorderRadius.only(
                      topLeft: const Radius.circular(40.0),
                      bottomLeft: const Radius.circular(40.0),
                      bottomRight: const Radius.circular(40.0),
                      topRight: const Radius.circular(40.0)),
                  color: Colors.grey.withOpacity(0.4),
                ),
                child: new Padding(
                  padding: const EdgeInsets.only(
                      left: 30.0, right: 30.0, top: 10.0, bottom: 20.0),
                  child: new SingleChildScrollView(
                    child: new Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        new Container(
                          child: new Image(
                            image: new AssetImage(
                                "assets/launcher/ic_launcher.png"),
                          ),
                        ),
                        new Text(
                          "Video wird auf dem TV abgespielt.",
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontSize: 20.0),
                        ),
                        _buildPlayerCenterControls(showLoadingIndicator),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    GestureTapCallback gestureTapCallback;
    if (_latestFlutterPlayerValue != null &&
            _latestFlutterPlayerValue.isPlaying ||
        _latestTvPlayerValue.isPlaying) {
      if (_hideStuff) {
        gestureTapCallback = _cancelAndRestartTimer;
      } else {
        gestureTapCallback = () {
          setState(() {
            _hideStuff = true;
          });
        };
      }
    } else {
      // keep showing controls when player is paused
      gestureTapCallback = () {
        _hideTimer?.cancel();

        setState(() {
          _hideStuff = false;
        });
      };
    }

    return Expanded(
      child: GestureDetector(
        onTap: gestureTapCallback,
        child: backGroundContainer,
      ),
    );
  }

  GestureDetector _buildMuteButton(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();
        if (_latestFlutterPlayerValue.volume == 0) {
          flutterPlayerController.setVolume(_latestPlayerVolume ?? 0.5);
          if (_latestTvPlayerValue.playbackOnTvStarted) {
            tvPlayerController.unmute(_latestTvPlayerValue.volume ?? 0.5);
          }
          return;
        }

        _latestPlayerVolume = flutterPlayerController.value.volume;
        flutterPlayerController.setVolume(0);
        if (_latestTvPlayerValue.playbackOnTvStarted) {
          tvPlayerController.mute();
        }
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10.0),
            child: Container(
              color: backgroundColor,
              child: Container(
                height: barHeight,
                padding: EdgeInsets.only(
                  left: buttonPadding,
                  right: buttonPadding,
                ),
                child: Icon(
                  (_latestFlutterPlayerValue != null &&
                          _latestFlutterPlayerValue.volume > 0)
                      ? Icons.volume_up
                      : Icons.volume_off,
                  color: iconColor,
                  size: 16.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildSamsungScreenCast(
    VideoPlayerController controller,
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    String tvCastIcon;

    if (_latestTvPlayerValue != null &&
        _latestTvPlayerValue.isCurrentlyCheckingTV) {
      tvCastIcon = 'assets/cast/ic_cast0_white.png';
    } else if (_latestTvPlayerValue != null &&
        _latestTvPlayerValue.playbackOnTvStarted) {
      tvCastIcon = 'assets/cast/ic_cast_connected_white.png';
      iconColor = Colors.red;
    } else {
      tvCastIcon = 'assets/cast/ic_cast_white.png';
    }

    return GestureDetector(
      onTap: () {
        flutterPlayerController.pause();
        showDialog(
            context: context,
            builder: (ctxt) => new AvailableTVsDialog(tvPlayerController));
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10.0),
            child: Container(
              color: backgroundColor,
              child: Container(
                  height: barHeight,
                  padding: EdgeInsets.only(
                    left: buttonPadding,
                    right: buttonPadding,
                  ),
                  child: new Image.asset(tvCastIcon,
                      width: 16.0, height: 16.0, color: iconColor)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPosition(Color iconColor) {
    final position = _latestFlutterPlayerValue != null
        ? _latestFlutterPlayerValue.position
        : Duration(seconds: 0);

    return Padding(
      padding: EdgeInsets.only(right: 12.0),
      child: Text(
        formatDuration(position),
        style: TextStyle(
          color: iconColor,
          fontSize: 12.0,
        ),
      ),
    );
  }

  Widget _buildRemaining(Color iconColor) {
    final position = _latestFlutterPlayerValue != null &&
            _latestFlutterPlayerValue.duration != null
        ? _latestFlutterPlayerValue.duration -
            _latestFlutterPlayerValue.position
        : Duration(seconds: 0);

    return Padding(
      padding: EdgeInsets.only(right: 12.0),
      child: Text(
        '-${formatDuration(position)}',
        style: TextStyle(color: iconColor, fontSize: 12.0),
      ),
    );
  }

  GestureDetector _buildSkipBack(double height) {
    return GestureDetector(
      onTap: _skipBack,
      child: Container(
        child: Icon(
          OpenIconicIcons.mediaSkipBackward,
          color: Colors.white,
          size: height,
        ),
      ),
    );
  }

  GestureDetector _buildSkipForward(double height) {
    return GestureDetector(
      onTap: _skipForward,
      child: Container(
        height: height,
        color: Colors.transparent,
        child: Icon(
          OpenIconicIcons.mediaSkipForward,
          color: Colors.white,
          size: height,
        ),
      ),
    );
  }

  Widget _buildTopBar(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    Widget topBar = Container(
      height: barHeight,
      margin: EdgeInsets.only(
        top: marginSize,
        right: marginSize,
        left: marginSize,
      ),
      child: Row(
        children: <Widget>[
          chewieController.allowFullScreen
              ? _buildExitButton(
                  backgroundColor, iconColor, barHeight, buttonPadding)
              : Container(),
          Expanded(child: Container()),
          chewieController.allowMuting
              ? _buildMuteButton(
                  backgroundColor, iconColor, barHeight, buttonPadding)
              : Container(),
          _buildSamsungScreenCast(flutterPlayerController, backgroundColor,
              iconColor, barHeight, buttonPadding)
        ],
      ),
    );
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      // stay clear of the top bar
      return new SafeArea(child: topBar);
    }
    return topBar;
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: 12.0),
        child: CustomCupertinoVideoProgressBar(
          flutterPlayerController,
          tvPlayerController,
          onDragStart: () {
            _hideTimer?.cancel();
            isScrubbing = true;
          },
          onDragUpdate: () {},
          onDragEnd: () {
            _startHideTimer();
            isScrubbing = false;
          },
          colors: chewieController.cupertinoProgressColors ??
              ChewieProgressColors(
                playedColor: Color.fromARGB(
                  120,
                  255,
                  255,
                  255,
                ),
                handleColor: Color.fromARGB(
                  255,
                  255,
                  255,
                  255,
                ),
                bufferedColor: Color.fromARGB(
                  60,
                  255,
                  255,
                  255,
                ),
                backgroundColor: Color.fromARGB(
                  20,
                  255,
                  255,
                  255,
                ),
              ),
        ),
      ),
    );
  }

  void _playPause() {
    setState(() {
      if (_latestFlutterPlayerValue != null &&
          _latestFlutterPlayerValue.isPlaying) {
        _hideStuff = false;
        _hideTimer?.cancel();
        flutterPlayerController.pause();
      } else if (tvPlayerController.value.isPlaying) {
        _hideStuff = false;
        _hideTimer?.cancel();
        tvPlayerController.pause();
      } else {
        _cancelAndRestartTimer();
        if (tvPlayerController.value.playbackOnTvStarted) {
          tvPlayerController.resume();
          return;
        }

        if (!flutterPlayerController.value.initialized) {
          flutterPlayerController.initialize().then((_) {
            flutterPlayerController.play();
          });
        } else {
          flutterPlayerController.play();
        }
      }
    });
  }

  void _skipBack() {
    _cancelAndRestartTimer();
    final beginning = Duration(seconds: 0).inMilliseconds;
    final skip = (_latestFlutterPlayerValue.position - Duration(seconds: 15))
        .inMilliseconds;

    Duration position = Duration(milliseconds: math.max(skip, beginning));
    if (_latestTvPlayerValue != null &&
        tvPlayerController.value.playbackOnTvStarted) {
      tvPlayerController.seekTo(position);
      return;
    }

    flutterPlayerController.seekTo(position);
  }

  void _skipForward() {
    _cancelAndRestartTimer();
    final end = _latestFlutterPlayerValue.duration.inMilliseconds;
    final skip = (_latestFlutterPlayerValue.position + Duration(seconds: 15))
        .inMilliseconds;
    var position = Duration(milliseconds: math.min(skip, end));

    if (_latestTvPlayerValue != null &&
        tvPlayerController.value.playbackOnTvStarted) {
      tvPlayerController.seekTo(position);
      return;
    }

    flutterPlayerController.seekTo(position);
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();

    setState(() {
      _hideStuff = false;

      _startHideTimer();
    });
  }
}
