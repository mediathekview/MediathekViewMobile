import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

class SearchFilter extends StatelessWidget {
  //E.g Thema/Titel
  String filterId;

  //Der Wert nachdem gefiltert wird
  String filterValue;
  var handleTabCallback;
  String displayText;

//  SearchFilter(this.filterId, this.text, this.handleTabCallback);

  SearchFilter(
      {Key key,
      @required this.filterId,
      @required this.filterValue,
      @required this.handleTabCallback,
      this.displayText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
//    double width = MediaQuery.of(context).size.width;

    return new Padding(
        padding: new EdgeInsets.only(left: 10.0),
        child: new GestureDetector(
          onTap: () {
            handleTabCallback(filterId);
          },
          child: new Container(
            height: 25.0,
//          constraints: new BoxConstraints(minWidth: 100, maxWidth: ),
            decoration: new BoxDecoration(
              color: Colors.grey[700],
              shape: BoxShape.rectangle,
              borderRadius: new BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.only(right: 5.0, left: 5.0),
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
//          new IconButton(iconSize: 18.0, disabledColor: Colors.black, alignment: Alignment.center, padding: const EdgeInsets.all(0.0), icon: new Icon(Icons.delete)),
                new Padding(
                  padding: new EdgeInsets.only(right: 5.0),
                  child:
                      new Icon(Icons.delete, size: 18.0, color: Colors.white),
                ),

                new Text(
                    displayText == null || displayText.isEmpty
                        ? filterId
                        : displayText,
                    style: Theme.of(context).textTheme.button,
                    textAlign: TextAlign.start,
                    maxLines: 1)
              ],
            ),
          ),
        ));
  }
}
