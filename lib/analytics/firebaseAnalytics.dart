import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

import 'package:flutter_ws/model/Video.dart';
import 'package:flutter_ws/model/VideoEntity.dart';
import 'package:flutter_ws/section/liveTVSection.dart';
import 'package:flutter_ws/widgets/filterMenu/searchFilter.dart';

class Firebase {

  static FirebaseAnalytics analytics;

  static initFirebase(FirebaseAnalytics ana){
    analytics = ana;
  }

  static void sendCurrentTabToAnalytics(FirebaseAnalyticsObserver observer,
      String tabName) {
    observer.analytics.setCurrentScreen(
      screenName: tabName,
    );
  }

  static Future<Null> logPlatformChannelException(String eventName, String message, String os) async {
    Map<String, String> data = new Map();
    data.putIfAbsent("eventName", () => eventName);
    data.putIfAbsent("message", () => message);
    data.putIfAbsent("os", () => os);
    _sendVariousEvent("PlatformChannelException", data);
  }

  static Future<Null> logStreamVideo(Video video) async {
    _sendVariousEvent("StreamVideo", video.toMap());
  }

  static Future<Null> logDownloadVideo(Video video) async {
    _sendVariousEvent("DownloadVideo", video.toMap());
  }

  static Future<Null> logCancleDownloadVideo() async {
    _sendVariousEvent("Cancle", new Map());
  }

  static Future<Null> logStreamDownloadedVideo(VideoEntity entity) async {
    _sendVariousEvent("StreamDownloadedVideo", entity.toMap());
  }

  static Future<Null> logPaypalClicked() async {
    _sendVariousEvent("PaypalClicked", new Map());
  }

  static Future<Null> logStreamChannel(Channel channel) async {
    Map<String, String> data = new Map();
    data.putIfAbsent("name", () => channel.name);
    data.putIfAbsent("group", () => channel.group);
    _sendVariousEvent("StreamChannel", data);
  }

  static Future<Null> logVideoSearch(String query,
      Map<String, SearchFilter> filters) async {
    Map<String, String> data = new Map();
    data.putIfAbsent("SearchInput", () => query);
    filters.forEach((key, filter) {
      data.putIfAbsent("Filter_" + key, () => filter.filterValue);
    });

    _sendVariousEvent("VideoSearch", data);
  }

  static Future<Null> logOperatingSystem(
      String osName) async {
    _sendVariousEvent("OperatingSystem", <String, dynamic>{
      'Os': osName
    },);
  }

  static Future<Null> _sendVariousEvent(String eventName, Map<String, dynamic> parameters) async {
    await analytics.logEvent(
        name: eventName,
        parameters: parameters
    );
    print('Firebase: Event with name ' + eventName + ' logged');
  }
}