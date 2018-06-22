//import 'package:flutter/cupertino.dart';
//import 'package:flutter/material.dart';
//import 'package:meta/meta.dart';
//import 'package:uuid/uuid.dart';
//import 'package:video_player/video_player.dart';
//
//
////Todo leaking conn - movev up - only one chewie but more contrrollers
//class VideoPlayer extends StatefulWidget {
//  final String videoTitle;
//  final String url;
////  final VideoPlayerController _controller = new VideoPlayerController.network(
////  'https://flutter.github.io/assets-for-api-docs/videos/butterfly.mp4');
//
//  VideoPlayer({@required this.videoTitle, @required this.url});
//
//  @override
//  State<StatefulWidget> createState() {
//    return new _VideoPlayerState();
//  }
//}
//
//class _VideoPlayerState extends State<VideoPlayer> {
//  TargetPlatform _platform;
//  VideoPlayerController _controller;
//  VoidCallback listener;
//  Chewie chewie;
//  Uuid uuid;
//
//  _VideoPlayerState() {
//
//    listener = () async {
//      if (_controller.value.initialized) {
//        await _controller.seekTo(new Duration(seconds: 1));
//        print("2 seconds preview played - pausing video playback");
//        _controller.pause();
//        _controller.removeListener(listener);
//      }
//    };
//  }
//
//
////  @override
////  void dispose() {
////    print("Setting controller to null for video: " + widget.videoTitle);
////    _controller = null;
////    super.dispose();
////  }
//
//  @override
//  void initState() {
//    super.initState();
//    getNewVideoPlaybackController();
//    uuid = new Uuid();
//
//  }
//
//  VideoPlayerController getNewVideoPlaybackController() {
//    print("Creating new video player controller");
//    _controller =  new VideoPlayerController.network(widget.url);
//
//    return _controller;
//  }
//
//  @override
//  Widget build(BuildContext context) {
//
//    print("Rendering video with titel <" + widget.videoTitle.toString() +">");
//
//
//
//
//    controller.addListener(listener);
//
//    return new Container(
//      key: new Key(uuid.v1()),
//      child: chewie,
//    );
//  }
//}