import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

import 'package:flutter_ws/model/Video.dart';
import 'package:flutter_ws/widgets/filterMenu/searchFilter.dart';


// TODO: log app verions
class Firebase {

  static void sendCurrentTabToAnalytics(FirebaseAnalyticsObserver observer,
      String tabName) {
    observer.analytics.setCurrentScreen(
      screenName: tabName,
    );
  }

  static Future<Null> appOpened(FirebaseAnalytics analytics) async {
    await analytics.logAppOpen();
    print('Firebase: App Opened');
  }

  static Future<Null> logVideoDetailViewed(FirebaseAnalytics analytics,
      Video video) async {
    _sendVariousEvent(analytics, "VideoDetail", video.toMap());
    print('Firebase: Video Detail Viewed');
  }

  static Future<Null> logVideoSearch(FirebaseAnalytics analytics, String query,
      Map<String, SearchFilter> filters) async {
    Map<String, String> data = new Map();
    data.putIfAbsent("SearchInput", () => query);
    filters.forEach((key, filter) {
      data.putIfAbsent("Filter_" + key, () => filter.filterValue);
    });

    _sendVariousEvent(analytics, "VideoSearch", data);

//    print('Firebase: Video Search logged');
  }

  static Future<Null> logOperatingSystem(FirebaseAnalytics analytics,
      String osName) async {
    _sendVariousEvent(analytics, "OperatingSystem", <String, dynamic>{
      'Os': osName
    },);

//    print('Firebase: Operating System event successfully logged');
  }

  static Future<Null> _sendVariousEvent(FirebaseAnalytics analytics,
      String eventName, Map<String, dynamic> parameters) async {
    await analytics.logEvent(
        name: eventName,
        parameters: parameters
    );

    //    await analytics.logEvent(
//      name: 'test_event',
//      parameters: <String, dynamic>{
//        'string': 'string',
//        'int': 42,
//        'long': 12345678910,
//        'double': 42.0,
//        'bool': true,
//      },
//    );
    print('Firebase: Event with name ' + eventName + ' logged');
  }

  static Future<Null> _testSetUserId(FirebaseAnalytics analytics) async {
    await analytics.setUserId('some-user');
    print('setUserId succeeded');
  }

  static Future<Null> _testSetCurrentScreen(FirebaseAnalytics analytics) async {
    await analytics.setCurrentScreen(
      screenName: 'Analytics Demo',
      screenClassOverride: 'AnalyticsDemo',
    );
    print('setCurrentScreen succeeded');
  }

  static Future<Null> _testSetAnalyticsCollectionEnabled(
      FirebaseAnalytics analytics) async {
    await analytics.android?.setAnalyticsCollectionEnabled(false);
    await analytics.android?.setAnalyticsCollectionEnabled(true);
    print('setAnalyticsCollectionEnabled succeeded');
  }

  static Future<Null> _testSetMinimumSessionDuration(
      FirebaseAnalytics analytics) async {
    await analytics.android?.setMinimumSessionDuration(20000);
    print('setMinimumSessionDuration succeeded');
  }

  static Future<Null> _testSetSessionTimeoutDuration(
      FirebaseAnalytics analytics) async {
    await analytics.android?.setSessionTimeoutDuration(2000000);
    print('setSessionTimeoutDuration succeeded');
  }

  static Future<Null> _testSetUserProperty(FirebaseAnalytics analytics) async {
    await analytics.setUserProperty(name: 'regular', value: 'indeed');
    print('setUserProperty succeeded');
  }


