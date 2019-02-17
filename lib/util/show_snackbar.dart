import 'package:flutter/material.dart';

class SnackbarActions {
  static void showError(BuildContext context, String msg) {
    Scaffold.of(context).showSnackBar(
      new SnackBar(
        backgroundColor: Colors.red,
        content: new Text(msg),
      ),
    );
  }

  static void showErrorWithTryAgain(BuildContext context, String errorMsg,
      String tryAgainMsg, dynamic onTryAgainPressed, String videoId) {
    Scaffold.of(context).showSnackBar(
      new SnackBar(
        backgroundColor: Colors.red,
        content: new Text(errorMsg),
        action: new SnackBarAction(
          label: tryAgainMsg,
          onPressed: () {
            Scaffold.of(context).hideCurrentSnackBar();
            onTryAgainPressed(videoId);
          },
        ),
      ),
    );
  }
}
