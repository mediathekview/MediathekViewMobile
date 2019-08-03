import 'package:flutter/material.dart';
import 'package:flutter_ws/database/video_progress_entity.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/util/device_information.dart';
import 'package:flutter_ws/util/rating_util.dart';
import 'package:flutter_ws/widgets/overviewSection/carousel_slider.dart';
import 'package:flutter_ws/widgets/overviewSection/util.dart';
import 'package:logging/logging.dart';

class OverviewSection extends StatefulWidget {
  final Logger logger = new Logger('VideoWidget');

  @override
  _OverviewSectionState createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<OverviewSection> {
  AppState appState;
  Map<String, VideoProgressEntity> videosWithPlaybackProgress = new Map();
  bool ratingsAlreadyRequested = false;

  @override
  Widget build(BuildContext context) {
    appState = AppSharedStateContainer.of(context).appState;
    Size size = MediaQuery.of(context).size;
    Orientation orientation = MediaQuery.of(context).orientation;

    //load ratings after the database access to avoid requesting ratings multiple times & starting preview generation multiple times
    loadVideosWithPlaybackProgress().then((v) => loadRatings());
    return _buildMobile(size, orientation, DeviceInformation.isTablet(context));
  }

  Widget _buildMobile(Size size, Orientation orientation, bool isTablet) {
    int crossAxisCount;
    if (orientation == Orientation.portrait && isTablet) {
      crossAxisCount = 2;
    } else if (orientation == Orientation.portrait && !isTablet) {
      crossAxisCount = 1;
    } else if (orientation == Orientation.landscape && isTablet) {
      crossAxisCount = 3;
    } else if (orientation == Orientation.landscape && !isTablet) {
      crossAxisCount = 2;
    }

    return new Scaffold(
      backgroundColor: Colors.grey[800],
      body: new SafeArea(
        child: Container(
          child: CustomScrollView(
            slivers: <Widget>[
              new SliverList(
                  delegate: new SliverChildListDelegate(
                [
                  new CarouselWithIndicator(
                    videosWithRatingInformation: appState.bestVideosAllTime,
                    viewportFraction: 1.0,
                    autoPlay: true,
                    enlargeCenterPage: false,
                    showIndexBar: true,
                    videosWithPlaybackProgress: videosWithPlaybackProgress,
                    width: size.width,
                    orientation: orientation,
                  ),
                  appState.hotVideosToday == null ||
                          appState.hotVideosToday.isNotEmpty
                      ? getHeading("Heute beliebt")
                      : new Container(),
                ],
              )),
              appState.hotVideosToday != null
                  ? appState.hotVideosToday.isNotEmpty
                      ? new SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: 16 / 9,
                            mainAxisSpacing: 8.0,
                            crossAxisSpacing: 8.0,
                          ),
                          delegate: SliverChildListDelegate(
                            Util.getSliderItems(appState.hotVideosToday,
                                videosWithPlaybackProgress, size.width / 2),
                          ),
                        )
                      : SliverToBoxAdapter(child: new Container())
                  : new SliverList(
                      delegate: new SliverChildListDelegate([
                      new Container(
                        width: size.width,
                        height: size.width / 16 * 9,
                        child: new Center(
                          child: new CircularProgressIndicator(
                            valueColor: new AlwaysStoppedAnimation<Color>(
                                Color(0xffffbf00)),
                            strokeWidth: 5.0,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ])),
            ],
          ),
        ),
      ),
    );
  }

  Padding getHeading(String message) {
    return new Padding(
      padding: EdgeInsets.only(left: 20.0, top: 10.0, bottom: 16.0),
      child: new Text(
        message,
        style: new TextStyle(
            fontSize: 25.0, color: Colors.white, fontWeight: FontWeight.w800),
      ),
    );
  }

  void loadRatings() {
    // make sure to only make one request
    if (ratingsAlreadyRequested) {
      return;
    }
    ratingsAlreadyRequested = true;

    if (appState.hotVideosToday == null) {
      RatingUtil.loadBestRatingsToday().then((ratings) {
        widget.logger.info(
            "Hot ratings retrieved. Amount: " + ratings.length.toString());

        //request previews
        ratings.forEach((videoId, rating) => appState.videoPreviewManager
            .generatePreview(videoId, url: rating.url_video));

        appState.setHotVideosToday(ratings);
        if (mounted) {
          setState(() {});
        }
      });
    }

    if (appState.bestVideosAllTime == null) {
      RatingUtil.loadBestRatingsOverall().then((ratings) {
        widget.logger.info(
            "Best ratings retrieved. Amount: " + ratings.length.toString());

        //request previews
        ratings.forEach((videoId, rating) {
          appState.videoPreviewManager
              .generatePreview(videoId, url: rating.url_video);
        });

        appState.setBestVideosAllTime(ratings);

        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  Future loadVideosWithPlaybackProgress() async {
    //check for playback progress
    if (videosWithPlaybackProgress.isEmpty) {
      return appState.databaseManager.getAllLastViewedVideos().then((all) {
        if (all != null && all.isNotEmpty) {
          all.forEach((entity) =>
              videosWithPlaybackProgress.putIfAbsent(entity.id, () => entity));
          if (mounted) setState(() {});
        }
        return;
      });
    }
  }
}
