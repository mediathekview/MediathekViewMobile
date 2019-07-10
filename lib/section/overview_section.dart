import 'package:flutter/material.dart';
import 'package:flutter_ws/database/video_progress_entity.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/util/rating_download_util.dart';
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
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black87,
        body: new SafeArea(
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              /* new CarouselWithIndicator(
              videosWithRatingInformation: appState.hotVideosToday,
              viewportFraction: 0.8,
              autoPlay: false,
              enlargeCenterPage: true,
              showIndexBar: false,
              videosWithPlaybackProgress: videosWithPlaybackProgress,
              width: size.width,
            ),*/
              new Flexible(
                child: appState.hotVideosToday != null
                    ? new GridView.count(
                        childAspectRatio: 16 / 9,
                        mainAxisSpacing: 5.0,
                        crossAxisSpacing: 5.0,
                        padding: const EdgeInsets.all(5.0),
                        shrinkWrap: true,
                        crossAxisCount:
                            (orientation == Orientation.portrait) ? 2 : 3,
                        children: Util.getSliderItems(appState.hotVideosToday,
                            videosWithPlaybackProgress, size.width / 2),
                      )
                    : new Container(
                        width: size.width,
                        height: size.width / 16 * 9,
                        child: new Center(
                          child: new CircularProgressIndicator(
                            valueColor:
                                new AlwaysStoppedAnimation<Color>(Colors.red),
                            strokeWidth: 2.0,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
              ),
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
      RatingUtil.loadHotRatingsToday().then((ratings) {
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
      RatingUtil.loadBestRatedAllTime().then((ratings) {
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
      return appState.databaseManager.getAllVideoProgressEntities().then((all) {
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
