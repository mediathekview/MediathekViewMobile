import 'package:flutter/material.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/util/row_adapter.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

typedef void ListTileTapped(String id);

class ScrollPositionHolder {
  double value = 0.0;
}

class VideoListView extends StatefulWidget {
  final Logger logger = new Logger('VideoListView');
  final int pageThreshold = 10;
  final int amountOfVideosToFetch = 60;
  final ScrollPositionHolder offset = new ScrollPositionHolder();

  List<Video> videos;
  var queryEntries;
  int amountOfVideosFetched;

  VideoListView({
    Key key,
    @required this.queryEntries,
    @required this.amountOfVideosFetched,
    @required this.videos,
  }) : super(key: key);

  double getOffsetMethod() {
    return offset.value;
  }

  void setOffsetMethod(double val) {
    offset.value = val;
  }

  @override
  _VideoListViewState createState() => _VideoListViewState();
}

class _VideoListViewState extends State<VideoListView> {
  ScrollController scrollController;

  @override
  void initState() {
    super.initState();

    if (widget.getOffsetMethod() != null) {
      widget.logger.fine(
          "Video List View get offset: " + widget.getOffsetMethod().toString());
      scrollController =
          new ScrollController(initialScrollOffset: widget.getOffsetMethod());
    } else {
      widget.logger.fine("Video List View: Not Setting scroll offset -> NULL");
      scrollController = new ScrollController();
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.logger.info("Rendering Main Video List with list length " +
        widget.videos.length.toString() +
        " & fetched: " +
        widget.amountOfVideosFetched.toString());

    if (widget.videos.length == 0 && widget.amountOfVideosFetched == 0) {
      widget.logger.fine("No Videos found");
      return new Container(child: new Text("keine Videos gefunden"));
    } else if (widget.videos.length == 0) {
      widget.logger.fine("Searching: video list legth : 0 & amountFetched: " +
          widget.amountOfVideosFetched.toString());
      return new Container(
        alignment: Alignment.center,
        child: new CircularProgressIndicator(
            valueColor:
                new AlwaysStoppedAnimation<Color>(new Color(0xffffbf00)),
            strokeWidth: 5.0,
            backgroundColor: Colors.white),
      );
    }

    return new ListView.builder(
        controller: scrollController,
        itemBuilder: itemBuilder,
        itemCount: widget.videos.length);
  }

  Widget itemBuilder(BuildContext context, int index) {
    if (Scrollable.of(context) != null &&
        Scrollable.of(context).position != null &&
        Scrollable.of(context).position.pixels != null)
      widget.setOffsetMethod(Scrollable.of(context).position.pixels);
    else
      widget.logger
          .severe("Video List View: Error could not set pixel position");

    if (index + widget.pageThreshold > widget.videos.length) {
      widget.queryEntries(index, widget.amountOfVideosToFetch);
    }

    if (widget.videos.length == index + 1 &&
        widget.amountOfVideosToFetch == widget.amountOfVideosFetched) {
      widget.logger.fine("Return progress indicator. Video list length is " +
          widget.videos.length.toString() +
          " and index is " +
          index.toString() +
          " Amount Fetched: " +
          widget.amountOfVideosFetched.toString());
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
          RowAdapter.createRow(widget.videos[index]),
        ],
      );
    }
  }
}
