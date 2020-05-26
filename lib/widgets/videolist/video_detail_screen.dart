import 'package:flutter/material.dart';
import 'package:flutter_ws/database/video_entity.dart';
import 'package:flutter_ws/database/video_progress_entity.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/util/device_information.dart';
import 'package:flutter_ws/util/text_styles.dart';
import 'package:flutter_ws/util/timestamp_calculator.dart';
import 'package:flutter_ws/widgets/bars/playback_progress_bar.dart';
import 'package:flutter_ws/widgets/videolist/download/download_progress_bar.dart';
import 'package:flutter_ws/widgets/videolist/util/util.dart';
import 'package:flutter_ws/widgets/videolist/video_widget.dart';
import 'package:logging/logging.dart';

import 'download_switch.dart';

class VideoDetailScreen extends StatefulWidget {
  final Logger logger = new Logger('VideoDetailScreen');

  AppSharedState appWideState;
  Image image;
  Video video;
  VideoEntity entity;
  bool isDownloading;
  bool isDownloaded;
  String heroUuid;

  VideoDetailScreen(this.appWideState, this.image, this.video, this.entity,
      this.isDownloading, this.isDownloaded, this.heroUuid);

  @override
  _VideoDetailScreenState createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  VideoProgressEntity videoProgressEntity;