  Future<Null> _testAllEventTypes(FirebaseAnalytics analytics) async {
    await analytics.logAddPaymentInfo();
    await analytics.logAddToCart(
      currency: 'USD',
      value: 123.0,
      itemId: 'test item id',
      itemName: 'test item name',
      itemCategory: 'test item category',
      quantity: 5,
      price: 24.0,
      origin: 'test origin',
      itemLocationId: 'test location id',
      destination: 'test destination',
      startDate: '2015-09-14',
      endDate: '2015-09-17',
    );
    await analytics.logAddToWishlist(
      itemId: 'test item id',
      itemName: 'test item name',
      itemCategory: 'test item category',
      quantity: 5,
      price: 24.0,
      value: 123.0,
      currency: 'USD',
      itemLocationId: 'test location id',
    );

    await analytics.logBeginCheckout(
      value: 123.0,
      currency: 'USD',
      transactionId: 'test tx id',
      numberOfNights: 2,
      numberOfRooms: 3,
      numberOfPassengers: 4,
      origin: 'test origin',
      destination: 'test destination',
      startDate: '2015-09-14',
      endDate: '2015-09-17',
      travelClass: 'test travel class',
    );
    await analytics.logCampaignDetails(
      source: 'test source',
      medium: 'test medium',
      campaign: 'test campaign',
      term: 'test term',
      content: 'test content',
      aclid: 'test aclid',
      cp1: 'test cp1',
    );
    await analytics.logEarnVirtualCurrency(
      virtualCurrencyName: 'bitcoin',
      value: 345.66,
    );
    await analytics.logEcommercePurchase(
      currency: 'USD',
      value: 432.45,
      transactionId: 'test tx id',
      tax: 3.45,
      shipping: 5.67,
      coupon: 'test coupon',
      location: 'test location',
      numberOfNights: 3,
      numberOfRooms: 4,
      numberOfPassengers: 5,
      origin: 'test origin',
      destination: 'test destination',
      startDate: '2015-09-13',
      endDate: '2015-09-14',
      travelClass: 'test travel class',
    );
    await analytics.logGenerateLead(
      currency: 'USD',
      value: 123.45,
    );
    await analytics.logJoinGroup(
      groupId: 'test group id',
    );
    await analytics.logLevelUp(
      level: 5,
      character: 'witch doctor',
    );
    await analytics.logLogin();
    await analytics.logPostScore(
      score: 1000000,
      level: 70,
      character: 'tiefling cleric',
    );
    await analytics.logPresentOffer(
      itemId: 'test item id',
      itemName: 'test item name',
      itemCategory: 'test item category',
      quantity: 6,
      price: 3.45,
      value: 67.8,
      currency: 'USD',
      itemLocationId: 'test item location id',
    );
    await analytics.logPurchaseRefund(
      currency: 'USD',
      value: 45.67,
      transactionId: 'test tx id',
    );
    await analytics.logSearch(
      searchTerm: 'hotel',
      numberOfNights: 2,
      numberOfRooms: 1,
      numberOfPassengers: 3,
      origin: 'test origin',
      destination: 'test destination',
      startDate: '2015-09-14',
      endDate: '2015-09-16',
      travelClass: 'test travel class',
    );
    await analytics.logSelectContent(
      contentType: 'test content type',
      itemId: 'test item id',
    );
    await analytics.logShare(
      contentType: 'test content type',
      itemId: 'test item id',
    );
    await analytics.logSignUp(
      signUpMethod: 'test sign up method',
    );
    await analytics.logSpendVirtualCurrency(
      itemName: 'test item name',
      virtualCurrencyName: 'bitcoin',
      value: 34,
    );
    await analytics.logTutorialBegin();
    await analytics.logTutorialComplete();
    await analytics.logUnlockAchievement(id: 'all Firebase API covered');
    await analytics.logViewItem(
      itemId: 'test item id',
      itemName: 'test item name',
      itemCategory: 'test item category',
      itemLocationId: 'test item location id',
      price: 3.45,
      quantity: 6,
      currency: 'USD',
      value: 67.8,
      flightNumber: 'test flight number',
      numberOfPassengers: 3,
      numberOfRooms: 1,
      numberOfNights: 2,
      origin: 'test origin',
      destination: 'test destination',
      startDate: '2015-09-14',
      endDate: '2015-09-15',
      searchTerm: 'test search term',
      travelClass: 'test travel class',
    );
    await analytics.logViewItemList(
      itemCategory: 'test item category',
    );
    await analytics.logViewSearchResults(
      searchTerm: 'test search term',
    );
    print('All standard events logged successfully');
  }
}