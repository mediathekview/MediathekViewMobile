import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingListPage extends StatelessWidget {
  int determineNumberOfNeededTilesToFillScreen(
      BuildContext context, double listRowHeight) {
    double height = MediaQuery.of(context).size.height;
    // not filling whole available space
    return (height / listRowHeight).floor() - 1;
  }

  @override
  Widget build(BuildContext context) {
    Widget loadingCard = getLoadingCard();
    int num = determineNumberOfNeededTilesToFillScreen(context, 130);
    List<int> children = new List(num);

    return new SingleChildScrollView(
      child: new Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .map(
              (_) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      loadingCard,
                    ],
                  ),
            )
            .toList(),
      ),
    );
  }

  //Basically a visual replication of a list card from list_card.dart to show while the data for the video list is loading
  Widget getLoadingCard() {
    final cardContent = getCardContent();
    final card = getListCard(cardContent);
    Widget dummyChannelThumbnail = getDummyChannelThumbnail();

    return new Container(
      margin: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 8.0,
      ),
      child: new Stack(
        children: <Widget>[card, dummyChannelThumbnail],
      ),
    );
  }

  Container getCardContent() {
    return new Container(
      margin: new EdgeInsets.only(top: 12.0, bottom: 12.0),
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(height: 4.0),
          new Flexible(
            child: new Container(
              margin: new EdgeInsets.only(left: 40.0, right: 12.0),
              child: new Text(
                "Dummy Text",
              ),
            ),
          ),
          new Container(height: 10.0),
          new Flexible(
            child: new Container(
              margin: new EdgeInsets.only(left: 40.0, right: 12.0),
              child: new Text("Long Video Title"),
            ),
          ),
          new Container(padding: new EdgeInsets.only(left: 40.0, right: 12.0)),
          new Container(height: 20.0),
        ],
      ),
    );
  }

  Shimmer getListCard(Container cardContent) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300],
      highlightColor: Colors.grey[100],
      child: new Container(
        child: cardContent,
        margin: new EdgeInsets.only(left: 20.0),
        decoration: new BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
        ),
      ),
    );
  }

  Container getDummyChannelThumbnail() {
    return new Container(
      margin: new EdgeInsets.only(left: 2.0, top: 5.0),
      alignment: FractionalOffset.topLeft,
      width: 50.0,
      height: 50.0,
      decoration: new BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey,
      ),
    );
  }
}
