import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

class FilterMenuState {
  bool isFilterMenuOpen;
  FilterMenuState(this.isFilterMenuOpen);
}

class _InheritedStateContainer extends InheritedWidget {

  final StateContainerAppBarState data;

  _InheritedStateContainer({
    Key key,
    @required this.data,
    @required Widget child,
  }) : super(key: key, child: child);


  @override
  bool updateShouldNotify(_InheritedStateContainer old) {
    return true;
  }
}

class FilterBarSharedState extends StatefulWidget {
  final Widget child;
  final FilterMenuState videoListState;

  FilterBarSharedState({
    @required this.child,
    this.videoListState,
  });

  static StateContainerAppBarState of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(_InheritedStateContainer)
            as _InheritedStateContainer)
        .data;
  }

  @override
  StateContainerAppBarState createState() => new StateContainerAppBarState();
}

class StateContainerAppBarState extends State<FilterBarSharedState> {
  FilterMenuState filterMenuState;

  void updateAppBarState() {
    print("Filter menu");

    if (filterMenuState == null) {

      setState(() {
        filterMenuState = new FilterMenuState(true);
      });
    } else {
      setState(() {
        filterMenuState.isFilterMenuOpen = !filterMenuState.isFilterMenuOpen;
      });
    }
  }

  // build new inherited widget
  @override
  Widget build(BuildContext context) {
    print("Rendering StateContainerState");
    return new _InheritedStateContainer(
      data: this,
      child: widget.child,
    );
  }
}
