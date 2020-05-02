import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

const ERROR_MSG_CAST_FAILED = "Cast zu Samsung TV fehlgeschlagen.";
const ERROR_GENERAL_CAST = "Es ist ein Fehler aufgetreten.";
const ERROR_MSG_CONNECTION_FAILED = "Verbindung zu Samsung TV fehlgeschlagen.";
const ERROR_MSG_TV_DISCOVERY_FAILED = "Suche nach Samsung TV's fehlgeschlagen.";
const ERROR_MSG_PLAY_FAILED = "Abspielen fehlgeschlagen.";

// SamsungTVCastManager has the platform channels to talk to the native iOS implementation for casting videos to supported Samsung TVs
class SamsungTVCastManager {
  final Logger logger = new Logger('SamsungTvCastManager');
  EventChannel _tvFoundEventChannel;
  EventChannel _tvLostEventChannel;
  EventChannel _tvReadinessEventChannel;
  EventChannel _tvPlayerEventChannel;
  EventChannel _tvPlaybackPositionEventChannel;

  MethodChannel _methodChannel;
  Stream<dynamic> _foundTvsStream;
  Stream<dynamic> _lostTvsStream;
  Stream<dynamic> _tvReadinessStream;
  Stream<dynamic> _tvPlayerStream;
  Stream<dynamic> _tvPlaybackPositionStream;

  SamsungTVCastManager(BuildContext context) {
    _methodChannel =
        const MethodChannel('com.mediathekview.mobile/samsungTVCast');
    _tvFoundEventChannel =
        const EventChannel('com.mediathekview.mobile/samsungTVFound');
    _tvLostEventChannel =
        const EventChannel('com.mediathekview.mobile/samsungTVLost');
    _tvReadinessEventChannel =
        const EventChannel('com.mediathekview.mobile/samsungTVReadiness');
    _tvPlayerEventChannel =
        const EventChannel('com.mediathekview.mobile/samsungTVPlayer');
    _tvPlaybackPositionEventChannel = const EventChannel(
        'com.mediathekview.mobile/samsungTVPlaybackPosition');
  }

  Future startTVDiscovery() async {
    try {
      Map<String, String> requestArguments = new Map();
      await _methodChannel.invokeMethod('startDiscovery', requestArguments);
    } on PlatformException catch (e) {
      logger.severe(
          "Starting samsung tv discovery failed. Reason " + e.toString());
    } on MissingPluginException catch (e) {
      logger.severe("Starting samsung tv discovery failed. Missing Plugin: " +
          e.toString());
    }
  }

  Future stopTVDiscovery() async {
    try {
      Map<String, String> requestArguments = new Map();
      await _methodChannel.invokeMethod('stopDiscovery', requestArguments);
    } on PlatformException catch (e) {
      logger.severe(
          "Stopping samsung tv discovery failed. Reason " + e.toString());
    } on MissingPluginException catch (e) {
      logger.severe("Stopping samsung tv discovery failed. Missing Plugin: " +
          e.toString());
    }
  }

  void checkIfTvIsSupported(String tvName) async {
    Map<String, String> requestArguments = new Map();
    requestArguments.putIfAbsent("tvName", () => tvName);

    try {
      await _methodChannel.invokeMethod('check', requestArguments);
    } on PlatformException catch (e) {
      logger.severe(
          "Starting samsung tv readiness check failed. Reason " + e.toString());
    } on MissingPluginException catch (e) {
      logger.severe(
          "Starting samsung tv readiness check failed. Missing Plugin: " +
              e.toString());
    }
  }

  Future play(String videoUrl, String title, Duration startingPosition) async {
    Map<String, String> requestArguments = new Map();
    // has to be url accessible from internet (do not support downloaded videos)
    requestArguments.putIfAbsent("url", () => videoUrl);
    requestArguments.putIfAbsent("title", () => title);
    requestArguments.putIfAbsent(
        "startingPosition", () => startingPosition.inMilliseconds.toString());

    try {
      _methodChannel.invokeMethod('play', requestArguments);
    } on PlatformException catch (e) {
      logger
          .severe("Playing video on Samsung TV failed. Reason " + e.toString());
    } on MissingPluginException catch (e) {
      logger.severe("Playing video on Samsung TV failed. Missing Plugin: " +
          e.toString());
    }
  }

