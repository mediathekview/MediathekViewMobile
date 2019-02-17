import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ws/global_state/appBar_state_container.dart';
import 'package:flutter_ws/util/text_styles.dart';
import 'package:flutter_ws/widgets/filterMenu/filter_menu.dart';
import 'package:flutter_ws/widgets/filterMenu/search_filter.dart';
import 'package:logging/logging.dart';

class GradientAppBar extends StatelessWidget {
  final Logger logger = new Logger('GradientAppBar');
  final TextEditingController controller;
  final bool isFilterMenuOpen;
  final int currentAmountOfVideosInList;
  final int totalAmountOfVideosForSelection;
  FilterMenu filterMenu;
  List<SearchFilter> searchFilters;
  StateContainerAppBarState state;

  GradientAppBar(this.controller, this.filterMenu, this.isFilterMenuOpen,
      this.currentAmountOfVideosInList, this.totalAmountOfVideosForSelection);

  @override
  Widget build(BuildContext context) {
    logger.fine("Rendering App Bar");

    final theme = Theme.of(context);
    state = FilterBarSharedState.of(context);
    searchFilters = filterMenu.searchFilters.values.toList();

    bool isFilterMenuOpen = getFilterMenuState(context);

    return new Container(
      padding: const EdgeInsets.only(left: 16.0, right: 32.0),
      decoration: new BoxDecoration(
        color: Colors.grey[800],
        boxShadow: <BoxShadow>[
          new BoxShadow(
            color: Colors.black12,
            blurRadius: 10.0,
            offset: new Offset(0.0, 10.0),
          )
        ],
      ),
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          new Padding(
            padding: new EdgeInsets.only(bottom: 10.0),
            child: new Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                new Theme(
                  data: theme.copyWith(
                      primaryColor: new Color(0xffffbf00),
                      brightness: Brightness.dark,
                      accentColor: new Color(0xffffbf00)),
                  child: new Expanded(
                    child: new Container(
                      padding: new EdgeInsets.only(right: 20.0),
                      child: new TextField(
                        style: inputTextStyle,
                        controller: controller,
                        decoration: new InputDecoration(
                          suffixIcon: new IconButton(
                              color: controller.text.isNotEmpty
                                  ? Colors.red
                                  : Colors.transparent,
                              onPressed: () {
                                controller.text = "";
                              },
                              icon: new Icon(
                                Icons.clear,
                                size: 30.0,
                              )),
                          labelStyle: hintTextStyle.copyWith(
                              color: theme.indicatorColor),
                          icon: new Icon(Icons.search, size: 30.0),
                          isDense: true,
//                        hintText: 'Suche',
                        ),
                      ),
                    ),
                  ),
                ),
                new Text("Videos: " +
                    currentAmountOfVideosInList.toString() +
                    " / " +
                    totalAmountOfVideosForSelection.toString()),
                new Center(
                  child: new FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      state.updateAppBarState();
                    },
                    backgroundColor: Color(0xffffbf00),
                    highlightElevation: 10.0,
                    isExtended: true,
                    foregroundColor: Colors.black,
                    elevation: 7.0,
                    tooltip: "Filter Menü öffnen",
                    child: new Icon(Icons.edit, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          //show filters if there are some in the list
          searchFilters != null && searchFilters.isNotEmpty
              ? new Padding(
                  padding: new EdgeInsets.only(bottom: 5.0),
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      new Text('Filter: ', style: filterRowTextStyle),
                      new Row(children: searchFilters),
                    ],
                  ),
                )
              : new Container(),

          isFilterMenuOpen
              ? new Padding(
                  padding: new EdgeInsets.only(bottom: 10.0, top: 10.0),
                  child: filterMenu)
              : new Container(),
        ],
      ),
    );
  }

  bool getFilterMenuState(BuildContext context) {
    FilterMenuState videoListState = state.filterMenuState;
    return videoListState != null && videoListState.isFilterMenuOpen;
  }
}
