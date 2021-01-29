import 'dart:async';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ws/api/api_query.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/model/indexing_info.dart';
import 'package:flutter_ws/model/query_result.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/section/download_section.dart';
import 'package:flutter_ws/section/settings_section.dart';
import 'package:flutter_ws/util/countly.dart';
import 'package:flutter_ws/util/json_parser.dart';
import 'package:flutter_ws/util/text_styles.dart';
import 'package:flutter_ws/widgets/bars/gradient_app_bar.dart';
import 'package:flutter_ws/widgets/bars/status_bar.dart';
import 'package:flutter_ws/widgets/filterMenu/filter_menu.dart';
import 'package:flutter_ws/widgets/filterMenu/search_filter.dart';
import 'package:flutter_ws/widgets/introSlider/intro_slider.dart';
import 'package:flutter_ws/widgets/videolist/video_list_view.dart';
import 'package:flutter_ws/widgets/videolist/videolist_util.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'global_state/appBar_state_container.dart';

void main() {
  runZonedGuarded<Future<void>>(() async {
    runApp(new AppSharedStateContainer(child: new MyApp()));
  }, Countly.recordDartError);
}

class MyApp extends StatelessWidget {
  final TextEditingController textEditingController =
      new TextEditingController();

  @override
  Widget build(BuildContext context) {
    AppSharedStateContainer.of(context).initializeState(context);

    final title = 'MediathekViewMobile';

    //Setup global log levels
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((LogRecord rec) {
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
    });

    Uuid uuid = new Uuid();

    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: new ThemeData(
        textTheme: new TextTheme(
            subhead: subHeaderTextStyle,
            title: headerTextStyle,
            body1: body1TextStyle,
            body2: body2TextStyle,
            display1: hintTextStyle,
            button: buttonTextStyle),
        chipTheme: new ChipThemeData.fromDefaults(
            secondaryColor: Colors.black,
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
  final Logger logger = new Logger('Main');

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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  List<Video> videos;
  final Logger logger;

  //global state
  AppSharedState appWideState;

  //AppBar
  IconButton buttonOpenFilterMenu;
  String currentUserQueryInput;

  //Filter Menu
  Map<String, SearchFilter> searchFilters;
  bool filterMenuOpen;
  bool filterMenuChannelFilterIsOpen;

  // API
  static APIQuery api;
  IndexingInfo indexingInfo;
  bool refreshOperationRunning;
  bool apiError;
  Completer<Null> refreshCompleter;

  //Keys
  Key videoListKey;
  Key statusBarKey;
  Key indexingBarKey;

  //mock
  static Timer mockTimer;

  //Statusbar
  StatusBar statusBar;

  TabController _controller;

  /// Indicating the current displayed page
  /// 0: videoList
  /// 1: LiveTV
  /// 2: downloads
  /// 3: about
  int _page = 0;

  //search
  TextEditingController searchFieldController;
  bool scrolledToEndOfList;
  int lastAmountOfVideosRetrieved;
  int totalQueryResults = 0;

  //Tabs
  Widget videoSearchList;
  static DownloadSection downloadSection;
  SettingsSection aboutSection;

  //intro slider
  SharedPreferences prefs;
  bool isFirstStart = false;

  // Cuuntly
  bool showCountlyGDPRDialog = false;
  static const COUNTLY_GITHUB =
      "https://raw.githubusercontent.com/mediathekview/MediathekViewMobile/master/resources/countly/config/endpoint.txt";
  static const SHARED_PREFERENCE_KEY_COUNTLY_CONSENT = "countly_consent";
  static const SHARED_PREFERENCE_KEY_COUNTLY_API = "countly_api";
  static const SHARED_PREFERENCE_KEY_COUNTLY_APP_KEY = "countly_app_key";

  HomePageState(this.searchFieldController, this.logger);

  @override
  void dispose() {
    logger.fine("Disposing Home Page");
    WidgetsBinding.instance.removeObserver(this);
    Countly.isInitialized().then((initialized) {
      if (initialized) {
        Countly.stop();
      }
    });

    super.dispose();
  }

  @override
  void initState() {
    videos = new List();
    searchFilters = new Map();
    filterMenuOpen = false;
    filterMenuChannelFilterIsOpen = false;
    apiError = false;
    indexingInfo = null;
    lastAmountOfVideosRetrieved = -1;
    refreshOperationRunning = false;
    scrolledToEndOfList = false;
    currentUserQueryInput = "";
    var inputListener = () => handleSearchInput();
    searchFieldController.addListener(inputListener);

    //register Observer to react to android/ios lifecycle events
    WidgetsBinding.instance.addObserver(this);

    _controller = new TabController(length: 3, vsync: this);
    _controller.addListener(() => onUISectionChange());

    //Init tabs
    //liveTVSection = new LiveTVSection();
    aboutSection = new SettingsSection();

    //keys
    Uuid uuid = new Uuid();
    videoListKey = new Key(uuid.v1());
    statusBarKey = new Key(uuid.v1());
    indexingBarKey = new Key(uuid.v1());

    api = new APIQuery(
        onDataReceived: onSearchResponse, onError: onAPISearchError);
    api.search(currentUserQueryInput, searchFilters);

    checkForFirstStart();

    setupCountly();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    appWideState = AppSharedStateContainer.of(context);

    if (isFirstStart) {
      return new IntroScreen(onDonePressed: () {
        setState(() {
          isFirstStart = false;
          prefs.setBool('firstStart', false);
        });
      });
    }

    if (showCountlyGDPRDialog) {
      logger.info("show dialog");
      return _showGDPRDialog(context);
    }

    if (downloadSection == null) {
      downloadSection = new DownloadSection(appWideState);
    }

    return new Scaffold(
      backgroundColor: Colors.grey[800],
      body: new TabBarView(
        controller: _controller,
        children: <Widget>[
          getVideoSearchListWidget(),
          downloadSection,
          aboutSection == null ? new SettingsSection() : aboutSection
        ],
      ),
      bottomNavigationBar: new Theme(
        data: Theme.of(context).copyWith(
            // sets the background color of the `BottomNavigationBar`
            canvasColor: Colors.black,
            // sets the active color of the `BottomNavigationBar` if `Brightness` is light
            primaryColor: Colors.red,
            textTheme: Theme.of(context).textTheme.copyWith(
                caption: new TextStyle(
                    color: Colors
                        .yellow))), // sets the inactive color of the `BottomNavigationBar`
        child: new BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _page,
          onTap: navigationTapped,
          items: [
            BottomNavigationBarItem(
                icon: Icon(
                  Icons.live_tv,
                  color: Colors.white,
                ),
                activeIcon: Icon(
                  Icons.live_tv,
                  color: Color(0xffffbf00),
                ),
                title: Text("Mediathek",
                    style: new TextStyle(color: Colors.white, fontSize: 15.0))),
            BottomNavigationBarItem(
                icon: Icon(
                  Icons.folder,
                  color: Colors.white,
                ),
                activeIcon: Icon(
                  Icons.folder,
                  color: Color(0xffffbf00),
                ),
                title: Text("Bibliothek",
                    style: new TextStyle(color: Colors.white, fontSize: 15.0))),
            BottomNavigationBarItem(
                icon: Icon(
                  Icons.settings_outlined,
                  color: Colors.white,
                ),
                activeIcon: Icon(
                  Icons.settings_outlined,
                  color: Color(0xffffbf00),
                ),
                title: Text("Settings",
                    style: new TextStyle(color: Colors.white, fontSize: 15.0)))
          ],
        ),
      ),
    );
  }

  Widget getVideoSearchListWidget() {
    logger.fine("Rendering Video Search list");

    Widget videoSearchList = new SafeArea(
      child: new RefreshIndicator(
        onRefresh: _handleListRefresh,
        child: new Container(
          color: Colors.grey[800],
          child: new CustomScrollView(
            slivers: <Widget>[
              new SliverToBoxAdapter(
                child: new FilterBarSharedState(
                  child: new GradientAppBar(
                      this,
                      searchFieldController,
                      new FilterMenu(
                          searchFilters: searchFilters,
                          onFilterUpdated: _filterMenuUpdatedCallback,
                          onSingleFilterTapped: _singleFilterTappedCallback),
                      false,
                      videos.length,
                      totalQueryResults),
                ),
              ),
              new VideoListView(
                  key: videoListKey,
                  videos: videos,
                  amountOfVideosFetched: lastAmountOfVideosRetrieved,
                  queryEntries: onQueryEntries,
                  currentQuerySkip: api.getCurrentSkip(),
                  totalResultSize: totalQueryResults,
                  mixin: this),
              new SliverToBoxAdapter(
                child: new StatusBar(
                    key: statusBarKey,
                    apiError: apiError,
                    videoListIsEmpty: videos.isEmpty,
                    lastAmountOfVideosRetrieved: lastAmountOfVideosRetrieved,
                    firstAppStartup: lastAmountOfVideosRetrieved < 0),
              ),
            ],
          ),
        ),
      ),
    );
    return videoSearchList;
  }

  // Called when the user presses on of the BottomNavigationBarItems. Does not get triggered by a users swipe.
  void navigationTapped(int page) {
    logger.info("New Navigation Tapped: ---> Page " + page.toString());
    _controller.animateTo(page,
        duration: const Duration(milliseconds: 300), curve: Curves.ease);

    setState(() {
      this._page = page;
    });
  }

  /*
    Gets triggered whenever TabController changes page.
    This can be due to a user's swipe or via tab on the BottomNavigationBar
   */
  onUISectionChange() {
    if (this._page != _controller.index) {
      logger
          .info("UI Section Change: ---> Page " + _controller.index.toString());

      Countly.isInitialized().then((initialized) {
        if (initialized) {
          switch (_controller.index) {
            case 0:
              Countly.recordView("Mediathek");
              break;
            case 1:
              Countly.recordView("Downloads");
              break;
            case 2:
              // do something else
              Countly.recordView("Settings");
              break;
          }
        }
      });

      setState(() {
        this._page = _controller.index;
      });
    }
  }

  Future<Null> _handleListRefresh() async {
    logger.fine("Refreshing video list ...");
    refreshOperationRunning = true;
    //the completer will be completed when there are results & the flag == true
    refreshCompleter = new Completer<Null>();
    _createQueryWithClearedVideoList();

    return refreshCompleter.future;
  }

  // ----------CALLBACKS: WebsocketController----------------

  void onAPISearchError(Error error) {
    logger.info("Received an error from thr API." + error.toString());

    // TODO show status bar with error

    // http 503 -> indexing
    // http 500 -> internal error
    // http 400 -> invalid query
  }

  void onSearchResponse(String data) {
    if (data == null) {
      logger.fine("Data received is null");
      setState(() {});
      return;
    }

    if (refreshOperationRunning) {
      refreshOperationRunning = false;
      refreshCompleter.complete();
      videos.clear();
      logger.fine("Refresh operation finished.");
      HapticFeedback.lightImpact();
    }

    QueryResult queryResult = JSONParser.parseQueryResult(data);

    List<Video> newVideosFromQuery = queryResult.videos;
    totalQueryResults = queryResult.queryInfo.totalResults;
    lastAmountOfVideosRetrieved = newVideosFromQuery.length;
    logger.info("received videos: " + lastAmountOfVideosRetrieved.toString());

    int videoListLengthOld = videos.length;
    videos = VideoListUtil.sanitizeVideos(newVideosFromQuery, videos);
    int newVideosCount = videos.length - videoListLengthOld;
    logger.info("received new videos: " + newVideosCount.toString());

    if (newVideosCount == 0 && scrolledToEndOfList == false) {
      logger.info("Scrolled to end of list & mounted: " + mounted.toString());
      scrolledToEndOfList = true;
      if (mounted) {
        setState(() {});
      }
      return;
    } else if (newVideosCount != 0) {
      // client side result filtering
      if (searchFilters["Länge"] != null) {
        // do not filter length if maximum range is set
        List<String> split = searchFilters["Länge"].filterValue.split("-");
        double end = double.parse(split.elementAt(1));
        if (end.toInt() != 60) {
          videos =
              VideoListUtil.applyLengthFilter(videos, searchFilters["Länge"]);
        }
      }
      int newVideosCount = videos.length - videoListLengthOld;

      logger.info('Received ' +
          newVideosCount.toString() +
          ' new video(s). Amount of videos in list ' +
          videos.length.toString());

      lastAmountOfVideosRetrieved = newVideosCount;
      scrolledToEndOfList == false;
      if (mounted) setState(() {});
    }
  }

  // ----------CALLBACKS: From List View ----------------

  onQueryEntries() {
    api.search(currentUserQueryInput, searchFilters);
  }

  // ---------- SEARCH Input ----------------

  void handleSearchInput() {
    if (currentUserQueryInput == searchFieldController.text) {
      logger.fine(
          "Current Query Input equals new query input - not querying again!");
      return;
    }

    _createQueryWithClearedVideoList();
  }

  void _createQuery() {
    currentUserQueryInput = searchFieldController.text;

    api.search(currentUserQueryInput, searchFilters);
  }

  void _createQueryWithClearedVideoList() {
    logger.fine("Clearing video list");
    videos.clear();
    api.resetSkip();

    if (mounted) setState(() {});
    _createQuery();
  }

  // ----------CALLBACKS: FILTER MENU----------------

  _filterMenuUpdatedCallback(SearchFilter newFilter) {
    //called whenever a filter in the menu gets a value
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
        _createQueryWithClearedVideoList();
      }
    } else if (newFilter.filterValue.isNotEmpty) {
      logger.fine("New filter with id " +
          newFilter.filterId.toString() +
          " detected with value " +
          newFilter.filterValue);

      HapticFeedback.mediumImpact();

      this.searchFilters.putIfAbsent(newFilter.filterId, () => newFilter);
      _createQueryWithClearedVideoList();
    }
  }