  @override
  void initState() {
    checkPlaybackProgress();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = DeviceInformation.isTablet(context);
    double totalImageWidth = MediaQuery.of(context).size.width;

    var orientation = MediaQuery.of(context).orientation;

    if (isTablet && orientation == Orientation.landscape) {
      totalImageWidth = totalImageWidth * 0.7;
      widget.logger.info("Reduced with to: " + totalImageWidth.toString());
    }

    double height = VideoWidgetState.calculateImageHeight(
        widget.image, totalImageWidth, 16 / 9);
    widget.logger.info("Reduced height to: " + height.toString());

    GestureDetector image = getImageSurface(totalImageWidth, height);

    Widget downloadProgressBar = new DownloadProgressBar(widget.video.id,
        widget.video.title, widget.appWideState.appState.downloadManager, true);

    Widget layout;
    if (isTablet && orientation == Orientation.landscape) {
      layout = buildTabletLandscapeLayout(
          totalImageWidth, height, image, context, downloadProgressBar);
    } else if (!isTablet && orientation == Orientation.landscape) {
      // mobile landscape -> only provide ability to play video. no title nothing

    } else {
      // all portrait:  like youtube:
      // first the title underneath
      // then rating
      // then description
      layout = buildVerticalLayout(image, downloadProgressBar);
    }

    return new Scaffold(
      backgroundColor: Colors.grey[800],
      body: new SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: getAppBar(),
            ),
            SliverToBoxAdapter(
              child: layout,
            ),
          ],
        ),
      ),
    );
  }

  Column buildTabletLandscapeLayout(double totalImageWidth, double height,
      GestureDetector image, BuildContext context, Widget downloadProgressBar) {
    Widget description = getDescription();
    Container metaInformation = getMeta();

    double rowPaddingLeft = 10;
    double rowPaddingRight = 5;
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        new Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              color: Colors.grey[900],
              child: new ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: totalImageWidth, maxHeight: height),
                child: new Stack(
                  alignment: Alignment.center,
                  fit: StackFit.passthrough,
                  children: <Widget>[
                    image,
                    new Positioned(
                        bottom: 0.0,
                        left: 0.0,
                        right: 0.0,
                        child: downloadProgressBar)
                  ],
                ),
              ),
            ),
            new Padding(
              padding:
                  EdgeInsets.only(left: rowPaddingLeft, right: rowPaddingRight),
              child: new ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                child: new Container(
                  width: MediaQuery.of(context).size.width -
                      totalImageWidth -
                      rowPaddingLeft -
                      rowPaddingRight,
                  height: height,
                  color: Colors.grey[700],
                  child: description,
                ),
              ),
            )
          ],
        ),
        new Container(
          margin: EdgeInsets.only(left: 10.0, top: 10.0, bottom: 10.0),
          child: new DownloadSwitch(
              widget.appWideState,
              widget.video,
              widget.isDownloading,
              widget.isDownloaded,
              widget.appWideState.appState.downloadManager),
        ),
        metaInformation,
      ],
    );
  }

  Column buildVerticalLayout(
      GestureDetector image, Widget downloadProgressBar) {
    Widget sideBar = new SingleChildScrollView(
      child: new Container(
        margin: EdgeInsets.only(left: 35, top: 10),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Text("Beschreibung",
                style: headerTextStyle.copyWith(fontSize: 30)),
            new Container(height: 10),
            new Text(widget.video.description,
                style: subHeaderTextStyle.copyWith(fontSize: 20)),
          ],
        ),
      ),
    );

    Widget meta = getMeta();

    return new Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(color: Colors.grey[900], child: image),
          downloadProgressBar,
          new Container(
            height: 10,
          ),
          new Padding(
            padding: new EdgeInsets.only(left: 10.0),
            child: new DownloadSwitch(
                widget.appWideState,
                widget.video,
                widget.isDownloading,
                widget.isDownloaded,
                widget.appWideState.appState.downloadManager),
          ),
          new Container(
            height: 10,
          ),
          meta,
          sideBar,
        ]);
  }

  Container getMeta() {
    return new Container(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
            margin: EdgeInsets.only(left: 35),
            child: new Chip(
              backgroundColor: Colors.grey[700],
              avatar: CircleAvatar(
                backgroundColor: Theme.of(context).accentColor,
                child: new Icon(Icons.info),
                maxRadius: 25,
              ),
              label: new Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    new Row(
                      children: <Widget>[
                        Text(
                          "Thema: ",
                          style: new TextStyle(
                              color: Colors.white,
                              backgroundColor: Colors.grey[700],
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.video.topic,
                          style: new TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                              backgroundColor: Colors.grey[700]),
                        ),
                      ],
                    ),
                    new Row(
                      children: <Widget>[
                        Text(
                          "Länge: ",
                          style: new TextStyle(
                              color: Colors.white,
                              backgroundColor: Colors.grey[700],
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.video.duration != null
                              ? Calculator.calculateDuration(
                                  widget.video.duration.toString())
                              : "?",
                          style: new TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                              backgroundColor: Colors.grey[700]),
                        ),
                      ],
                    ),
                    new Row(
                      children: <Widget>[
                        Text(
                          "Ausgestrahlt: ",
                          style: new TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                              backgroundColor: Colors.grey[700],
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.video.timestamp != null
                              ? Calculator.calculateTimestamp(
                                  widget.video.timestamp)
                              : "?",
                          style: new TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                              backgroundColor: Colors.grey[700]),
                        ),
                      ],
                    )
                  ]),
            ),
          ),
        ],
      ),
    );
  }

  SingleChildScrollView getDescription() {
    return new SingleChildScrollView(
      child: new Container(
        margin: EdgeInsets.only(left: 5),
        child: new Column(
          children: <Widget>[
            new Text("Beschreibung",
                style: headerTextStyle.copyWith(fontSize: 30)),
            new Text(widget.video.description,
                style: subHeaderTextStyle.copyWith(fontSize: 20)),
          ],
        ),
      ),
    );
  }

  GestureDetector getImageSurface(double totalImageWidth, double height) {
    Widget videoProgressBar = new Container();
    if (videoProgressEntity != null) {
      videoProgressBar = new PlaybackProgressBar(videoProgressEntity.progress,
          int.tryParse(widget.video.duration.toString()), false);
    }

    return new GestureDetector(
      child: new AspectRatio(
        aspectRatio: totalImageWidth > height
            ? totalImageWidth / height
            : height / totalImageWidth,
        child: new Container(
          constraints: BoxConstraints(maxWidth: totalImageWidth),
          child: new Stack(
            alignment: Alignment.center,
            fit: StackFit.passthrough,
            children: <Widget>[
              new Hero(tag: widget.heroUuid, child: widget.image),
              new Positioned(
                bottom: 0,
                left: 0.0,
                right: 0.0,
                child: new Opacity(opacity: 0.7, child: videoProgressBar),
              ),
              new Center(
                  child: Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 150.0,
              )),
            ],
          ),
        ),
      ),
      onTap: () async {
        // play video
        if (mounted) {
          Util.playVideoHandler(context, widget.appWideState, widget.entity,
                  widget.video, videoProgressEntity)
              .then((value) {
            // setting state after the video player popped the Navigator context
            // this reloads the video progress entity to show the playback progress
            checkPlaybackProgress();
          });
        }
      },
    );
  }

  AppBar getAppBar() {
    return new AppBar(
      title: new Text(
        widget.video.title,
        style: sectionHeadingTextStyle,
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: new Color(0xffffbf00),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back, size: 30.0, color: Colors.white),
        onPressed: () {
          //return channels when user pressed back
          return Navigator.pop(context);
        },
      ),
    );
  }

  void checkPlaybackProgress() async {
    widget.appWideState.appState.databaseManager
        .getVideoProgressEntity(widget.video.id)
        .then((entity) {
      widget.logger.info("Video has playback progress: " + widget.video.title);
      videoProgressEntity = entity;
      if (mounted) {
        setState(() {});
      }
    });
  }
}
