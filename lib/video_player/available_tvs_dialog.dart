import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/widgets/videolist/circular_progress_with_text.dart';
import 'package:logging/logging.dart';

import 'TVPlayerController.dart';

class AvailableTVsDialog extends StatefulWidget {
  TvPlayerController tvPlayerController;

  AvailableTVsDialog(this.tvPlayerController);

  @override
  State<StatefulWidget> createState() {
    return new _AvailableTVsDialogState();
  }
}

class _AvailableTVsDialogState extends State<AvailableTVsDialog> {
  AppSharedState _appWideState;
  final Logger logger = new Logger('_AvailableTVsDialog');
  VoidCallback listener;

  _AvailableTVsDialogState() {
    listener = () {
      setState(() {});
    };
  }
  @override
  void initState() {
    super.initState();
    // react on value changes (e.g position) on both the flutter as well as the Tv player
    tvPlayerController.addListener(listener);
  }

  @override
  void deactivate() {
    tvPlayerController.removeListener(listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    _appWideState = AppSharedStateContainer.of(context);

    var availableTVs = tvPlayerController.value.availableTvs
        .map((tv) => new SimpleDialogOption(
              child: new Text(tv,
                  style: new TextStyle(color: Colors.white, fontSize: 18.0)),
              onPressed: () {
                logger.info("Connecting to Samsung TV" + tv);

                // initialize tvPlayer controller
                if (!widget.tvPlayerController
                    .isListeningToPlatformChannels()) {
                  widget.tvPlayerController.initialize();
                }

                _appWideState.appState.samsungTVCastManager
                    .checkIfTvIsSupported(tv);
                Navigator.pop(context, true);
              },
            ))
        .toList();
    if (tvPlayerController.value.playbackOnTvStarted) {
      availableTVs.add(new SimpleDialogOption(
        child: new RaisedButton(
          child: new Text("Verbindung trennen",
              style: new TextStyle(color: Colors.white, fontSize: 20.0)),
          color: Color(0xffffbf00),
          onPressed: () {
            tvPlayerController.disconnect();
            Navigator.pop(context, true);
          },
        ),
      ));
    }

    return new AlertDialog(
      backgroundColor: Colors.grey[800],
      title: new CircularProgressWithText(
        new Text(
          "Verfügbare Fernseher",
          style: new TextStyle(color: Colors.white, fontSize: 20.0),
          softWrap: true,
          maxLines: 2,
        ),
        Colors.grey[800],
        new Color(0xffffbf00),
      ),
      content: new SingleChildScrollView(
        child: new Column(
          children: availableTVs,
        ),
      ),
    );
  }

  TvPlayerController get tvPlayerController => widget.tvPlayerController;
}
