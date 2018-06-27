import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ws/enum/wsEventTypes.dart';
import 'package:flutter_ws/exceptions/FailedToContactWebsocket.dart';
import 'package:flutter_ws/manager/WebsocketManager.dart';
import 'package:flutter_ws/model/IndexingInfo.dart';
import 'package:flutter_ws/model/QueryResult.dart';
import 'package:flutter_ws/model/Video.dart';
import 'package:flutter_ws/section/aboutSection.dart';
import 'package:flutter_ws/section/downloadSection.dart';
import 'package:flutter_ws/section/liveTVSection.dart';
import 'package:flutter_ws/util/jsonParser.dart';
import 'package:flutter_ws/util/textStyles.dart';
import 'package:flutter_ws/util/websocket.dart';
import 'package:flutter_ws/widgets/StatusBar.dart';
import 'package:flutter_ws/widgets/filterMenu/filterMenu.dart';
import 'package:flutter_ws/widgets/filterMenu/searchFilter.dart';
import 'package:flutter_ws/widgets/gradientAppBar.dart';
import 'package:flutter_ws/widgets/indexingBar.dart';
import 'package:flutter_ws/widgets/inherited/appBar_state_container.dart';
import 'package:flutter_ws/widgets/inherited/list_state_container.dart';
import 'package:flutter_ws/widgets/list/videoListView.dart';
import 'package:uuid/uuid.dart';
//custom

