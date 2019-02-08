import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ws/widgets/filterMenu/channel_picker.dart';
import 'package:flutter_ws/widgets/filterMenu/filtermenu_channel_edit_button.dart';
import 'package:flutter_ws/widgets/filterMenu/search_filter.dart';
import 'package:flutter_ws/global_state/appBar_state_container.dart';
import 'package:meta/meta.dart';
import 'package:logging/logging.dart';

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

    return new GestureDetector(
      onTap: () {
        FilterBarSharedState.of(context).updateAppBarState();
      },
      child: new Container(
        decoration: new BoxDecoration(
          color: Colors.grey[800],
        ),
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            getFilterMenuRow("Thema", "Thema", _themaFieldController),

            getFilterMenuRow("Titel", "Titel", _titleFieldController),
            //Sender row
            new Row(
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
                          style: theme.textTheme.body2,
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
            ),
          ],
        ),
      ),
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
//          new IconButton(iconSize: 18.0, disabledColor: Colors.black, alignment: Alignment.center, padding: const EdgeInsets.all(0.0), icon: new Icon(Icons.delete)),
        new Container(
          width: 80.0,
          child: new Padding(
            padding: new EdgeInsets.only(right: 15.0),
            child: new Text(
              displayText,
              style: theme.textTheme.body2,
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
            style: theme.textTheme.body1,
            controller: controller,
            decoration: new InputDecoration(
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
        onFilterUpdated(new SearchFilter(
            filterId: filterId,
            filterValue: currentValueOfFilter,
            handleTabCallback: handleTapOnFilter));
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
            fullscreenDialog: true));

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
}
