import 'package:flutter/foundation.dart' show kIsWeb;

import 'platform_navigator.dart';
import '_web_navigator.dart' if (dart.library.io) 'platform_utils_noop.dart';

// Factory function to get the appropriate navigator
PlatformNavigator getPlatformNavigator() {
  return kIsWeb ? WebNavigator() : PlatformNavigator();
}
