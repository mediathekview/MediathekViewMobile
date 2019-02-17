import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ChannelThumbnail extends StatelessWidget {
  final String imgPath;
  final bool isDownloadedAlready;

  ChannelThumbnail(this.imgPath, this.isDownloadedAlready);

  @override
  Widget build(BuildContext context) {
    Uuid uuid = new Uuid();

    return new Container(
      key: new Key(uuid.v1()),
      margin: new EdgeInsets.only(left: 2.0, top: 5.0),
      alignment: FractionalOffset.topLeft,
      width: 50.0,
      height: 50.0,
      decoration: new BoxDecoration(
        shape: BoxShape.circle,
        color: isDownloadedAlready ? Colors.green[800] : Colors.grey[300],
        image: new DecorationImage(
          image: new AssetImage('assets/img/' + imgPath),
        ),
      ),
    );
  }
}
