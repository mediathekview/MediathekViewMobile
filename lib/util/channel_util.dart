import 'package:flutter/material.dart';
import 'package:flutter_ws/enum/channels.dart';

class ChannelUtil {
  static List<Widget> getAllChannelImages() {
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
