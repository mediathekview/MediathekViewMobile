import 'dart:async';
import 'dart:ui' as ui show Image;

import 'package:flutter/material.dart';
import 'package:flutter_ws/manager/nativeVideoManager.dart';

class LiveTVSection extends StatelessWidget {
  Size size;

  @override
  Widget build(BuildContext context) {
     size = MediaQuery
        .of(context)
        .size;
    return new GridView.count(
        padding: const EdgeInsets.all(4.0),
      childAspectRatio: size.height * 1.5 / size.width,

        crossAxisCount: 1,
        mainAxisSpacing: 1.0,
//        crossAxisSpacing: 2.0,
        children: getGridTiles());
//    return new Center(child: new Icon(Icons.image, size: 150.0, color: Colors.red),);
  }

  List<Widget> getGridTiles() {
    List<Widget> tiles = new List();
    tiles.add(getTile("assets/imgLiveStream/ARD_LIVE.jpg", "http://daserste_live-lh.akamaihd.net/i/daserste_de@91204/master.m3u8"));
    tiles.add(getTile("assets/imgLiveStream/NDR_LIVE.jpg", "https://ndrfs-lh.akamaihd.net/i/ndrfs_nds@430233/master.m3u8"));
    tiles.add(getTile("assets/imgLiveStream/ZDF_LIVE.png", "https://zdf1314-lh.akamaihd.net/i/de14_v1@392878/master.m3u8"));
    tiles.add(getTile("assets/imgLiveStream/ZDF_LIVE.png", "http://wdrfsgeo-lh.akamaihd.net/i/wdrfs_geogeblockt@530016/master.m3u8"));
    return tiles;
  }

  Widget getTile(String assetPath, String liveStreamUrl) {
    return new GridTile(
      child: new Card(
        child: new Stack(
          children: <Widget>[
            new Positioned.fill(
              child: new Image.asset(
                  assetPath, fit: BoxFit.fitWidth, width: size.width,),
            ),
      new Positioned.fill(child: new Material(
        color: Colors.transparent,
        child: new InkWell(onTap: () {_handleTap(liveStreamUrl);}),),),
          ],),),);
  }

  void _handleTap(String url) {
    print("play");
    NativeVideoPlayer nativeVideoPlayer = new NativeVideoPlayer();
    nativeVideoPlayer.playVideo(url);
  }
}