  Future seekTo(Duration seek) async {
    Map<String, String> requestArguments = new Map();
    requestArguments.putIfAbsent(
        "seekTo", () => seek.inMilliseconds.toString());

    try {
      await _methodChannel.invokeMethod('seekTo', requestArguments);
    } on PlatformException catch (e) {
      logger.severe(
          "Seeking to video position on Samsung TV failed " + e.toString());
    } on MissingPluginException catch (e) {
      logger.severe(
          "Seeking to video position on Samsung TV failed. Missing Plugin: " +
              e.toString());
    }
  }

  Future pause() async {
    Map<String, String> requestArguments = new Map();
    try {
      await _methodChannel.invokeMethod('pause', requestArguments);
    } on PlatformException catch (e) {
      logger.severe("Pausing video on Samsung TV failed " + e.toString());
    } on MissingPluginException catch (e) {
      logger.severe("Pausing video on Samsung TV failed. Missing Plugin: " +
          e.toString());
    }
  }

  Future disconnect() async {
    Map<String, String> requestArguments = new Map();
    try {
      await _methodChannel.invokeMethod('disconnect', requestArguments);
    } on PlatformException catch (e) {
      logger.severe("Disconnecting from Samsung TV failed " + e.toString());
    } on MissingPluginException catch (e) {
      logger.severe("Disconnecting from Samsung TV failed. Missing Plugin: " +
          e.toString());
    }
  }

  Future stop() async {
    Map<String, String> requestArguments = new Map();
    try {
      await _methodChannel.invokeMethod('stop', requestArguments);
    } on PlatformException catch (e) {
      logger.severe("Stopping video on Samsung TV failed " + e.toString());
    } on MissingPluginException catch (e) {
      logger.severe("Stopping video on Samsung TV failed. Missing Plugin: " +
          e.toString());
    }
  }

  Future resume() async {
    Map<String, String> requestArguments = new Map();
    try {
      _methodChannel.invokeMethod('resume', requestArguments);
    } on PlatformException catch (e) {
      logger.severe("Resuming video on Samsung TV failed " + e.toString());
    } on MissingPluginException catch (e) {
      logger.severe("Resuming video on Samsung TV failed. Missing Plugin: " +
          e.toString());
    }
  }

  Future mute() async {
    Map<String, String> requestArguments = new Map();
    try {
      _methodChannel.invokeMethod('mute', requestArguments);
    } on PlatformException catch (e) {
      logger.severe("Muting video on Samsung TV failed " + e.toString());
    } on MissingPluginException catch (e) {
      logger.severe(
          "Muting video on Samsung TV failed. Missing Plugin: " + e.toString());
    }
  }

  Future unmute() async {
    Map<String, String> requestArguments = new Map();
    try {
      _methodChannel.invokeMethod('unmute', requestArguments);
    } on PlatformException catch (e) {
//      SnackbarActions.showError(ctx, ERROR_GENERAL_CAST);
      logger.severe("Unmuting video on Samsung TV failed " + e.toString());
    } on MissingPluginException catch (e) {
//      SnackbarActions.showError(ctx, ERROR_GENERAL_CAST);
      logger.severe("Unmuting video on Samsung TV failed. Missing Plugin: " +
          e.toString());
    }
  }

  Stream<dynamic> getFoundTVStream() {
    if (_foundTvsStream == null) {
      _foundTvsStream = _tvFoundEventChannel.receiveBroadcastStream();
    }
    return _foundTvsStream;
  }

  Stream<dynamic> getLostTVStream() {
    if (_lostTvsStream == null) {
      _lostTvsStream = _tvLostEventChannel.receiveBroadcastStream();
    }
    return _lostTvsStream;
  }

  Stream<dynamic> getTvReadinessStream() {
    if (_tvReadinessStream == null) {
      _tvReadinessStream = _tvReadinessEventChannel.receiveBroadcastStream();
    }
    return _tvReadinessStream;
  }

  Stream<dynamic> getTvPlayerStream() {
    if (_tvPlayerStream == null) {
      _tvPlayerStream = _tvPlayerEventChannel.receiveBroadcastStream();
    }
    return _tvPlayerStream;
  }

  Stream<dynamic> getTvPlaybackPositionStream() {
    if (_tvPlaybackPositionStream == null) {
      _tvPlaybackPositionStream =
          _tvPlaybackPositionEventChannel.receiveBroadcastStream();
    }
    return _tvPlaybackPositionStream;
  }
}
