import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Heading extends StatelessWidget {
  String heading;
  double fontSize;
  double paddingLeft;
  double paddingTop;
  double paddingBottom;

  Heading(this.heading, this.fontSize, this.paddingLeft, this.paddingTop,
      this.paddingBottom);

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.only(
          left: paddingLeft, top: paddingTop, bottom: paddingBottom),
      sliver: new SliverList(
        delegate: new SliverChildListDelegate(
          [
            new Text(
              heading,
              style: new TextStyle(
                  fontSize: fontSize,
                  color: Colors.white,
                  fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
