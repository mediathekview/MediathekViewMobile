import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ws/util/os_checker.dart';
import 'package:logging/logging.dart';

class FilesystemPermissionManager {
  final Logger logger = new Logger('FilesystemPermissionManager');
  EventChannel _eventChannel;
  MethodChannel _methodChannel;
  Stream<dynamic> _updateStream;
  StreamSubscription<dynamic> streamSubscription;

  FilesystemPermissionManager(BuildContext context) {
    _eventChannel = const EventChannel('samples.flutter.io/permissionEvent');
    _methodChannel = const MethodChannel('samples.flutter.io/permission');
  }

  Stream<dynamic> getBroadcastStream() {
    if (_updateStream == null) {
      _updateStream = _eventChannel.receiveBroadcastStream();
    }
    return _updateStream;
  }

  // request permission. Returns true = already Granted, do not grant again, false = asked for permission
  Future<bool> askUserForPermission() async {
    TargetPlatform os = await OsChecker.getTargetPlatform();
    if (os == TargetPlatform.android) {
      try {
        _methodChannel.invokeMethod('askUserForPermission').then((result) {
          String res = result['AlreadyGranted'];
          bool alreadyGranted = res.toLowerCase() == 'true';
          return alreadyGranted;
        });
      } on PlatformException catch (e) {
        logger.severe(
            "Asking for Android FileSystemPermissions failed. Reason " +
                e.toString());

        return false;
      }
    }
    //Asking for filesystem permissions only required on Android
    return true;
  }

  Future<bool> hasFilesystemPermission() async {
    TargetPlatform os = await OsChecker.getTargetPlatform();
    if (os == TargetPlatform.android) {
      try {
        return _methodChannel
            .invokeMethod('hasFilesystemPermission')
            .then((result) {
          String perm = result['hasPermission'];
          bool hasPermission = perm.toLowerCase() == 'true';
          return hasPermission;
        });
      } on PlatformException catch (e) {
        logger.severe(
            "Checking for Asking for Android FileSystemPermissions failed. Reason " +
                e.toString());

        return false;
      }
    }
    //filesystem permissions only required on Android
    return true;
  }
}
