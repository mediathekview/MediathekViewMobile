import 'package:flutter/material.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:flutter_ws/database/video_entity.dart';
import 'package:flutter_ws/database/video_progress_entity.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/util/channel_util.dart';
import 'package:flutter_ws/util/cross_axis_count.dart';
import 'package:flutter_ws/util/device_information.dart';
import 'package:flutter_ws/util/show_snackbar.dart';
import 'package:flutter_ws/util/text_styles.dart';
import 'package:flutter_ws/widgets/downloadSection/current_downloads.dart';
import 'package:flutter_ws/widgets/downloadSection/heading.dart';
import 'package:flutter_ws/widgets/downloadSection/video_list_item_builder.dart';
import 'package:flutter_ws/widgets/downloadSection/watch_history.dart';
import 'package:flutter_ws/widgets/overviewSection/util.dart';
import 'package:flutter_ws/widgets/videolist/circular_progress_with_text.dart';
import 'package:logging/logging.dart';

const ERROR_MSG = "Deletion of video failed.";
const TRY_AGAIN_MSG = "Try again.";
const recentlyWatchedVideosLimit = 5;

class DownloadSection extends StatefulWidget {
  final Logger logger = new Logger('DownloadSection');
  final AppSharedState appWideState;

  DownloadSection(this.appWideState);

  @override
  State<StatefulWidget> createState() {
    return new DownloadSectionState(new Set());
  }
}

class DownloadSectionState extends State<DownloadSection> {
  List<Video> currentDownloads = new List();
  Set<Video> downloadedVideos = new Set();
  Set<String> userDeletedAppId; //used for fade out animation
  int milliseconds = 1500;
  Map<String, double> progress = new Map();
  Map<String, VideoProgressEntity> videosWithPlaybackProgress = new Map();

  DownloadSectionState(this.userDeletedAppId);

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.appWideState.appState.downloadManager.syncCompletedDownloads();
    loadAlreadyDownloadedVideosFromDb();
    loadVideosWithPlaybackProgress();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    Widget loadingIndicator = getCurrentDownloadsTopBar();

