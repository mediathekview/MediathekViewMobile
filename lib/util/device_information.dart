import 'dart:async';

import 'package:device_info/device_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';

class DeviceInformation {
  static final Logger logger = new Logger('OsChecker');
  static TargetPlatform platform;

  static Future<TargetPlatform> getTargetPlatform() async {
    if (platform != null) return platform;

    DeviceInfoPlugin deviceInfo = new DeviceInfoPlugin();
    try {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      logger.info('Running on ${androidInfo.model}'); // e.g. "Moto G (4)"
      platform = TargetPlatform.android;
      return platform;
    } catch (e) {
      logger.fine("Running NOT on Android");
    }

    try {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      logger.info('Running on iOS: ${iosInfo.utsname.machine}');
      platform = TargetPlatform.iOS;
      return platform; // e.g. "iPod7,1""Moto G (4)"
    } catch (e) {
      logger.severe("Running NOT on IOS - OS unknown. Return default: Android");
      return TargetPlatform.android;
    }
  }

  static bool isTablet(BuildContext context) {
    // The equivalent of the "smallestWidth" qualifier on Android.
    var shortestSide = MediaQuery.of(context).size.shortestSide;

    // Determine if we should use mobile layout or not, 600 here is
    // a common breakpoint for a typical 7-inch tablet.
    return shortestSide > 600;
  }
}
