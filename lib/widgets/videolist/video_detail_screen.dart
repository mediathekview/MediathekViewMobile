import 'package:filesize/filesize.dart';
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

import 'channel_thumbnail.dart';
import 'download_switch.dart';
import 'meta_info_list_tile.dart';

class VideoDetailScreen extends StatefulWidget {
  final Logger logger = new Logger('VideoDetailScreen');

  AppSharedState appWideState;
  Image image;
  Video video;
  VideoEntity entity;
  bool isDownloading;
  bool isDownloaded;
  String heroUuid;
  String defaultImageAssetPath;

  VideoDetailScreen(
      this.appWideState,
      this.image,
      this.video,
      this.entity,
      this.isDownloading,
      this.isDownloaded,
      this.heroUuid,
      this.defaultImageAssetPath);

  @override
  _VideoDetailScreenState createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  VideoProgressEntity videoProgressEntity;
  bool isTablet;

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

    Widget downloadProgressBar = new DownloadProgressBar(
        widget.video.id,
        widget.video.title,
        widget.appWideState.appState.downloadManager,
        true,
        null);

    Widget layout;
    if (isTablet && orientation == Orientation.landscape) {
      layout = buildTabletLandscapeLayout(
          totalImageWidth, height, image, context, downloadProgressBar);
    } else if (!isTablet && orientation == Orientation.landscape) {
      // mobile landscape -> only provide ability to play video. no title nothing
      layout = new Container(color: Colors.grey[900], child: image);
      // layout = buildMobileLandscapeLayout();
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
              widget.appWideState.appState.downloadManager,
              widget.video.size != null ? filesize(widget.video.size) : "",
              isTablet),
        ),
      ],
    );
  }

  Column buildVerticalLayout(
      GestureDetector image, Widget downloadProgressBar) {
    Widget sideBar = Container();

    if (widget.video.description != null &&
        widget.video.description.length > 0) {
      sideBar = new SingleChildScrollView(
        child: new Container(
          margin: EdgeInsets.only(left: 35, top: 10),
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Text("Description",
                  style: headerTextStyle.copyWith(fontSize: 30)),
              new Container(height: 10),
              new Text(widget.video.description,
                  style: subHeaderTextStyle.copyWith(fontSize: 20)),
            ],
          ),
        ),
      );
    }
    return new Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Stack(
              alignment: Alignment.center,
              fit: StackFit.passthrough,
              children: <Widget>[
                new Container(color: Colors.grey[900], child: image),
                new Positioned(
                  bottom: 0,
                  left: 0.0,
                  right: 0.0,
                  child: new Opacity(
                    opacity: 0.7,
                    child: new Container(
                      color: Colors.grey[800],
                      child: MetaInfoListTile.getVideoMetaInformationListTile(
                          context,
                          widget.video.duration.toString(),
                          widget.video.title,
                          widget.video.timestamp,
                          widget.defaultImageAssetPath,
                          widget.entity != null),
                    ),
                  ),
                ),
                new Positioned(
                    bottom: 0.0,
                    left: 0.0,
                    right: 0.0,
                    child: downloadProgressBar)
              ]),
          new DownloadSwitch(
              widget.appWideState,
              widget.video,
              widget.isDownloading,
              widget.isDownloaded,
              widget.appWideState.appState.downloadManager,
              widget.video.size != null ? filesize(widget.video.size) : "",
              isTablet),
          sideBar,
        ]);
  }

  SingleChildScrollView getDescription() {
    var container = new Container();

    if (widget.video.description != null &&
        widget.video.description.length > 0) {
      container = new Container(
        margin: EdgeInsets.only(left: 5),
        child: new Column(
          children: <Widget>[
            new Text("Description",
                style: headerTextStyle.copyWith(fontSize: 30)),
            new Text(widget.video.description,
                style: subHeaderTextStyle.copyWith(fontSize: 20)),
          ],
        ),
      );
    }

    return new SingleChildScrollView(
      child: container,
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
        backgroundColor: new Color(0xffffbf00),
        titleSpacing: 0.0,
        centerTitle: false,
        title: new Text(
          "Zurück",
          style: sectionHeadingTextStyle,
        ),
        leading: new Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          new IconButton(
            icon: new Icon(Icons.arrow_back, size: 30.0, color: Colors.white),
            onPressed: () {
              //return channels when user pressed back
              return Navigator.pop(context);
            },
          ),
        ]));
  }

  void checkPlaybackProgress() async {
    widget.appWideState.appState.databaseManager
        .getVideoProgressEntity(widget.video.id)
        .then((entity) {
      widget.logger.fine("Video has playback progress: " + widget.video.title);
      videoProgressEntity = entity;
      if (mounted) {
        setState(() {});
      }
    });
  }

  ListTile getBottomBar(BuildContext context, String assetPath, String title,
      String lenght, int timestamp, bool isDownloaded) {
    return new ListTile(
      trailing: new Text(
        lenght != null ? Calculator.calculateDuration(lenght) : "",
        style: videoMetadataTextStyle.copyWith(color: Colors.white),
      ),
      leading: assetPath.isNotEmpty
          ? new ChannelThumbnail(assetPath, isDownloaded)
          : new Container(),
      title: new Text(
        title,
        style:
            Theme.of(context).textTheme.subhead.copyWith(color: Colors.white),
      ),
      subtitle: new Text(
        timestamp != null ? Calculator.calculateTimestamp(timestamp) : "",
        style: Theme.of(context).textTheme.title.copyWith(color: Colors.white),
      ),
    );
  }
}
