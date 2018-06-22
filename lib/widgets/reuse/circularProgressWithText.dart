import 'package:flutter/material.dart';

class CircularProgressWithText extends StatelessWidget {
  final Text text;
  final Color containerColor;
  final Color indicatorColor;

  CircularProgressWithText(this.text, this.containerColor, this.indicatorColor);

  @override
  Widget build(BuildContext context) {
    return new Center(
      child: new Container(
        height: 40.0,
        color: containerColor,
        child: new Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              text,
              new Container(width: 8.0),
              new Container(
                constraints: BoxConstraints.tight(Size.square(13.0)),
                child: new CircularProgressIndicator(
                  valueColor: new AlwaysStoppedAnimation<Color>(indicatorColor),
                  strokeWidth: 2.0,
                  backgroundColor: Colors.white,
                ),
              ),
            ]),
      ),
    );
  }
}
