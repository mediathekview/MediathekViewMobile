import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ws/analytics/firebaseAnalytics.dart';
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
import 'package:flutter_ws/util/osChecker.dart';
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

void main() => runApp(new AppSharedStateContainer(child: new MyApp()));

class MyApp extends StatelessWidget {
//  static FirebaseAnalytics analytics = new FirebaseAnalytics();
//  static FirebaseAnalyticsObserver observer =
//      new FirebaseAnalyticsObserver(analytics: analytics);
  final TextEditingController textEditingController =
      new TextEditingController();

  @override
  Widget build(BuildContext context) {
    AppSharedStateContainer.of(context).initializeState(context);

    print("Rendering Main App");
    final title = 'MediathekView';

    //Track os
//    OsChecker
//        .getTargetPlatform()
//        .then((platform) => Firebase.logOperatingSystem(platform.toString()));

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
      home: new MyHomePage(
        key: new Key(uuid.v1()),
        title: title,
//        analytics: analytics,
//        observer: observer,
        textEditingController: textEditingController,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  //FirebaseAnalytics
//  final FirebaseAnalytics analytics;
//  final FirebaseAnalyticsObserver observer;

  final String title;
  final TextEditingController textEditingController;
  final PageController pageController;

  MyHomePage(
      {Key key,
      @required this.title,
//      this.analytics,
//      this.observer,
      this.pageController,
      this.textEditingController})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new HomePageState(this.textEditingController);
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
  static WebsocketController websocketController;
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
  Timer noConnectionChecker;

  //Statusbar
  StatusBar statusBar;

  TabController _controller;
  TextEditingController searchFieldController;

  /// Indicating the current displayed page
  /// 0: videoList
  /// 1: LiveTV
  /// 2: downloads
  /// 3: about
  int _page = 0;

  bool scrolledToEndOfList;

  //FirebaseAnalytics
//  final FirebaseAnalytics analytics;
//  final FirebaseAnalyticsObserver observer;

  //Tabs
  Widget videoSearchList;
  LiveTVSection liveTVSection;
  DownloadSection downloadSection;
  AboutSection aboutSection;


  HomePageState(this.searchFieldController);

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
    searchFieldController.addListener(inputListener);

    //register Observer to react to android/ios lifecycle events
    WidgetsBinding.instance.addObserver(this);

    //Firebase
//    Firebase.initFirebase(analytics);

    _controller = new TabController(length: 4, vsync: this);

    //Init tabs
    videoSearchList = getVideoSearchListWidget();
    liveTVSection = new LiveTVSection();
    downloadSection = new DownloadSection();
    aboutSection = new AboutSection();


    //keys
    Uuid uuid = new Uuid();
    videoListKey = new Key(uuid.v1());
    statusBarKey = new Key(uuid.v1());
    indexingBarKey = new Key(uuid.v1());

    websocketController = new WebsocketController(
        onDataReceived: onWebsocketData,
        onDone: onWebsocketDone,
        onError: onWebsocketError,
        onWebsocketChannelOpenedSuccessfully:
            onWebsocketChannelOpenedSuccessfully);
    websocketController.initializeWebsocket().then((Void) {
      currentUserQueryInput = searchFieldController.text;

      print("Firing query on home page init");
      websocketController.queryEntries(
          currentUserQueryInput, searchFilters, 0, 10);
    });

    Duration duration = new Duration(milliseconds: 5000);
    noConnectionChecker = new Timer.periodic(
      duration,
      (Timer t) {
        ConnectionState connectionState = websocketController.connectionState;

        if (connectionState == ConnectionState.active) {
          print("Ws connection is fine");
          if (websocketInitError) {
            websocketInitError = false;
            if (mounted) setState(() {});
          }
        } else if (connectionState == ConnectionState.done ||
            connectionState == ConnectionState.none) {
          print("Ws connection is " +
              connectionState.toString() +
              " and mounted: " +
              mounted.toString());

          if (mounted)
            websocketController
                .initializeWebsocket()
                .then((initializedSuccessfully) {
              if (initializedSuccessfully) {
                print("WS connection stable again");
                if (videos.isEmpty) _createQuery(0, 10);
              } else {
                print("WS initialization failed");
              }
            });
        }
      },
    );
  }

  @override
  void dispose() {
//    _pageController.dispose();
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

    return new Scaffold(
      backgroundColor: Colors.grey[100],
      body: new TabBarView(
        controller: _controller,
        children: <Widget>[
          new SafeArea(child:  videoSearchList == null? getVideoSearchListWidget(): videoSearchList),
          liveTVSection == null? new LiveTVSection(): liveTVSection,
          downloadSection == null? new DownloadSection(): downloadSection,
          aboutSection == null? new AboutSection(): aboutSection
        ],
      ),
      bottomNavigationBar: new Theme(
        data: Theme.of(context).copyWith(
            canvasColor: Colors.grey[900],
            splashColor: new Color(0xffffbf00),
//            unselectedWidgetColor: Colors.green,
            primaryColor: Colors.white,
            textTheme: Theme
                .of(context)
                .textTheme
                .copyWith(caption: new TextStyle(color: Colors.grey))),
        child: new BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: [
              new BottomNavigationBarItem(
                activeIcon:
                    new Icon(Icons.search, color: new Color(0xffffbf00)),
                icon: new Icon(Icons.search, color: Colors.white),
                title: new Text("Suche"),
              ),
              new BottomNavigationBarItem(
                activeIcon:
                    new Icon(Icons.live_tv, color: new Color(0xffffbf00)),
                icon: new Icon(Icons.live_tv,
                    color: _page != 1 ? Colors.white : new Color(0xffffbf00)),
                title: new Text("Live Tv"),
              ),
              new BottomNavigationBarItem(
                activeIcon:
                    new Icon(Icons.file_download, color: new Color(0xffffbf00)),
                icon: new Icon(Icons.file_download,
                    color: _page != 2 ? Colors.white : new Color(0xffffbf00)),
                title: new Text("Downloads"),
              ),
              new BottomNavigationBarItem(
                activeIcon:
                    new Icon(Icons.info_outline, color: new Color(0xffffbf00)),
                icon: new Icon(Icons.info_outline, color: Colors.white),
                title: new Text("About"),
              )
            ],
            onTap: navigationTapped,
            currentIndex: _page),
      ),
    );
  }

