import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

class SearchFilter extends StatelessWidget {
  //E.g Thema/Titel
  String filterId;

  //Der Wert nachdem gefiltert wird
  String filterValue;
  var handleTabCallback;
  String displayText;

  SearchFilter(
      {Key key,
      @required this.filterId,
      @required this.filterValue,
      @required this.handleTabCallback,
      this.displayText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Padding(
        padding: new EdgeInsets.only(left: 10.0, top: 2.0),
        child: new GestureDetector(
          onTap: () {
            handleTabCallback(filterId);
          },
          child: new Container(
            height: 25.0,
            decoration: new BoxDecoration(
              color: Colors.black,
              shape: BoxShape.rectangle,
              borderRadius: new BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.only(right: 5.0, left: 5.0),
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                new Padding(
                  padding: new EdgeInsets.only(right: 5.0),
                  child: new Icon(Icons.clear, size: 22.0, color: Colors.red),
                ),
                new Text(
                    displayText == null || displayText.isEmpty
                        ? filterId
                        : displayText,
                    style: new TextStyle(
                        fontSize: 12.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.start,
                    maxLines: 1)
              ],
            ),
          ),
        ));
  }
}
