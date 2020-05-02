import 'package:flutter/material.dart';
import 'package:flutter_ws/model/channel.dart';
import 'package:flutter_ws/util/text_styles.dart';

class ChannelListTile extends StatefulWidget {
  final Channel channel;

  ChannelListTile(Channel product)
      : channel = product,
        super(key: new ObjectKey(product));

  @override
  ChannelListTileState createState() {
    return new ChannelListTileState(channel);
  }
}

class ChannelListTileState extends State<ChannelListTile> {
  final Channel channel;

  ChannelListTileState(this.channel);

  @override
  Widget build(BuildContext context) {
    return new ListTile(
        onTap: () {
          setState(() {
            channel.isCheck = !channel.isCheck;
          });
        },
        leading: new CircleAvatar(
          backgroundColor: Colors.grey,
          child: new Image(
              image: new AssetImage("assets/img/" + channel.avatarImage)),
        ),
        title: new Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            new Expanded(child: new Text(channel.name, style: body2TextStyle)),
            new Checkbox(
                value: channel.isCheck,
                activeColor: Colors.grey[800],
                onChanged: (bool value) {
                  setState(() {
                    channel.isCheck = value;
                  });
                })
          ],
        ));
  }
}
