import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'custom_chewie_player.dart';
import 'custom_video_controls.dart';

class FlutterVideoPlayer extends StatefulWidget {
  VideoPlayerController controller;
  CustomChewieController chewieController;
  String videoUrl;

  FlutterVideoPlayer(String videoUrl) {
    this.videoUrl = videoUrl;
    controller = VideoPlayerController.network(
      videoUrl,
    );
  }

  @override
  _FlutterVideoPlayerState createState() => _FlutterVideoPlayerState();
}

class _FlutterVideoPlayerState extends State<FlutterVideoPlayer> {
  @override
  void initState() {
    buildControllers();
    // Initialize the controller and store the Future for later use.
    //_initializeVideoPlayerFuture = widget.controller.initialize();

    // Use the controller to loop the video.
    //widget.controller.setLooping(true);
    super.initState();
  }

  void buildControllers() {
    widget.controller = VideoPlayerController.network(
      widget.videoUrl,
    );

    widget.chewieController = new CustomChewieController(
        videoPlayerController: widget.controller,
        autoPlay: true,
        looping: true,
        customControls: new CustomVideoControls(
            backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
            iconColor: Color(0xffffbf00)),
        fullScreenByDefault: true);
  }

  @override
  void dispose() {
    //FlutterVideoPlayer.controller.dispose();
    //FlutterVideoPlayer.chewieController.dispose();
    print("Video Player widget being disposed");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("Video Controller is null" +
        (widget.controller == null ? "true" : "false"));

    return new Container(
      child: new CustomChewie(
        controller: widget.chewieController,
      ),
    );

    /* return new Scaffold(
      backgroundColor: Colors.grey[800],
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          widget.controller.play();
          if (snapshot.connectionState == ConnectionState.done) {
            return new Stack(children: <Widget>[
              new Center(
                  child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                // By default, the VideoPlayer widget takes up as much space as possible.
                child: VideoPlayer(widget.controller),
              )),
              new Positioned(
                top: 10.0,
                left: 10.0,
                child: new IconButton(
                    icon: new Icon(Icons.clear),
                    onPressed: () {
                      Navigator.pop(context);
                    }),
              ),
            ]);
            // If the VideoPlayerController has finished initialization, use
            // the data it provides to limit the aspect ratio of the video.
          } else {
            // If the VideoPlayerController is still initializing, show a
            // loading spinner.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );*/
  }
}