  Widget getVideoSearchListWidget() {
    Widget videoSearchList = new Column(children: <Widget>[
      new FilterBarSharedState(
        child: new GradientAppBar(
            searchFieldController,
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
    return videoSearchList;
  }

//  void onPageChanged(int page) {
//    print("On page Changed: ---> Page " + page.toString());
//    setState(() {
//      this._page = page;
//    });
//  }

  /// Called when the user presses on of the
  /// [BottomNavigationBarItem] with corresponding
  /// page index
  void navigationTapped(int page) {
    print("New Navigation Tapped: ---> Page " + page.toString());
    _controller.animateTo(page,
        duration: const Duration(milliseconds: 300), curve: Curves.ease);

    setState(() {
      this._page = page;
    });

    /// 0: videoList
    /// 1: LiveTV
    /// 2: downloads
    /// 3: about
    String pageName;
    switch (page) {
      case 0:
        pageName = "VideoList";
        break;
      case 1:
        pageName = "LiveTV";
        break;
      case 2:
        pageName = "Downloads";
        break;
      case 3:
        pageName = "About";
        break;
    }
//    Firebase.sendCurrentTabToAnalytics(observer, pageName);
  }

  Future<Null> _handleListRefresh() async {
    print("Refreshing video list ...");
    refreshOperationRunning = true;
    //the completer will be completed when there are results & the flag == true
    refreshCompleter = new Completer<Null>();
    _createQueryWithClearedVideoList(0, 10);

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
  }

  void onWebsocketError(FailedToContactWebsocketError error) {
    if (this.websocketInitError == false) {
      this.websocketInitError = true;
      if (mounted) setState(() {});
    }
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
          this.indexingError = false;
          this.indexingInfo = indexingInfo;
        });
      } else if (indexingInfo.error) {
        setState(() {
          this.indexingError = true;
        });
      } else {
        setState(() {
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
//          print("FOund duplicate with title: " +
//              video.title +
//              " and duration: " +
//              video.duration.toString() +
//              " and index: " +
//              b.toString());
          hasDuplicate = true;
          break;
        }
      }
      if (hasDuplicate == false) {
        //TODO exlude ORF atm
        if (currentVideo.channel == "ORF") continue;

//        print("video: " + currentVideo.channel);
        videos.add(currentVideo);
//        print("Adding video. Length now: " + videos.length.toString());
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

  // ---------- SEARCH Input ----------------

  void handleSearchInput() {
    if (currentUserQueryInput == searchFieldController.text) {
      print("Current Query Input equals new query input - not querying again!");
      return;
    }

    _createQueryWithClearedVideoList(0, 10);
  }

  void _createQuery(int skip, int top) {
    currentUserQueryInput = searchFieldController.text;

    websocketController.queryEntries(
        currentUserQueryInput, searchFilters, skip, top);
  }

  void _createQueryWithClearedVideoList(int skip, int top) {
    print("Clearing video list");
    videos.clear();

    //Firebase.logVideoSearch(searchFieldController.text, searchFilters);

    if (mounted) setState(() {});
    _createQuery(skip, top);
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
        _createQueryWithClearedVideoList(0, 10);
      }
    } else if (newFilter.filterValue.isNotEmpty) {
      print("New filter with id " +
          newFilter.filterId.toString() +
          " detected with value " +
          newFilter.filterValue);

      HapticFeedback.mediumImpact();

      this.searchFilters.putIfAbsent(newFilter.filterId, () => newFilter);
      _createQueryWithClearedVideoList(0, 10);
    }
  }

  _singleFilterTappedCallback(String id) {
    //remove filter from list and refresh state to retrigger build of app bar and list!
    searchFilters.remove(id);
    HapticFeedback.mediumImpact();
    _createQueryWithClearedVideoList(0, 10);
  }

  // ----------LIFECYCLE----------------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("Observed Lifecycle change " + state.toString());
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.suspending) {
      //TODO maybe dispose Tab controller here
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
