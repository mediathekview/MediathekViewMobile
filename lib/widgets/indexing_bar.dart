import 'package:flutter/material.dart';
import 'package:flutter_ws/model/indexing_info.dart';
import 'package:flutter_ws/util/text_styles.dart';
import 'package:flutter_ws/widgets/reuse/circular_progress_with_text.dart';
import 'package:meta/meta.dart';

class IndexingBar extends StatelessWidget {
  final IndexingInfo info;
  final bool indexingError;

  IndexingBar({Key key, @required this.info, @required this.indexingError})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("Rendering indexing Bar");

    if (!indexingError && info != null) {
      print("Currently indexing. Indexing progress: " +
          info.indexerProgress.toString());
      return new CircularProgressWithText(
          new Text("Update Video Datenbank", style: connectionLostTextStyle),
          new Color(0xffffbf00),
          Colors.white);
    } else if (indexingError) {
      //TODO show error icon & say server error - but you can still watch your Downloads
      print("Server Indexing error detected");
    }

    return new Container();
  }
}
