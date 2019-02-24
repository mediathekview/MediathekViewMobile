import 'package:flutter/material.dart';

class CircularProgressWithText extends StatelessWidget {
  final Text text;
  final Color containerColor;
  final Color indicatorColor;
  final double height;

  CircularProgressWithText(this.text, this.containerColor, this.indicatorColor,
      {this.height});

  @override
  Widget build(BuildContext context) {
    if (this.height != null) {
      return getWithFixedHeight();
    }
    return getExpandable();
  }

  Widget getWithFixedHeight() {
    return new Center(
      child: new Container(
        height: this.height,
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

  Widget getExpandable() {
    return new Container(
      color: containerColor,
      child: new Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: new Center(
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new Container(
                constraints: BoxConstraints.tight(Size.square(13.0)),
                child: new CircularProgressIndicator(
                  valueColor: new AlwaysStoppedAnimation<Color>(indicatorColor),
                  strokeWidth: 2.0,
                  backgroundColor: Colors.white,
                ),
              ),
              new Container(
                width: 10,
              ),
              new Flexible(
                child: new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[text],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
