import 'package:flutter/material.dart';
import '../../features/today/pages/today_page.dart';
import '../../features/compass/pages/compass_page.dart';
import '../../features/journey/pages/journey_page.dart';
import '../../features/horizon/pages/horizon_page.dart';

class AppRouter {
  static const String today = '/today';
  static const String compass = '/compass';
  static const String journey = '/journey';
  static const String horizon = '/horizon';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case today:
        return MaterialPageRoute(builder: (_) => const TodayPage());
      case compass:
        return MaterialPageRoute(builder: (_) => const CompassPage());
      case journey:
        return MaterialPageRoute(builder: (_) => const JourneyPage());
      case horizon:
        return MaterialPageRoute(builder: (_) => const HorizonPage());
      default:
        return MaterialPageRoute(builder: (_) => const TodayPage());
    }
  }
}