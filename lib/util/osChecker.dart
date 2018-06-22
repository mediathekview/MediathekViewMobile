import 'dart:async';

import 'package:device_info/device_info.dart';
import 'package:flutter/cupertino.dart';

class OsChecker {

  static Future<TargetPlatform> getTargetPlatform() async{
    DeviceInfoPlugin deviceInfo = new DeviceInfoPlugin();
    try {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      print('Running on ${androidInfo.model}'); // e.g. "Moto G (4)"
      return TargetPlatform.android;
    }
    catch (e){
      print("Running NOT on Android");
    }

    try {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      print('Running on iOS: ${iosInfo.utsname.machine}');  // e.g. "iPod7,1""Moto G (4)"
    }
    catch (e){
      print("Running NOT on IOS - OS unknown. Return default: Android");
      return TargetPlatform.android;
    }
  }
}