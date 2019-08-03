import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/util/device_information.dart';
import 'package:logging/logging.dart';

class FilesystemPermissionManager {
  final Logger logger = new Logger('FilesystemPermissionManager');
  EventChannel _eventChannel;
  MethodChannel _methodChannel;
  Stream<dynamic> _updateStream;
  StreamSubscription<dynamic> streamSubscription;
  AppSharedState appWideState;

  FilesystemPermissionManager(
      BuildContext context, AppSharedState appWideState) {
    _eventChannel =
        const EventChannel('com.mediathekview.mobile/permissionEvent');
    _methodChannel = const MethodChannel('com.mediathekview.mobile/permission');
  }

  Stream<dynamic> getBroadcastStream() {
    if (_updateStream == null) {
      _updateStream = _eventChannel.receiveBroadcastStream();
    }
    return _updateStream;
  }

  // request permission. Returns true = already Granted, do not grant again, false = asked for permission
  Future<bool> askUserForPermission() async {
    if (appWideState.appState.targetPlatform == TargetPlatform.android) {
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
    TargetPlatform os = await DeviceInformation.getTargetPlatform();
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
