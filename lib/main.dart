import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ws/enum/ws_event_types.dart';
import 'package:flutter_ws/exceptions/failed_to_contact_websocket.dart';
import 'package:flutter_ws/model/indexing_info.dart';
import 'package:flutter_ws/model/query_result.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/websocket/websocket_manager.dart';
import 'package:flutter_ws/section/about_section.dart';
import 'package:flutter_ws/section/download_section.dart';
import 'package:flutter_ws/section/live_tv_section.dart';
import 'package:flutter_ws/util/json_parser.dart';
import 'package:flutter_ws/util/text_styles.dart';
import 'package:flutter_ws/websocket/websocket.dart';
import 'package:flutter_ws/widgets/filterMenu/filter_menu.dart';
import 'package:flutter_ws/widgets/filterMenu/search_filter.dart';
import 'package:flutter_ws/widgets/bars/gradient_app_bar.dart';
import 'package:flutter_ws/widgets/bars/indexing_bar.dart';
import 'package:flutter_ws/global_state/appBar_state_container.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/widgets/videolist/video_list_view.dart';
import 'package:flutter_ws/widgets/bars/status_bar.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

void main() => runApp(new AppSharedStateContainer(child: new MyApp()));

class MyApp extends StatelessWidget {
  final TextEditingController textEditingController =
      new TextEditingController();

  @override
  Widget build(BuildContext context) {
    AppSharedStateContainer.of(context).initializeState(context);

    final title = 'MediathekView';

    //Setup global log levels
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((LogRecord rec) {
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
    });

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
      ),
      title: title,
      home: new MyHomePage(
        key: new Key(uuid.v1()),
        title: title,
        textEditingController: textEditingController,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final TextEditingController textEditingController;
  final PageController pageController;
  final Logger logger = new Logger('MyHomePage');

  MyHomePage(
      {Key key,
      @required this.title,
      this.pageController,
      this.textEditingController})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new HomePageState(this.textEditingController, this.logger);
  }
}

class HomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  List<Video> videos;
  final Logger logger;

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
  static Timer socketHealthTimer;

  //Keys
  Key videoListKey;
  Key statusBarKey;
  Key indexingBarKey;

  //mock
  static Timer mockTimer;

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

  //Tabs
  Widget videoSearchList;
  LiveTVSection liveTVSection;
  DownloadSection downloadSection;
  AboutSection aboutSection;

  HomePageState(this.searchFieldController, this.logger);

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

      logger.fine("Firing initial query on home page init");
      websocketController.queryEntries(
          currentUserQueryInput, searchFilters, 0, 10);
    });

    startSocketHealthTimer();
  }

  void startSocketHealthTimer() {
    if (socketHealthTimer == null || !socketHealthTimer.isActive) {
      Duration duration = new Duration(milliseconds: 5000);
      Timer.periodic(
        duration,
        (Timer t) {
          ConnectionState connectionState = websocketController.connectionState;

          if (connectionState == ConnectionState.active) {
            logger.fine("Ws connection is fine");
            if (websocketInitError) {
              websocketInitError = false;
              if (mounted) setState(() {});
            }
          } else if (connectionState == ConnectionState.done ||
              connectionState == ConnectionState.none) {
            logger.fine("Ws connection is " +
                connectionState.toString() +
                " and mounted: " +
                mounted.toString());

            if (mounted)
              websocketController
                  .initializeWebsocket()
                  .then((initializedSuccessfully) {
                if (initializedSuccessfully) {
                  logger.info("WS connection stable again");
                  if (videos.isEmpty) _createQuery(0, 10);
                } else {
                  logger.info("WS initialization failed");
                }
              });
          }
        },
      );
    }
  }

  @override
  void dispose() {
//    _pageController.dispose();
    logger.fine("Disposing Home Page & shutting down websocket connection");

    websocketController.stopPing();
    websocketController.closeWebsocketChannel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    stateContainer = AppSharedStateContainer.of(context);

    logger.fine("Rendering Home Page");

    return new Scaffold(
      backgroundColor: Colors.grey[100],
      body: new TabBarView(
        controller: _controller,
        children: <Widget>[
          new SafeArea(
              child: videoSearchList == null
                  ? getVideoSearchListWidget()
                  : videoSearchList),
          liveTVSection == null ? new LiveTVSection() : liveTVSection,
          downloadSection == null ? new DownloadSection() : downloadSection,
          aboutSection == null ? new AboutSection() : aboutSection
        ],
      ),
      bottomNavigationBar: new Theme(
        data: Theme.of(context).copyWith(
            canvasColor: Colors.grey[900],
            splashColor: new Color(0xffffbf00),
//            unselectedWidgetColor: Colors.green,
            primaryColor: Colors.white,
            textTheme: Theme.of(context)
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
                onSingleFilterTapped: _singleFilterTappedCallback),
            false),
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

  /// Called when the user presses on of the
  /// [BottomNavigationBarItem] with corresponding
  /// page index
  void navigationTapped(int page) {
    logger.fine("New Navigation Tapped: ---> Page " + page.toString());
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
  }

  Future<Null> _handleListRefresh() async {
    logger.fine("Refreshing video list ...");
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

  onWebsocketDone() {
    logger.info("Received a Done signal from the Websocket");
  }

  void onWebsocketError(FailedToContactWebsocketError error) {
    logger.info("Received a ERROR from the Websocket.", {error: error});
    if (this.websocketInitError == false) {
      this.websocketInitError = true;
      if (mounted) setState(() {});
    }
  }

  void onWebsocketData(String data) {
    if (data == null) {
      logger.fine("Data received is null");
      setState(() {});
      return;
    }

    //determine event type
    String socketIOEventType =
        WebsocketHandler.parseSocketIOConnectionType(data);

    if (socketIOEventType != WebsocketConnectionTypes.UNKNOWN)
      logger.fine("Websocket: received response type: " + socketIOEventType);

    if (socketIOEventType == WebsocketConnectionTypes.RESULT) {
      if (refreshOperationRunning) {
        refreshOperationRunning = false;
        refreshCompleter.complete();
        videos.clear();
        logger.fine("Refresh operation finished.");
        HapticFeedback.lightImpact();
      }

      QueryResult queryResult = JSONParser.parseQueryResult(data);

      List<Video> newVideosFromQuery = queryResult.videos;
      logger.fine('Received ' +
          newVideosFromQuery.length.toString() +
          ' entries. Amount of videos currently in list ' +
          videos.length.toString());

      lastAmountOfVideosRetrieved = newVideosFromQuery.length;

      //construct new videos List
      int newVideosCount = addOnlyNewVideos(newVideosFromQuery);

      logger.fine("Added amount of new videos: " + newVideosCount.toString());

      if (newVideosCount == 0 && scrolledToEndOfList == false) {
        logger.fine("Scrolled to end of list");
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
      logger.info("Recieved pong. Content: " + data);
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
          hasDuplicate = true;
          break;
        }
      }
      if (hasDuplicate == false) {
        //TODO exlude ORF atm
        if (currentVideo.channel == "ORF") continue;
        videos.add(currentVideo);
        newVideosCount++;
      }
    }
    return newVideosCount;
  }

  // ----------CALLBACKS: From List View ----------------

  onQueryEntries(int skip, int top) {
    logger.fine('Requesting entries with skip ' +
        skip.toString() +
        ". last requested skip is " +
        lastRequestedSkip.toString());

    lastRequestedSkip = skip;
    websocketController.queryEntries(
        currentUserQueryInput, searchFilters, skip, top); //
  }

  // ---------- SEARCH Input ----------------

  void handleSearchInput() {
    if (currentUserQueryInput == searchFieldController.text) {
      logger.fine(
          "Current Query Input equals new query input - not querying again!");
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
    logger.fine("Clearing video list");
    videos.clear();

    //Firebase.logVideoSearch(searchFieldController.text, searchFilters);

    if (mounted) setState(() {});
    _createQuery(skip, top);
  }

  // ----------CALLBACKS: FILTER MENU----------------

  _filterMenuUpdatedCallback(SearchFilter newFilter) {
    //called whenever a filter in the menu gets a value
//    logger.fine("Changed Filter detected. ID : " + newFilter.filterId + " current value: " + newFilter.filterValue);

    if (this.searchFilters[newFilter.filterId] != null) {
      if (this.searchFilters[newFilter.filterId].filterValue !=
          newFilter.filterValue) {
        logger.fine("Changed filter text for filter with id " +
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
      logger.fine("New filter with id " +
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
    logger.fine("Observed Lifecycle change " + state.toString());
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
    if (mockTimer == null || !mockTimer.isActive) {
      var one = new Duration(seconds: 1);
      mockTimer = new Timer.periodic(one, (Timer t) {
        logger.fine("increase");
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
}
