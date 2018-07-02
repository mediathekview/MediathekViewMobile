import 'package:flutter/material.dart';
import 'package:flutter_ws/model/Video.dart';
import 'package:flutter_ws/util/textStyles.dart';
import 'package:flutter_ws/widgets/inherited/list_state_container.dart';
import 'package:flutter_ws/widgets/list/DownloadCardBody.dart';
import 'package:flutter_ws/widgets/list/channelThumbnail.dart';
import 'package:flutter_ws/widgets/list/videoPreviewAdapter.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

class ListCard extends StatefulWidget {
  final String imgPath;
  final Video video;

  ListCard({Key key, @required this.imgPath, @required this.video})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new _ListCardState();
  }

}

class _ListCardState extends State<ListCard> {

  BuildContext context;
  AppSharedState stateContainer;
  Widget iconBeschreibung;
  bool modalBottomScreenIsShown = false;

  @override
  Widget build(BuildContext context) {
    this.context = context;
    stateContainer = AppSharedStateContainer.of(context);
    VideoListState videoListState = stateContainer.videoListState;

    bool isExtendet = false;
    if (videoListState != null) {
      Set<String> extendetTiles = videoListState.extendetListTiles;
      isExtendet = extendetTiles.contains(widget.video.id);
    }
    Uuid uuid = new Uuid();

    final cardContent = new Container(
//      color: Colors.white,
      key: new Key(uuid.v1()),
      margin: new EdgeInsets.only(top: 12.0, bottom: 12.0),
//      constraints: new BoxConstraints.,
      child: new Column(
        key: new Key(uuid.v1()),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(key: new Key(uuid.v1()), height: 4.0),
          new Flexible(
            key: new Key(uuid.v1()),
            child: new Container(
              key: new Key(uuid.v1()),
              margin: new EdgeInsets.only(left: 40.0, right: 12.0),
              child: new Text(
                widget.video.topic,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme
                    .of(context)
                    .textTheme
                    .title
                    .copyWith(color: Colors.black),
              ),
            ),
          ),
          new Container(key: new Key(uuid.v1()), height: 10.0),
          new Flexible(
            key: new Key(uuid.v1()),
            child: new Container(
              key: new Key(uuid.v1()),
              margin: new EdgeInsets.only(left: 40.0, right: 12.0),
//              padding: new EdgeInsets.only(right: 13.0),
              child: new Text(
                widget.video.title,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: Theme
                    .of(context)
                    .textTheme
                    .subhead
                    .copyWith(color: Colors.black),
//                style: subHeaderTextStyle,
              ),
            ),
          ),
          isExtendet == true
              ? new Container(
              key: new Key(uuid.v1()),
              margin:
              new EdgeInsets.symmetric(vertical: 8.0, horizontal: 40.0),
              height: 2.0,
              color: Colors.grey)
              : new Container(
              key: new Key(uuid.v1()),
              padding: new EdgeInsets.only(left: 40.0, right: 12.0)),
          new Column(key: new Key(uuid.v1()), children: <Widget>[
            isExtendet == true
                ? new VideoPreviewAdapter(widget.video.id, video: widget.video, defaultImageAssetPath: widget.imgPath, showLoadingIndicator: false)
                : new Container(),
            //ContentRow is always visible but like a sandwich in the middle of the download switch and the progress bar
            new DownloadCardBody(widget.video),
          ]),
        ],
      ),
    );

    final card = new Container(
      child: cardContent,
      margin: new EdgeInsets.only(left: 20.0),
      decoration: new BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        boxShadow: <BoxShadow>[
          new BoxShadow(
            color: Colors.black12,
            blurRadius: 10.0,
            offset: new Offset(0.0, 10.0),
          ),
        ],
      ),
    );

    iconBeschreibung = new Container(
        alignment: FractionalOffset.topRight,
        child: new IconButton(
          icon: new Icon(Icons.info, color: new Color(0xffffbf00)),
          tooltip: 'Beschreibung',
          onPressed: () {
            if (modalBottomScreenIsShown) {
              Navigator.pop(context);
              modalBottomScreenIsShown = false;
            } else {
              showDescription();
              modalBottomScreenIsShown = true;
            }
          },
        ));

    return new Container(
      margin: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 8.0,
      ),
      child: new Stack(
        children: <Widget>[
          new GestureDetector(onTap: _handleTap, child: card),
          isExtendet ? new Container():new Positioned.fill(
            left: 20.0,
            child: new Material(
                color: Colors.transparent,
                child: new InkWell(onTap: _handleTap)
            ),
          ),
          iconBeschreibung,
          widget.imgPath.isNotEmpty ? new ChannelThumbnail(widget.imgPath) : new Container(),
        ],
      ),
    );
  }

  void _handleTap() {
    print("handle tab on tile");
    stateContainer.updateExtendetListTile(widget.video.id);
    //only rerender this tile, not the whole app state!
    setState(() {
    });
  }

  showDescription() {
    //TODO: fire synchronous http request "getDescription"
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return new Container(
          child: new Padding(
            padding: const EdgeInsets.only(
                left: 30.0, right: 30.0, top: 10.0, bottom: 20.0),
            child: new SingleChildScrollView(
              child: new Column(
                children: <Widget>[
                  iconBeschreibung,
                  new Text(widget.video.description,
                      textAlign: TextAlign.left,
                      style: subHeaderTextStyle.copyWith(color: Colors.black))
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}