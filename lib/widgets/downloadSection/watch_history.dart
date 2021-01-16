import 'package:flutter/material.dart';
import 'package:flutter_ws/database/video_progress_entity.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/util/device_information.dart';
import 'package:flutter_ws/util/text_styles.dart';
import 'package:flutter_ws/widgets/downloadSection/util.dart';
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
    var orientation = MediaQuery.of(context).orientation;

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

    List<Widget> watchHistoryWidgets;
    if (DeviceInformation.isTablet(context)) {
      watchHistoryWidgets = getHistoryGridList(
          size.width, (orientation == Orientation.portrait) ? 2 : 3);
    } else {
      watchHistoryWidgets = getHistoryGridList(
          size.width, orientation == Orientation.portrait ? 1 : 2);
    }

    var sliverAppBar = new SliverAppBar(
      title: new Text('Watch History', style: sectionHeadingTextStyle),
      backgroundColor: new Color(0xffffbf00),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back, size: 30.0, color: Colors.white),
        onPressed: () {
          //return channels when user pressed back
          return Navigator.pop(context);
        },
      ),
    );

    // add App bar on top
    watchHistoryWidgets.insert(0, sliverAppBar);

    return new Scaffold(
      backgroundColor: Colors.grey[800],
      body: new SafeArea(
        child: CustomScrollView(slivers: watchHistoryWidgets),
      ),
    );
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

  List<Widget> getHistoryGridList(double width, int crossAxisCount) {
    Map<int, MapEntry<VideoProgressEntity, List<Widget>>> watchHistoryItems =
        new Map();
    for (int i = 0; i < history.length; i++) {
      VideoProgressEntity progress = history.elementAt(i);

      int daysPassedSinceVideoWatched;
      try {
        daysPassedSinceVideoWatched =
            getDaysSinceVideoWatched(progress.timestampLastViewed);
      } on Exception catch (e) {
        continue;
      }

      Widget historyItem = Util.getWatchHistoryItem(progress, width);

      if (watchHistoryItems[daysPassedSinceVideoWatched] == null) {
        List<Widget> itemList = new List();
        itemList.add(historyItem);

        watchHistoryItems[daysPassedSinceVideoWatched] =
            new MapEntry(progress, itemList);
      } else {
        watchHistoryItems[daysPassedSinceVideoWatched].value.add(historyItem);
      }
    }

    // now for each day group create a grid
    List<Widget> resultList = new List();

    watchHistoryItems.entries.forEach((entry) {
      String heading = getWatchHistoryHeading(
          entry.key,
          new DateTime.fromMillisecondsSinceEpoch(
              entry.value.key.timestampLastViewed));

      resultList.add(
        SliverToBoxAdapter(
          child: new Padding(
            padding: EdgeInsets.only(left: 10.0, bottom: 10.0, top: 5),
            child: new Text(
              heading,
              style: new TextStyle(
                  color: Colors.white,
                  fontSize: 25.0,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
      resultList.add(
        new SliverPadding(
          padding: EdgeInsets.only(left: 10.0, right: 10.0),
          sliver: SliverGrid.count(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 16 / 9,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
            children: entry.value.value,
          ),
        ),
      );
    });

    return resultList;
  }

  int getDaysSinceVideoWatched(int timestampLastViewed) {
    DateTime videoWatchDate =
        new DateTime.fromMillisecondsSinceEpoch(timestampLastViewed);
    if (videoWatchDate == null) {
      throw new Exception();
    }
    Duration differenceToToday = new DateTime.now().difference(videoWatchDate);
    return differenceToToday.inDays;
  }
}
