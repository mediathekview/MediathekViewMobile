import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_ws/manager/databaseManager.dart';
import 'package:flutter_ws/manager/nativeVideoManager.dart';
import 'package:flutter_ws/model/ChannelFavoriteEntity.dart';
import 'package:flutter_ws/util/textStyles.dart';
import 'package:flutter_ws/widgets/inherited/list_state_container.dart';

class LiveTVSection extends StatefulWidget {
  @override
  _LiveTVSectionState createState() => _LiveTVSectionState();
}

class _LiveTVSectionState extends State<LiveTVSection> {
  Size size;
  List<String> listData;
  NativeVideoPlayer nativeVideoPlayer;
  Map<String, ChannelFavoriteEntity> favChannels;
  DatabaseManager databaseManager;
  AppSharedState appWideState;

  @override
  void initState() {
    // Check Last Time updated

    //Insert into DB -> last time updated

    //  TODO load recent list https://github.com/jnk22/kodinerds-iptv/blob/master/iptv/kodi/kodi_tv.m3u
    nativeVideoPlayer = new NativeVideoPlayer();
    listData = new List();
    //  if not available, use default list that i attached as file
    getFileData("assets/default_live_stream_channels.txt")
        .then((String fileData) {
      setState(() {
        listData = fileData.split("#EXTINF:-1");
        listData.removeAt(0);
      });

      print("Found entries: " + listData.length.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;

    appWideState = AppSharedStateContainer.of(context);
    favChannels = appWideState.appState.favoritChannels;
    print("Amount of Fav channels: " + favChannels.length.toString());
    favChannels.forEach((string, channel) => print("Saved Key: " + string));
    databaseManager = appWideState.appState.databaseManager;

    return new Scaffold(
      backgroundColor: Colors.grey[800],
      body: new Column(
        children: <Widget>[
          new AppBar(
              title: new Text('LiveTV', style: sectionHeadingTextStyle),
              backgroundColor: new Color(0xffffbf00)),
          listData.isNotEmpty
              ? new Flexible(
                  child: new ListView.builder(
                      itemBuilder: itemBuilder, itemCount: listData.length),
                )
              : new Container(
                  alignment: Alignment.center,
                  child: new CircularProgressIndicator(
                      valueColor: new AlwaysStoppedAnimation<Color>(
                          new Color(0xffffbf00)),
                      strokeWidth: 5.0,
                      backgroundColor: Colors.white),
                ),
        ],
      ),
    );
  }

  Widget itemBuilder(BuildContext context, int index) {
    String line = listData[index];
    if (line.startsWith("http")) {
      return Container();
    }
    print("Item with index " +
        index.toString() +
        "  content: " +
        listData[index].toString());

    List<String> splits = line.split(",");

    if (splits.length < 2) {
      return Container();
    }

    String secondSplit = splits[1];
    int urlBegin = secondSplit.indexOf("http");
    String url = secondSplit.substring(urlBegin);

    String senderName = getM3u8Value("tvg-name", line);
    String groupTitle = getM3u8Value("group-title", line);
    String logo = getM3u8Value("tvg-logo", line);

    return new ListTile(
        onTap: () {
          nativeVideoPlayer.playVideo(url);
        },
        trailing: favChannels[senderName] == null
            ? new IconButton(
                icon: new Icon(Icons.favorite_border),
                onPressed: () {
                  _handleAddFavoriteChannel(senderName, groupTitle, logo, url);
                })
            : new IconButton(
                icon: new Icon(
                  Icons.favorite,
                  color: Colors.red[900],
                ),
                onPressed: () {
                  _handleRemoveFavoriteChannel(
                      senderName, groupTitle, logo, url);
                }),
        leading: new CircleAvatar(
          backgroundColor: Colors.grey,
          child: new Image.network(logo),
        ),
        title: new Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            new Expanded(child: new Text(senderName, style: body2TextStyle)),
          ],
        ));
  }

  Future<String> getFileData(String path) async {
    return await rootBundle.loadString(path);
  }

  String getM3u8Value(String id, String line) {
    print(id);
    int indexOfId = line.indexOf(id);
    int indexEquals = indexOfId + id.length + 2;
    int endIndex = line.indexOf("\"", indexEquals);
//    print("Index of Id:" + indexOfId.toString() + " Equals:" + indexEquals.toString() + " End" + endIndex.toString());
    String sub = line.substring(indexEquals, endIndex);
//    print("Result " + sub);
    return sub;
  }

  void _handleAddFavoriteChannel(
      String senderName, String groupTitle, String logo, String url) {
    print("Pressed favourite");
    ChannelFavoriteEntity entity =
        new ChannelFavoriteEntity(senderName, logo, groupTitle, url);
    databaseManager.insertChannelFavorite(entity).then((dynamic) {
      print("added favorite CHannel to DB");
      //TODO only trigger reload of sigle tile
      setState(() {
        appWideState.appState.favoritChannels
            .putIfAbsent(senderName, () => entity);
      });
    });
  }

  void _handleRemoveFavoriteChannel(
      String senderName, String groupTitle, String logo, String url) {
    print("Pressed remove favourite");
    databaseManager.deleteChannelFavorite(senderName).then((dynamic) {
      print("removed favorite Channel from DB");
      //TODO only trigger reload of sigle tile
      setState(() {
        appWideState.appState.favoritChannels.remove(senderName);
      });
    });
  }
}
