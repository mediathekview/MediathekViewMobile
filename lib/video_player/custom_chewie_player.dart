import 'dart:async';

import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/video_player/custom_player_with_controls.dart';
import 'package:logging/logging.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

import 'TVPlayerController.dart';

/// A Video Player with Material and Cupertino skins.
///
/// `video_player` is pretty low level. Chewie wraps it in a friendly skin to
/// make it easy to use!
class CustomChewie extends StatefulWidget {
  CustomChewie({
    Key key,
    this.controller,
  })  : assert(controller != null, 'You must provide a chewie controller'),
        super(key: key);

  /// The [CustomChewieController]
  final CustomChewieController controller;

  @override
  CustomChewieState createState() {
    return CustomChewieState();
  }
}

class CustomChewieState extends State<CustomChewie> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(CustomChewie oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return _ChewieControllerProvider(
      controller: widget.controller,
      child: PlayerWithControls(),
    );
  }
}

/// The ChewieController is used to configure and drive the Chewie Player
/// Widgets. It provides methods to control playback, such as [pause] and
/// [resume], as well as methods that control the visual appearance of the player,
/// such as [enterFullScreen] or [exitFullScreen].
///
/// In addition, you can listen to the ChewieController for presentational
/// changes, such as entering and exiting full screen mode. To listen for
/// changes to the playback, such as a change to the seek position of the
/// player, please use the standard information provided by the
/// `VideoPlayerController`.
class CustomChewieController extends ChangeNotifier {
  CustomChewieController({
    this.context,
    this.videoPlayerController,
    this.tvPlayerController,
    this.aspectRatio,
    this.startAt,
    this.looping = false,
    this.fullScreenByDefault = false,
    this.cupertinoProgressColors,
    this.materialProgressColors,
    this.placeholder,
    this.overlay,
    this.showControls = true,
    this.customControls,
    this.errorBuilder,
    this.allowedScreenSleep = true,
    this.isLive = false,
    this.allowFullScreen = true,
    this.allowMuting = true,
    this.systemOverlaysAfterFullScreen = SystemUiOverlay.values,
    this.deviceOrientationsAfterFullScreen = const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
    this.video,
    this.isCurrentlyPlayingOnTV,
  }) : assert(videoPlayerController != null,
            'You must provide a controller to play a video') {
    _initialize();
  }

  final Logger logger = new Logger('SamsungTvCastManager');

  final BuildContext context;

  /// The controller for the video you want to play
  final VideoPlayerController videoPlayerController;

  // Controller for playing the video on the Tv
  final TvPlayerController tvPlayerController;

  // The video for playing
  final Video video;

  /// Start video at a certain position
  final Duration startAt;

  /// Whether or not the video should loop
  final bool looping;

  /// Whether or not to show the controls
  final bool showControls;

  /// Defines customised controls. Check [MaterialControls] or
  /// [CupertinoControls] for reference.
  final Widget customControls;

  /// When the video playback runs  into an error, you can build a custom
  /// error message.
  final Widget Function(BuildContext context, String errorMessage) errorBuilder;

  /// The Aspect Ratio of the Video. Important to get the correct size of the
  /// video!
  ///
  /// Will fallback to fitting within the space allowed.
  final double aspectRatio;

  /// The colors to use for controls on iOS. By default, the iOS player uses
  /// colors sampled from the original iOS 11 designs.
  final ChewieProgressColors cupertinoProgressColors;

  /// The colors to use for the Material Progress Bar. By default, the Material
  /// player uses the colors from your Theme.
  final ChewieProgressColors materialProgressColors;

  /// The placeholder is displayed underneath the Video before it is initialized
  /// or played.
  final Widget placeholder;

  /// A widget which is placed between the video and the controls
  final Widget overlay;

  /// Defines if the player will start in fullscreen when play is pressed
  final bool fullScreenByDefault;

  /// Defines if the player will sleep in fullscreen or not
  final bool allowedScreenSleep;

  /// Defines if the controls should be for live stream video
  final bool isLive;

  /// Defines if the fullscreen control should be shown
  final bool allowFullScreen;

  /// Defines if the mute control should be shown
  final bool allowMuting;

  /// Defines the system overlays visible after exiting fullscreen
  final List<SystemUiOverlay> systemOverlaysAfterFullScreen;

  /// Defines the set of allowed device orientations after exiting fullscreen
  final List<DeviceOrientation> deviceOrientationsAfterFullScreen;

  /// Start playing on TV when connected to it
  /// only used for init as this can change later
  final bool isCurrentlyPlayingOnTV;

  static CustomChewieController of(BuildContext context) {
    final chewieControllerProvider =
        context.inheritFromWidgetOfExactType(_ChewieControllerProvider)
            as _ChewieControllerProvider;

    return chewieControllerProvider.controller;
  }

  bool _isFullScreen = false;

  bool get isFullScreen => _isFullScreen;

  Future _initialize() async {
    // playing video on mobile - do not turn off the screen
    Wakelock.enable();

    await videoPlayerController.setLooping(looping);

    // always initializing video player to obtain video information (length, size) to display the controls
    if (!videoPlayerController.value.initialized) {
      await videoPlayerController.initialize();
    }

    if (fullScreenByDefault) {
      enterFullScreen();
    }

    // if is already playing on TV, do nothing
    if (isCurrentlyPlayingOnTV) {
      return;
    }

    await videoPlayerController.play();
    await videoPlayerController.seekTo(startAt);
  }

  void enterFullScreen() {
    _isFullScreen = true;
    notifyListeners();
  }

  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    notifyListeners();
  }
}

class _ChewieControllerProvider extends InheritedWidget {
  const _ChewieControllerProvider({
    Key key,
    @required this.controller,
    @required Widget child,
  })  : assert(controller != null),
        assert(child != null),
        super(key: key, child: child);

  final CustomChewieController controller;

  @override
  bool updateShouldNotify(_ChewieControllerProvider old) =>
      controller != old.controller;
}
