import 'package:flutter/material.dart';
import 'package:flutter_ws/util/textStyles.dart';
import 'package:meta/meta.dart';

class FilterMenuChannelEditButton extends StatelessWidget {
  //E.g Thema/Titel
  final Icon icon;
  var handleTabCallback;
  final String displayText;

  FilterMenuChannelEditButton(
      {Key key,
      @required this.icon,
      @required this.handleTabCallback,
      this.displayText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Container(
        height: 35.0,
        child: new RaisedButton(
          color: Colors.grey[700],
          shape: RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(8.0)),
          onPressed: () {
            handleTabCallback(context);
          },
          elevation: 6.0,
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
//          new IconButton(iconSize: 18.0, disabledColor: Colors.black, alignment: Alignment.center, padding: const EdgeInsets.all(0.0), icon: new Icon(Icons.delete)),
              new Padding(
                padding: new EdgeInsets.only(right: 5.0),
                child: new Icon(Icons.edit, size: 25.0, color: Colors.white),
              ),
              new Text(displayText,
                  style: Theme.of(context).textTheme.button,
                  textAlign: TextAlign.start,
                  maxLines: 1)
            ],
          ),
        ));
  }
}
