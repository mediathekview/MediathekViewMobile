import 'package:flutter/material.dart';
import 'package:flutter_ws/database/video_progress_entity.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/util/text_styles.dart';
import 'package:flutter_ws/widgets/overviewSection/util.dart';
import 'package:logging/logging.dart';

class WatchHistory extends StatefulWidget {
  final Logger logger = new Logger('WatchHistory');

  @override
  WatchHistoryState createState() {
    return new WatchHistoryState();
  }
}

class WatchHistoryState extends State<WatchHistory> {
  Set<VideoProgressEntity> history;
  AppState appState;

  @override
  Widget build(BuildContext context) {
    appState = AppSharedStateContainer.of(context).appState;
    Size size = MediaQuery.of(context).size;
    loadWatchHistory();

    if (history == null) {
      return new Container(
        width: size.width,
        height: size.width / 16 * 9,
        child: new Center(
          child: new CircularProgressIndicator(
            valueColor: new AlwaysStoppedAnimation<Color>(Colors.red),
            strokeWidth: 2.0,
            backgroundColor: Colors.white,
          ),
        ),
      );
    }

    List<Widget> watchHistoryWidgets = getHistoryList(size);

    return new Scaffold(
      backgroundColor: Colors.grey[800],
      body: new Column(
        children: <Widget>[
          new AppBar(
            title: new Text('Watch History', style: sectionHeadingTextStyle),
            backgroundColor: new Color(0xffffbf00),
            leading: new IconButton(
              icon: new Icon(Icons.arrow_back, size: 30.0, color: Colors.white),
              onPressed: () {
                //return channels when user pressed back
                return Navigator.pop(context);
              },
            ),
          ),
          new Flexible(
            child: new ListView(children: watchHistoryWidgets),
          ),
        ],
      ),
    );
  }

  List<Widget> getHistoryList(Size size) {
    Map<int, bool> sync = new Map();
    List<Widget> watchHistoryWidgets = new List();
    history.forEach((progress) {
      DateTime videoWatchDate =
          new DateTime.fromMillisecondsSinceEpoch(progress.timestampLastViewed);
      if (videoWatchDate == null) {
        return;
      }
      Duration differenceToToday =
          new DateTime.now().difference(videoWatchDate);
      var daysPassedSinceVideoWatched = differenceToToday.inDays;

      Widget historyItem = Util.getWatchHistoryItem(progress, size.width);
      // add bottom padding
      historyItem = new Padding(
          padding: EdgeInsets.only(bottom: 13.0), child: historyItem);

      if (sync[daysPassedSinceVideoWatched] != null) {
        watchHistoryWidgets.add(historyItem);
        return;
      }
      sync.putIfAbsent(daysPassedSinceVideoWatched, () => true);

      // add time as item before that in the list
      String heading =
          getWatchHistoryHeading(daysPassedSinceVideoWatched, videoWatchDate);
      watchHistoryWidgets.add(new Padding(
          padding: EdgeInsets.only(left: 10.0, bottom: 10.0, top: 5),
          child: new Text(
            heading,
            style: new TextStyle(
                color: Colors.white,
                fontSize: 25.0,
                fontWeight: FontWeight.w700),
          )));
      watchHistoryWidgets.add(historyItem);
    });
    return watchHistoryWidgets;
  }

  String getWatchHistoryHeading(
      int daysPassedSinceVideoWatched, DateTime videoWatchDate) {
    // add time as item before that in the list
    if (daysPassedSinceVideoWatched == 0) {
      //today
      return "Heute";
    } else if (daysPassedSinceVideoWatched == 1) {
      // yesterday
      return "Gestern";
    } else if (daysPassedSinceVideoWatched < 8) {
      // use weekdays
      String weekday = getWeekday(videoWatchDate.weekday);
      return weekday;
    } else {
      String watchDay;
      String watchMonth;
      if (videoWatchDate.day < 10) {
        watchDay = "0" + videoWatchDate.day.toString();
      } else {
        watchDay = videoWatchDate.day.toString();
      }

      if (videoWatchDate.month < 10) {
        watchMonth = "0" + videoWatchDate.month.toString();
      } else {
        watchMonth = videoWatchDate.month.toString();
      }
      if (daysPassedSinceVideoWatched < 365) {
        return watchDay + "." + watchMonth;
      } else {
        //add year
        return watchDay +
            "." +
            watchMonth +
            "." +
            videoWatchDate.year.toString();
      }
    }
  }

  Future loadWatchHistory() async {
    //check for playback progress
    if (history == null || history.isEmpty) {
      return appState.databaseManager.getAllLastViewedVideos().then((all) {
        if (all != null && all.isNotEmpty) {
          history = all;
          setState(() {});
        }
        return;
      });
    }
  }

  String getWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return "Montag";
        break;
      case 2:
        return "Dienstag";
        break;
      case 3:
        return "Mittwoch";
        break;
      case 4:
        return "Donnerstag";
        break;
      case 5:
        return "Freitag";
        break;
      case 6:
        return "Samstag";
        break;
      case 7:
        return "Sonntag";
        break;
    }
  }
}