void main() => runApp(new AppSharedStateContainer(child: new MyApp()));

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    AppSharedStateContainer.of(context).initializeState(context);

    print("Rendering Main App");
    final title = 'MediathekView';

    Uuid uuid = new Uuid();
    return new MaterialApp(
      theme: new ThemeData(
        textTheme: new TextTheme(
            subhead: subHeaderTextStyle,
            title: headerTextStyle,
            body1: body1TextStyle,
            body2: body2TextStyle,
            display1: hintTextStyle,
            button: buttonTextStyle),
        chipTheme: new ChipThemeData.fromDefaults(
            secondaryColor: Colors.grey,
            labelStyle: subHeaderTextStyle,
            brightness: Brightness.dark),
        brightness: Brightness.light,
//          indicatorColor: new Color(0xffffbf00)
      ),
      title: title,
      home: new MyHomePage(key: new Key(uuid.v1()), title: title),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final searchFieldController = new TextEditingController();

  MyHomePage({Key key, @required this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new HomePageState();
  }
}

class HomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  List<Video> videos;

  //global state
  AppSharedState stateContainer;

  //AppBar
  IconButton buttonOpenFilterMenu;
  String currentUserQueryInput;

  //Filter Menu
  Map<String, SearchFilter> searchFilters;
  bool filterMenuOpen;
  bool filterMenuChannelFilterIsOpen;

  //Websocket
  WebsocketController websocketController;
  bool websocketInitError;
  int lastAmountOfVideosRetrieved;
  IndexingInfo indexingInfo;
  bool indexingError;
  int lastRequestedSkip;
  bool refreshOperationRunning;
  Completer<Null> refreshCompleter;

  //Keys
  Key videoListKey;
  Key statusBarKey;
  Key indexingBarKey;

  //mock
  Timer mockTimer;

  //Statusbar
  StatusBar statusBar;

  TabController bottomNavigationBarController;

  bool scrolledToEndOfList;

  @override
  void initState() {
    videos = new List();

    //initialize Vars of HomePageState
    searchFilters = new Map();
    filterMenuOpen = false;
    filterMenuChannelFilterIsOpen = false;
    websocketInitError = false;
    lastRequestedSkip = 0;
    indexingInfo = null;
    indexingError = false;
    lastAmountOfVideosRetrieved = -1;
    refreshOperationRunning = false;
    currentUserQueryInput = "";
    scrolledToEndOfList = false;

    //search input
    var inputListener = () => handleSearchInput();
    widget.searchFieldController.addListener(inputListener);

    //register Observer to react to android/ios lifecycle events
    WidgetsBinding.instance.addObserver(this);

    //keys
    Uuid uuid = new Uuid();
    videoListKey = new Key(uuid.v1());
    statusBarKey = new Key(uuid.v1());
    indexingBarKey = new Key(uuid.v1());

    bottomNavigationBarController = new TabController(vsync: this, length: 4);

    websocketController = new WebsocketController(
        onDataReceived: onWebsocketData,
        onDone: onWebsocketDone,
        onError: onWebsocketError,
        onWebsocketChannelOpenedSuccessfully:
            onWebsocketChannelOpenedSuccessfully);
    websocketController.initializeWebsocket().then((Void) {
      currentUserQueryInput = widget.searchFieldController.text;

      websocketController.queryEntries(
          currentUserQueryInput, searchFilters, 0, 10);
    });
  }

  @override
  void dispose() {
    bottomNavigationBarController.dispose();

    print("Disposing Home Page & shutting down websocket connection");

    websocketController.stopPing();
    websocketController.closeWebsocketChannel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    stateContainer = AppSharedStateContainer.of(context);

    print("Rendering Home Page");

    Widget videoSearchList = new Column(children: <Widget>[
      new FilterBarSharedState(
        child: new GradientAppBar(
            widget.searchFieldController,
            new FilterMenu(
                searchFilters: searchFilters,
                onFilterUpdated: _filterMenuUpdatedCallback,
                onSingleFilterTapped: _singleFilterTappedCallback)),
      ),
      new Flexible(
        child: new RefreshIndicator(
            child: new VideoListView(
                key: videoListKey,
                videos: videos,
                amountOfVideosFetched: lastAmountOfVideosRetrieved,
                queryEntries: onQueryEntries),
            onRefresh: _handleListRefresh),
      ),
      new StatusBar(
          key: statusBarKey,
          websocketInitError: websocketInitError,
          videoListIsEmpty: videos.isEmpty,
          lastAmountOfVideosRetrieved: lastAmountOfVideosRetrieved,
          firstAppStartup: lastAmountOfVideosRetrieved < 0),
      new IndexingBar(
          key: indexingBarKey,
          indexingError: indexingError,
          info: indexingInfo),
    ]);

    return new Scaffold(
        backgroundColor: Colors.grey[100],
        bottomNavigationBar: new Container(
            height: 50.0,
            child: new Material(
                color: Colors.grey[900],
                child: new TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: new EdgeInsets.only(top: 2.0),
                    indicatorWeight: 2.0,
                    indicatorColor: new Color(0xffffbf00),
                    labelStyle: new TextStyle(fontSize: 10.0),
                    controller: bottomNavigationBarController,
                    tabs: <Tab>[
                      new Tab(icon: new Icon(Icons.search), text: "Suche"),
                      new Tab(icon: new Icon(Icons.live_tv), text: "Live TV"),
                      new Tab(
                          icon: new Icon(Icons.file_download),
                          text: "Downloads"),
                      new Tab(icon: new Icon(Icons.account_box), text: "About"),
                    ]))),
        body: new SafeArea(
            child: new TabBarView(
                controller: bottomNavigationBarController,
                children: <Widget>[
              videoSearchList,
              new LiveTVSection(),
              new DownloadSection(),
              new AboutSection()
            ])));
  }

  Future<Null> _handleListRefresh() async {
    print("Refreshing video list ...");
    refreshOperationRunning = true;
    //the completer will be completed when there are results & the flag == true
    refreshCompleter = new Completer<Null>();
    fireQueryOnSearchFilterUpdate();

    return refreshCompleter.future;
  }

  // ----------CALLBACKS: WebsocketController----------------
  onWebsocketChannelOpenedSuccessfully() {
    if (this.websocketInitError) {
      setState(() {
        this.websocketInitError = false;
      });
    }
  }

  //TODO add automatic reopen flag
  onWebsocketDone() {
    print('Received a Done signal from the Websocket');
    //retry connecting
    new Timer(new Duration(seconds: 3), () {
      websocketController.initializeWebsocket().then((Void) {
        print("Firing initial query after websocket done");
        _createQuery();
      });
    });
  }

  void onWebsocketError(FailedToContactWebsocketError error) {
    print("Ws initialization failed with " + error.toString());

    if (this.websocketInitError == false) {
      this.websocketInitError = true;
      if (mounted) setState(() {});
    }

    new Timer(new Duration(seconds: 3), () {
      websocketController.initializeWebsocket().then((Void) {
        print("Firing initial query after websocket error");
        _createQuery();
      });
    });
  }

  void onWebsocketData(String data) {
    if (data == null) {
      print("Data received is null");
      setState(() {});
      return;
    }

    //determine event type
    String socketIOEventType =
        WebsocketHandler.parseSocketIOConnectionType(data);

    if (socketIOEventType != WebsocketConnectionTypes.UNKNOWN)
      print("Websocket: received response type: " + socketIOEventType);

    if (socketIOEventType == WebsocketConnectionTypes.RESULT) {
      if (refreshOperationRunning) {
        refreshOperationRunning = false;
        refreshCompleter.complete();
        videos.clear();
        print("Refresh operation finished.");
        HapticFeedback.lightImpact();
      }

      QueryResult queryResult = JSONParser.parseQueryResult(data);

      List<Video> newVideosFromQuery = queryResult.videos;
      print('Received ' +
          newVideosFromQuery.length.toString() +
          ' entries. Amount of videos currently in list ' +
          videos.length.toString());

      lastAmountOfVideosRetrieved = newVideosFromQuery.length;

      //construct new videos List
      int newVideosCount = addOnlyNewVideos(newVideosFromQuery);

      print("Added amount of new videos: " + newVideosCount.toString());

      if (newVideosCount == 0 && scrolledToEndOfList == false) {
        print("Scrolled to end of list");
        scrolledToEndOfList = true;
        if (mounted) {
          setState(() {});
        }
        return;
      } else if (newVideosCount != 0) {
        lastAmountOfVideosRetrieved = newVideosCount;
        scrolledToEndOfList == false;
        if (mounted) setState(() {});
      }
    } else if (socketIOEventType == WebsocketConnectionTypes.INDEX_STATE) {
      IndexingInfo indexingInfo = JSONParser.parseIndexingEvent(data);

      if (!indexingInfo.done && !indexingInfo.error) {
        setState(() {
          //add queryResult && trigger rerender of list view in the build method
          this.indexingError = false;
          this.indexingInfo = indexingInfo;
        });
      } else if (indexingInfo.error) {
        setState(() {
          this.indexingError = true;
        });
      } else {
        setState(() {
          //Setting indexingInfo == null to ensure removal of progress indicator
          this.indexingError = false;
          this.indexingInfo = null;
        });
      }
    } else {
      print("Recieved pong. Content: " + data);
    }
  }

  int addOnlyNewVideos(List<Video> newVideosFromQuery) {
    int newVideosCount = 0;
    for (int i = 0; i < newVideosFromQuery.length; i++) {
      print("I: " + i.toString());
      Video currentVideo = newVideosFromQuery[i];
      bool hasDuplicate = false;
      for (int b = i + 1; b < newVideosFromQuery.length + videos.length; b++) {
        Video video;

        if (b > newVideosFromQuery.length - 1) {
          int index = b - newVideosFromQuery.length;
          video = videos[index];
        } else {
          video = newVideosFromQuery[b];
        }
        if (video.id == currentVideo.id ||
            video.title == currentVideo.title &&
                video.duration == currentVideo.duration) {
          print("FOund duplicate with title: " +
              video.title +
              " and duration: " +
              video.duration.toString() +
              " and index: " +
              b.toString());
          hasDuplicate = true;
          break;
        }
      }
      if (hasDuplicate == false) {
        videos.add(currentVideo);
        print("Adding video. Length now: " + videos.length.toString());
        newVideosCount++;
      }
    }
    return newVideosCount;
  }

  // ----------CALLBACKS: From List View ----------------

  onQueryEntries(int skip, int top) {
    print('Requesting entries with skip ' +
        skip.toString() +
        ". last requested skip is " +
        lastRequestedSkip.toString());

    lastRequestedSkip = skip;
    websocketController.queryEntries(
        currentUserQueryInput, searchFilters, skip, top);
  }

  // ----------CALLBACKS: From SEARCH INput ----------------

  void fireQueryOnSearchFilterUpdate() {
    _createQuery();
  }

  void handleSearchInput() {
    if (currentUserQueryInput == widget.searchFieldController.text) return;
    _createQuery();
  }

  void _createQuery() {
    print("Clearing video list");
    videos.clear();
    currentUserQueryInput = widget.searchFieldController.text;

    if (mounted) setState(() {});

    websocketController.queryEntries(
        currentUserQueryInput, searchFilters, 0, 10);
  }

  // ----------CALLBACKS: FILTER MENU----------------

  _filterMenuUpdatedCallback(SearchFilter newFilter) {
    //called whenever a filter in the menu gets a value
//    print("Changed Filter detected. ID : " + newFilter.filterId + " current value: " + newFilter.filterValue);

    if (this.searchFilters[newFilter.filterId] != null) {
      if (this.searchFilters[newFilter.filterId].filterValue !=
          newFilter.filterValue) {
        print("Changed filter text for filter with id " +
            newFilter.filterId.toString() +
            " detected. Old Value: " +
            this.searchFilters[newFilter.filterId].filterValue +
            " New : " +
            newFilter.filterValue);

        HapticFeedback.mediumImpact();

        searchFilters.remove(newFilter.filterId);
        if (newFilter.filterValue.isNotEmpty)
          this.searchFilters.putIfAbsent(newFilter.filterId, () => newFilter);
        //updates state internally
        fireQueryOnSearchFilterUpdate();
      }
    } else if (newFilter.filterValue.isNotEmpty) {
      print("New filter with id " +
          newFilter.filterId.toString() +
          " detected with value " +
          newFilter.filterValue);

      HapticFeedback.mediumImpact();

      this.searchFilters.putIfAbsent(newFilter.filterId, () => newFilter);
      fireQueryOnSearchFilterUpdate();
    }
  }

  _singleFilterTappedCallback(String id) {
    //remove filter from list and refresh state to retrigger build of app bar and list!
    searchFilters.remove(id);
    HapticFeedback.mediumImpact();
    fireQueryOnSearchFilterUpdate();
  }

  // ----------LIFECYCLE----------------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("Observed Lifecycle change " + state.toString());
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.suspending) {
      websocketController.stopPing();
      websocketController.closeWebsocketChannel();
    } else if (state == AppLifecycleState.resumed) {
      websocketController.initializeWebsocket();
    }
  }

  mockIndexing() {
    var one = new Duration(seconds: 1);
    this.mockTimer = new Timer.periodic(one, (Timer t) {
      print("increase");
      if (indexingInfo == null) {
        indexingInfo = new IndexingInfo();
        indexingInfo.indexerProgress = 0.0;
      }
      if (indexingInfo.indexerProgress > 1) {
        setState(() {
          //Setting indexingInfo == null to ensure removal of progress indicator
          this.indexingError = false;
          this.indexingInfo = null;
        });
        mockTimer.cancel();
        return;
      }
      setState(() {
        indexingInfo.indexerProgress = indexingInfo.indexerProgress + 0.05;
      });
    });
  }
}
