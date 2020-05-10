import 'package:flutter/material.dart';

import 'device_information.dart';

class CrossAxisCount {
  static int getCrossAxisCount(BuildContext context) {
    bool isTablet = DeviceInformation.isTablet(context);
    Orientation orientation = MediaQuery.of(context).orientation;

    if (isTablet && orientation == Orientation.portrait) {
      return 2;
    } else if (isTablet && orientation == Orientation.landscape) {
      return 3;
    } else if (orientation == Orientation.portrait) {
      return 1;
    } else {
      // mobile & landscape
      return 2;
    }
  }
}