  _singleFilterTappedCallback(String id) {
    //remove filter from list and refresh state to trigger build of app bar and list!
    searchFilters.remove(id);
    HapticFeedback.mediumImpact();
    _createQueryWithClearedVideoList();
  }

  // ----------LIFECYCLE----------------

  checkForFirstStart() async {
    prefs = await SharedPreferences.getInstance();
    var firstStart = prefs.getBool('firstStart');
    if (firstStart == null) {
      print("First start");
      setState(() {
        isFirstStart = true;
      });
    }
  }

  void setupCountly() async {
    logger.info("setup countly");
    var sharedPreferences = await SharedPreferences.getInstance();
    appWideState.appState.setSharedPreferences(sharedPreferences);

    logger.info("setup countly -2");

    if (appWideState.appState.sharedPreferences
            .containsKey(SHARED_PREFERENCE_KEY_COUNTLY_API) &&
        appWideState.appState.sharedPreferences
            .containsKey(SHARED_PREFERENCE_KEY_COUNTLY_APP_KEY)) {
      logger.info("setup countly -4");

      bool countlyConsent = appWideState.appState.sharedPreferences
          .getBool(SHARED_PREFERENCE_KEY_COUNTLY_CONSENT);

      if (!countlyConsent) {
        logger.info("Countly - no consent.");
        return;
      }

      String countlyAPI = appWideState.appState.sharedPreferences
          .getString(SHARED_PREFERENCE_KEY_COUNTLY_API);
      String countlyAppKey = appWideState.appState.sharedPreferences
          .getString(SHARED_PREFERENCE_KEY_COUNTLY_APP_KEY);

      logger.info("Loaded Countly data from shared preferences");
      CountlyUtil.initializeCountly(logger, countlyAPI, countlyAppKey, true);
      return;
    }

    logger.info("countly -3");

    // countly information not found in shared preferences
    // request permission from user
    // need to setState in order to show GDPR dialog
    setState(() {
      showCountlyGDPRDialog = true;
    });
  }

  Widget _showGDPRDialog(BuildContext context) {
    return NetworkGiffyDialog(
      //key: keys[1],
      image: Image.network(
        "https://raw.githubusercontent.com/Shashank02051997/FancyGifDialog-Android/master/GIF's/gif14.gif",
        fit: BoxFit.cover,
      ),
      entryAnimation: EntryAnimation.TOP_LEFT,
      title: Text(
        'Vielen Dank',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w600),
      ),
      description: Text(
        'Darf MediathekView anonymisierte Crash und Nutzungsdaten sammeln? Das hilft uns die App zu verbessern.',
        textAlign: TextAlign.center,
      ),
      onOkButtonPressed: () {
        CountlyUtil.loadCountlyInformationFromGithub(
            logger, appWideState, true);
        setState(() {
          showCountlyGDPRDialog = false;
        });
      },
      onCancelButtonPressed: () {
        CountlyUtil.loadCountlyInformationFromGithub(
            logger, appWideState, false);
        setState(() {
          showCountlyGDPRDialog = false;
        });
      },
      buttonCancelText: Text(
        "Nein",
        style: new TextStyle(color: Colors.white),
      ),
      buttonOkText: Text("Ja"),
    );
  }
}
