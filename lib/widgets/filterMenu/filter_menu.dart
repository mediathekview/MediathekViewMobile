import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ws/widgets/filterMenu/channel_picker.dart';
import 'package:flutter_ws/widgets/filterMenu/filtermenu_channel_edit_button.dart';
import 'package:flutter_ws/widgets/filterMenu/search_filter.dart';
import 'package:flutter_ws/widgets/filterMenu/video_length_slider.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

class FilterMenu extends StatelessWidget {
  final Logger logger = new Logger('FilterMenu');
  var onFilterUpdated;
  var onSingleFilterTapped;
  var onChannelsSelected;
  Map<String, SearchFilter> searchFilters;
  ThemeData theme;

  FilterMenu(
      {Key key,
      @required this.onFilterUpdated,
      @required this.searchFilters,
      @required this.onSingleFilterTapped,
      @required this.onChannelsSelected})
      : super(key: key);

  TextEditingController _titleFieldController;
  TextEditingController _themaFieldController;

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    logger.fine("Rendering filter Menu");
    _titleFieldController = searchFilters.containsKey('Titel')
        ? new TextEditingController(text: searchFilters['Titel'].filterValue)
        : new TextEditingController();

    _themaFieldController = searchFilters.containsKey('Thema')
        ? new TextEditingController(text: searchFilters['Thema'].filterValue)
        : new TextEditingController();

    return new Container(
      decoration: new BoxDecoration(
        color: Color(0xffffbf00),
      ),
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          getFilterMenuRow("Thema", "Thema", _themaFieldController),
          getFilterMenuRow("Titel", "Titel", _titleFieldController),
          getChannelRow(context),
          getRangeSliderRow(),
        ],
      ),
    );
  }

  Row getChannelRow(BuildContext context) {
    return new Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
//            crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        new Container(
            width: 80.0,
            child: new Padding(
                padding: new EdgeInsets.only(right: 15.0),
                child: new Text(
                  "Sender",
                  style: new TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.start,
                ))),
        searchFilters["Sender"] == null ||
                searchFilters["Sender"].filterValue.isEmpty
            ? new Switch(
                value: false,
                onChanged: (bool isEnabled) {
                  if (isEnabled) {
                    logger.fine("User enabled channel switch");
                    _openAddEntryDialog(context);
                  }
                })
            : new FilterMenuChannelEditButton(
                handleTabCallback: _openAddEntryDialog,
                icon: new Icon(Icons.edit, size: 50.0),
                displayText: "Sender"),
      ],
    );
  }

  handleTapOnFilter(String id) {
    logger.fine("Filter with id " + id.toString() + " was tapped");
    onSingleFilterTapped(id);
  }

  Widget getFilterMenuRow(
      String filterId, String displayText, TextEditingController controller) {
    var _filterTextFocus = new FocusNode();

    Row row = new Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        new Container(
          width: 80.0,
          child: new Padding(
            padding: new EdgeInsets.only(right: 15.0),
            child: new Text(
              displayText,
              style: new TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.start,
            ),
          ),
        ),
        new Expanded(
          child: new TextField(
            focusNode: _filterTextFocus,
            onSubmitted: (String value) {
              onFilterUpdated(
                new SearchFilter(
                    filterId: filterId,
                    filterValue: value,
                    handleTabCallback: handleTapOnFilter),
              );
            },
            style: new TextStyle(
                color: Colors.white,
                fontSize: 20.0,
                fontWeight: FontWeight.w700),
            controller: controller,
            decoration: new InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              contentPadding: new EdgeInsets.only(bottom: 0.0),
//              counterStyle: buttonTextStyle,
              hintStyle: theme.textTheme.display1,
            ),
          ),
        ),
      ],
    );

    _filterTextFocus.addListener(() {
      if (!_filterTextFocus.hasFocus) {
        String currentValueOfFilter = controller.text;
        onFilterUpdated(
          new SearchFilter(
              filterId: filterId,
              filterValue: currentValueOfFilter,
              handleTabCallback: handleTapOnFilter),
        );
      }
    });

    return new Padding(padding: new EdgeInsets.only(bottom: 10.0), child: row);
  }

  Future _openAddEntryDialog(BuildContext context) async {
    Set<String> channelSelection =
        await Navigator.of(context).push(new MaterialPageRoute<Set<String>>(
            builder: (BuildContext context) {
              return new ChannelPickerDialog(searchFilters["Sender"]);
            },
            fullscreenDialog: true,
            settings: RouteSettings(name: "ChannelPicker")));

    logger.fine("Channel selection received");

    String filterValue =
        channelSelection.map((String channel) => channel).join(";");

    String displayText = "Sender: " + channelSelection.length.toString();

    logger.fine("Sender filter: value: " +
        filterValue +
        " DisplayText: " +
        displayText);

    SearchFilter channelFilter = new SearchFilter(
        filterId: "Sender",
        filterValue: filterValue,
        displayText: displayText,
        handleTabCallback: handleTapOnFilter);

    onFilterUpdated(channelFilter);
  }

  getRangeSliderRow() {
    SearchFilter lengthFilter;
    if (searchFilters["Länge"] != null) {
      lengthFilter = new SearchFilter(
          filterId: "Länge",
          filterValue: searchFilters["Länge"].filterValue,
          handleTabCallback: handleTapOnFilter);
    } else {
      lengthFilter = new SearchFilter(
          filterId: "Länge", handleTabCallback: handleTapOnFilter);
    }

    return new Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        new Container(
          width: 80.0,
          child: new Padding(
            padding: new EdgeInsets.only(right: 5.0),
            child: new Text(
              "Länge",
              style: new TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.start,
            ),
          ),
        ),
        new Flexible(
            child: new VideoLengthSlider(onFilterUpdated, lengthFilter)),
      ],
    );
  }
}
