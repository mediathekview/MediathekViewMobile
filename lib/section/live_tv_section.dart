import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_ws/database/channel_favorite_entity.dart';
import 'package:flutter_ws/database/database_manager.dart';
import 'package:flutter_ws/platform_channels/video_manager.dart';
import 'package:flutter_ws/util/text_styles.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:logging/logging.dart';

class Channel {
  String name;
  String logo;
  String group;
  String url;

  Channel(this.name, this.logo, this.group, this.url);
}

typedef Widget ItemBuilder(BuildContext context, int index);

class LiveTVSection extends StatefulWidget {
  final Logger logger = new Logger('LiveTVSection');

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
  List<Channel> allChannels;
  List<Channel> localChannels;
  List<Channel> childChannels;
  List<Channel> newsChannels;

  @override
  void initState() {
    // Check Last Time updated

    //Insert into DB -> last time updated

    //  TODO load recent list https://github.com/jnk22/kodinerds-iptv/blob/master/iptv/kodi/kodi_tv.m3u
    nativeVideoPlayer = new NativeVideoPlayer();
    listData = new List();
    allChannels = new List();
    localChannels = new List();
    childChannels = new List();
    newsChannels = new List();

    //  if not available, use default list that i attached as file
    getFileData("assets/default_live_stream_channels.txt")
        .then((String fileData) {
      listData = fileData.split("#EXTINF:-1");
      listData.removeAt(0);
      widget.logger.fine("Found entries: " + listData.length.toString());

      //Create lists
      createSeperateLists(listData).then((x) {
        widget.logger.fine("finished creating lists: Alle: " +
            allChannels.length.toString() +
            " Kinder: " +
            childChannels.length.toString() +
            " Local: " +
            localChannels.length.toString() +
            " News: " +
            newsChannels.length.toString());

        allChannels.sort(
            (a, b) => a.name.toUpperCase().compareTo(b.name.toUpperCase()));
        childChannels.sort(
            (a, b) => a.name.toUpperCase().compareTo(b.name.toUpperCase()));
        localChannels.sort(
            (a, b) => a.name.toUpperCase().compareTo(b.name.toUpperCase()));
        newsChannels.sort(
            (a, b) => a.name.toUpperCase().compareTo(b.name.toUpperCase()));
        if (mounted) setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;

    appWideState = AppSharedStateContainer.of(context);
    favChannels = appWideState.appState.favoritChannels;
//    widget.logger.fine("Amount of Fav channels: " + favChannels.length.toString());
//    favChannels.forEach((string, channel) => widget.logger.fine("Saved Key: " + string));
    databaseManager = appWideState.appState.databaseManager;

    Widget allChannelsListView =
        buildListView(allChannels, itemBuilderAllChannels, true);
    Widget childChannelsListView =
        buildListView(childChannels, itemBuilderChildChannels, true);
    Widget localChannelsListView =
        buildListView(localChannels, itemBuilderLocalChannels, true);
    Widget newsChannelsListView =
        buildListView(newsChannels, itemBuilderNewsChannels, true);
    Widget favoriteChannelsListView = buildListView(
        favChannels.values.toList(), itemBuilderFavoriteChannels, false);

    PreferredSize tabbar = new PreferredSize(
      child: new TabBar(
        indicatorColor: Colors.white,
        tabs: <Widget>[
          new Tab(
              icon: new Icon(
                Icons.list,
              ),
              text: "Alle"),
          new Tab(
              icon: new Icon(
                Icons.favorite,
                color: Colors.red[900],
              ),
              text: "Meins"),
          new Tab(
              icon: new Icon(
                Icons.location_city,
              ),
              text: "Lokal"),
          new Tab(
              icon: new Icon(
                Icons.child_care,
              ),
              text: "Kinder"),
          new Tab(icon: new Icon(Icons.comment), text: "News"),
        ],
      ),
      preferredSize: new Size.fromHeight(40.0),
    );

    return new DefaultTabController(
      length: 5,
      child: new Scaffold(
        backgroundColor: Colors.grey[800],
        appBar: new AppBar(
          centerTitle: true,
          title: new Text('Live Tv'),
//            backgroundColor: new Color(0xffffbf00),
          elevation: 6.0,
          backgroundColor: Colors.grey[800],
          bottom: tabbar,
        ),
        body: new TabBarView(children: <Widget>[
          allChannelsListView,
          favoriteChannelsListView,
          localChannelsListView,
          childChannelsListView,
          newsChannelsListView
        ]),
      ),
    );
  }

  Column buildListView(List list, ItemBuilder builder, bool showLoading) {
    return new Column(
      children: <Widget>[
        list.isNotEmpty
            ? new Flexible(
                child: new ListView.builder(
                    itemBuilder: builder, itemCount: list.length),
              )
            : showLoading
                ? new Center(
                    child: new Container(
                      alignment: Alignment.center,
                      child: new CircularProgressIndicator(
                          valueColor: new AlwaysStoppedAnimation<Color>(
                              new Color(0xffffbf00)),
                          strokeWidth: 5.0,
                          backgroundColor: Colors.white),
                    ),
                  )
                : new Container(),
      ],
    );
  }

  Widget itemBuilderAllChannels(BuildContext context, int index) {
    Channel channel = allChannels[index];
//    widget.logger.fine("Item with index " + index.toString() + "  content: " + channel.name);
//    widget.logger.fine(channel.name + " : " + channel.logo);

    return getListTile(channel);
  }

  Widget itemBuilderFavoriteChannels(BuildContext context, int index) {
//    widget.logger.fine("Fav: TOTAlLength: " +
//        favChannels.length.toString() +
//        " Index: " +
//        index.toString());
    ChannelFavoriteEntity channelEntity = favChannels.values.toList()[index];
    Channel channel = new Channel(channelEntity.name, channelEntity.logo,
        channelEntity.groupname, channelEntity.url);
//    widget.logger.fine(channel.name + " : " + channel.logo);

    return getListTile(channel);
  }

  Widget itemBuilderChildChannels(BuildContext context, int index) {
    Channel channel = childChannels[index];
//    widget.logger.fine(channel.name + " : " + channel.logo);

    return getListTile(channel);
  }

  Widget itemBuilderLocalChannels(BuildContext context, int index) {
    Channel channel = localChannels[index];
//    widget.logger.fine(channel.name + " : " + channel.logo);
    return getListTile(channel);
  }

  Widget itemBuilderNewsChannels(BuildContext context, int index) {
    Channel channel = newsChannels[index];
    return getListTile(channel);
  }

  ListTile getListTile(Channel channel) {
    return new ListTile(
      onTap: () {
        nativeVideoPlayer.playLiveStream(channel);
      },
      trailing: favChannels[channel.name] == null
          ? new IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: () {
                _handleAddFavoriteChannel(channel);
              })
          : new IconButton(
              icon: new Icon(
                Icons.favorite,
                color: Colors.red[900],
              ),
              onPressed: () {
                _handleRemoveFavoriteChannel(channel.name);
              }),
      leading: new CircleAvatar(
        backgroundColor: Colors.grey,
        child: new Image.network(channel.logo),
      ),
      title: new Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          new Expanded(child: new Text(channel.name, style: body2TextStyle)),
        ],
      ),
    );
  }

  Future<String> getFileData(String path) async {
    return await rootBundle.loadString(path);
  }

  Future<void> createSeperateLists(List<String> split) async {
    split.forEach((line) {
      //Split at ","
      List<String> splits = line.split(",");
      if (splits.length < 2) {
        return Container();
      }
      //Get part right of ","
      String secondSplit = splits[1];
      // get index of url begin
      int urlBegin = secondSplit.indexOf("http");

      String url = secondSplit.substring(urlBegin);
      String senderName = getM3u8Value("tvg-name", line);
      String groupTitle = getM3u8Value("group-title", line);
      String logo = getM3u8Value("tvg-logo", line);

      //add to individual channel list
      Channel channel = new Channel(senderName, logo, groupTitle, url);
      addToIndividualChannelList(channel);
    });

    return null;
  }

  String getM3u8Value(String id, String line) {
    int indexOfId = line.indexOf(id);
    int indexEquals = indexOfId + id.length + 2;
    int endIndex = line.indexOf("\"", indexEquals);
    return line.substring(indexEquals, endIndex);
  }

  void _handleAddFavoriteChannel(Channel channel) {
    widget.logger.fine("Pressed favourite");
    ChannelFavoriteEntity entity = new ChannelFavoriteEntity(
        channel.name, channel.logo, channel.group, channel.url);
    databaseManager.insertChannelFavorite(entity).then((dynamic) {
      widget.logger.fine("added favorite CHannel to DB");
      setState(() {
        appWideState.appState.favoritChannels
            .putIfAbsent(channel.name, () => entity);
      });
    });
  }

  void _handleRemoveFavoriteChannel(String senderName) {
    widget.logger.fine("Pressed remove favourite");
    databaseManager.deleteChannelFavorite(senderName).then((dynamic) {
      widget.logger.fine("removed favorite Channel from DB");
      setState(() {
        appWideState.appState.favoritChannels.remove(senderName);
      });
    });
  }

  void addToIndividualChannelList(Channel channel) {
    String group = channel.group;

    if (group == "Lokal" || group == "Regional") {
      localChannels.add(channel);
    } else if (group == "Vollprogramm") {
      allChannels.add(channel);
    } else if (group.contains("Kinder")) {
      childChannels.add(channel);
    } else if (group.contains("Nachrichten")) {
      newsChannels.add(channel);
    } else {
      allChannels.add(channel);
    }
  }
}