    return _buildLayout(
        videosWithPlaybackProgress, size, context, loadingIndicator);
  }

  Widget getCurrentDownloadsTopBar() {
    if (currentDownloads.length == 1) {
      return CircularProgressWithText(
          new Text(
            "Downloading: '" + currentDownloads.elementAt(0).title + "'",
            style: connectionLostTextStyle,
            softWrap: true,
            maxLines: 3,
          ),
          Colors.green,
          Colors.green);
    } else if (currentDownloads.length > 1) {
      return CircularProgressWithText(
        new Text(
            "Downloading " + currentDownloads.length.toString() + " videos",
            style: connectionLostTextStyle),
        Colors.green,
        Colors.green,
        height: 50.0,
      );
    } else {
      return new Container();
    }
  }

  //Cancels active download (remove from task schema), removes the file from local storage & deletes the entry in VideoEntity schema
  void deleteDownload(BuildContext context, String id) {
    widget.logger.info("Deleting video with title id: " + id);
    widget.appWideState.appState.downloadManager
        .deleteVideo(id)
        .then((bool deletedSuccessfully) {
      loadAlreadyDownloadedVideosFromDb();
      if (deletedSuccessfully) {
        SnackbarActions.showSuccess(context, "Löschen erfolgreich");
        return;
      }
      SnackbarActions.showErrorWithTryAgain(context, ERROR_MSG, TRY_AGAIN_MSG,
          widget.appWideState.appState.downloadManager.deleteVideo, id);
    });
  }

  void loadAlreadyDownloadedVideosFromDb() async {
    Set<VideoEntity> downloads = await widget
        .appWideState.appState.databaseManager
        .getAllDownloadedVideos();

    if (downloads != null && this.downloadedVideos.length != downloads.length) {
      widget.logger.info("Downloads changed");
      this.downloadedVideos =
          downloads.map((entity) => Video.fromMap(entity.toMap())).toSet();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future loadVideosWithPlaybackProgress() async {
    //check for playback progress
    if (videosWithPlaybackProgress.isEmpty) {
      return widget.appWideState.appState.databaseManager
          .getLastViewedVideos(recentlyWatchedVideosLimit)
          .then((all) {
        if (all != null && all.isNotEmpty) {
          bool stateReloadNeeded = false;
          for (var i = 0; i < all.length; ++i) {
            var entity = all.elementAt(i);
            if (!videosWithPlaybackProgress.containsKey(entity)) {
              videosWithPlaybackProgress.putIfAbsent(entity.id, () => entity);
              stateReloadNeeded = true;
            }
          }
          if (stateReloadNeeded) {
            setState(() {});
          }
          // generatePreview(all.take(amount_of_swiper_items))
        }
        return;
      });
    }
  }

  SliverPadding getWatchHistoryButton() {
    ListTile tile = new ListTile(
      leading: new Icon(
        Icons.history,
        color: Color(0xffffbf00),
        size: 30.0,
      ),
      title: new Text(
        "Alle angesehenen Videos",
        style: new TextStyle(
            fontSize: 16.0, color: Colors.white, fontWeight: FontWeight.w600),
      ),
      onTap: () async {
        await Navigator.of(context).push(new MaterialPageRoute(
            builder: (BuildContext context) {
              // TODO: save previews of recently watched videos to disk
              // 1) get previews from file 2) previews even when video is already deleted
              return new WatchHistory();
            },
            settings: RouteSettings(name: "WatchHistory"),
            fullscreenDialog: true));
      },
    );

    return SliverPadding(
      padding: EdgeInsets.only(top: 10.0, bottom: 8.0),
      sliver: new SliverToBoxAdapter(child: tile),
    );
  }

  Widget _buildLayout(
      Map<String, VideoProgressEntity> videosWithPlaybackProgress,
      Size size,
      BuildContext context,
      Widget currentDownloadsTopBar) {
    Widget recentlyViewedHeading =
        new SliverToBoxAdapter(child: new Container());
    Widget recentlyViewedSlider =
        new SliverToBoxAdapter(child: new Container());
    Widget watchHistoryNavigation =
        new SliverToBoxAdapter(child: new Container());

    int crossAxisCount = CrossAxisCount.getCrossAxisCount(context);
    widget.logger.info("Cross axis count: " + crossAxisCount.toString());
    if (videosWithPlaybackProgress.isNotEmpty) {
      recentlyViewedHeading =
          new Heading("Kürzlich angesehen", 25.0, 20.0, 5.0, 16.0);

      List<Widget> watchHistoryItems = Util.getWatchHistoryItems(
          videosWithPlaybackProgress, size.width / crossAxisCount);

      double containerHeight = size.width / crossAxisCount / 16 * 9;

      Widget recentlyViewedSwiper = ListView(
        scrollDirection: Axis.horizontal,
        children: watchHistoryItems,
      );

      // special case for mobile & portrait -> use swiper instead of horizontally scrolling list
      if (!DeviceInformation.isTablet(context) &&
          MediaQuery.of(context).orientation == Orientation.portrait) {
        recentlyViewedSwiper =
            getMobileRecentlyWatchedSwiper(watchHistoryItems);
      }

      recentlyViewedSlider = SliverToBoxAdapter(
          child: new Container(
              height: containerHeight, child: recentlyViewedSwiper));

      // build navigation to complete history
      watchHistoryNavigation = getWatchHistoryButton();
    }

    Widget downloadHeading =
        new SliverToBoxAdapter(child: getEmptyDownloadWidget());
    Widget downloadList = new SliverToBoxAdapter(
      child: new Container(),
    );

    if (downloadedVideos != null && downloadedVideos.isNotEmpty) {
      downloadHeading = new Heading("Meine Downloads", 25.0, 20.0, 20.0, 0.0);

      var videoListItemBuilder = new VideoListItemBuilder.name(
          downloadedVideos.toList(), true, true, false,
          onRemoveVideo: deleteDownload);

      downloadList = SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 16 / 9,
          mainAxisSpacing: 1.0,
          crossAxisSpacing: 5.0,
        ),
        delegate: SliverChildBuilderDelegate(videoListItemBuilder.itemBuilder,
            childCount: downloadedVideos.length),
      );
    }

    return new Scaffold(
      backgroundColor: Colors.grey[800],
      body: new SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: currentDownloadsTopBar,
            ),
            recentlyViewedHeading,
            recentlyViewedSlider,
            watchHistoryNavigation,
            downloadHeading,
            new CurrentDownloads(widget.appWideState, downloadedVideosChanged),
            downloadList
          ],
        ),
      ),
    );
  }

  Theme getMobileRecentlyWatchedSwiper(List<Widget> watchHistoryItems) {
    return new Theme(
      //data: new ThemeData(primarySwatch: Colors.red),
      data: new ThemeData(
          primarySwatch: new MaterialColor(
        0xffffbf00,
        const <int, Color>{
          50: Color(0xFFFAFAFA),
          100: Color(0xFFF5F5F5),
          200: Color(0xFFEEEEEE),
          300: Color(0xFFE0E0E0),
          350: Color(0xFFD6D6D6),
          400: Color(0xFFBDBDBD),
          500: Color(0xFF9E9E9E),
          600: Color(0xFF757575),
          700: Color(0xFF616161),
          800: Color(0xFF424242),
          850: Color(0xFF303030),
          900: Color(0xFF212121),
        },
      )),
      child: new Swiper(
        itemBuilder: (BuildContext context, int index) {
          return watchHistoryItems[index];
        },
        itemCount: watchHistoryItems.length,
        pagination: new SwiperPagination(),
        control: new SwiperControl(),
      ),
    );
  }

  Center getEmptyDownloadWidget() {
    return new Center(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          new Center(
            child: new Text(
              "Keine Downloads",
              style: new TextStyle(fontSize: 25),
            ),
          ),
          new Container(
            height: 50,
            child: new ListView(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              children: ChannelUtil.getAllChannelImages(),
            ),
          ),
        ],
      ),
    );
  }

  // triggered when the download section should setState
  // 1) Download finished -> reload downloads from Database
  // 2) Current downloads retrieved -> to show green top bar
  void downloadedVideosChanged(List<Video> currentDownloads) {
    widget.logger.info("Downloads changed: setState()");

    if (this.currentDownloads.length != currentDownloads.length) {
      this.currentDownloads = currentDownloads;

      loadAlreadyDownloadedVideosFromDb();
      loadVideosWithPlaybackProgress();

      if (mounted) {
        setState(() {});
      }
    }
  }
}
