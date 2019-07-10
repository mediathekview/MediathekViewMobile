import 'package:flutter/material.dart';
import 'package:flutter_ws/enum/channels.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/model/video_rating.dart';
import 'package:flutter_ws/util/row_adapter.dart';
import 'package:flutter_ws/widgets/videolist/loading_list_view.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

typedef void ListTileTapped(String id);

class ScrollPositionHolder {
  double value = 0.0;
}

class VideoListView extends StatefulWidget {
  final Logger logger = new Logger('VideoListView');
  final int pageThreshold = 25;
  // final ScrollPositionHolder offset = new ScrollPositionHolder();

  List<Video> videos;
  var queryEntries;
  var refreshList;
  int amountOfVideosFetched;
  int totalResultSize;
  int currentQuerySkip;
  TickerProviderStateMixin mixin;

  VideoListView({
    Key key,
    @required this.queryEntries,
    @required this.amountOfVideosFetched,
    @required this.videos,
    @required this.refreshList,
    @required this.totalResultSize,
    @required this.currentQuerySkip,
    @required this.mixin,
  }) : super(key: key);

  @override
  _VideoListViewState createState() => _VideoListViewState();
}

class _VideoListViewState extends State<VideoListView> {
  ScrollController scrollController;
  Map<String, VideoRating> ratingCache;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    widget.logger.info("Rendering Main Video List with list length " +
        widget.videos.length.toString());

    if (widget.videos.length == 0 && widget.amountOfVideosFetched == 0) {
      widget.logger.fine("No Videos found");
      return new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Text(
            "0 Videos zu dieser Suchanfrage",
            style: new TextStyle(fontSize: 25),
          ),
          new Container(
            height: 50,
            child: new ListView(
              scrollDirection: Axis.horizontal,
              //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: getAllChannelImages(),
            ),
          )
        ],
      );
    } else if (widget.videos.length == 0) {
      widget.logger.fine("Searching: video list legth : 0 & amountFetched: " +
          widget.amountOfVideosFetched.toString());
      return new LoadingListPage();
    }

    return ListView.builder(
        controller: scrollController,
        itemBuilder: itemBuilder,
        itemCount: widget.videos.length);
  }

  Widget itemBuilder(BuildContext context, int index) {
    if (index + widget.pageThreshold > widget.videos.length) {
      widget.queryEntries();
    }

    if (widget.currentQuerySkip + widget.pageThreshold >=
            widget.totalResultSize &&
        widget.videos.length == index + 1) {
      widget.logger.info("ResultList - reached last position of result list.");
    } else if (widget.videos.length == index + 1) {
      widget.logger.info("Reached last position in list for query");
      return new Container(
          alignment: Alignment.center,
          width: 20.0,
          child: new CircularProgressIndicator(
              valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3.0));
    }

    if (widget.videos.length > index) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RowAdapter.createRow(widget.videos[index], widget.mixin),
        ],
      );
    }
  }

  List<Widget> getAllChannelImages() {
    List<Widget> images = new List();
    Channels.channelMap.forEach((name, assetPath) {
      images.add(new Container(
        margin: new EdgeInsets.only(left: 2.0, top: 5.0),
        width: 50.0,
        height: 50.0,
        decoration: new BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300],
          image: new DecorationImage(
            image: new AssetImage('assets/img/' + assetPath),
          ),
        ),
      ));
    });
    return images;
  }
}
