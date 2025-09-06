import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/navigation/bottom_nav_bar.dart';
import 'features/today/pages/today_page.dart';
import 'features/compass/pages/compass_page.dart';
import 'features/journey/pages/journey_page.dart';
import 'features/horizon/pages/horizon_page.dart';
import 'features/mindmaze/screens/mindmaze_hub_screen.dart';

class SoulBiosApp extends ConsumerStatefulWidget {
  const SoulBiosApp({super.key});

  @override
  ConsumerState<SoulBiosApp> createState() => _SoulBiosAppState();
}

class _SoulBiosAppState extends ConsumerState<SoulBiosApp> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _pages = const [
    TodayPage(),
    CompassPage(),
    JourneyPage(),
    HorizonPage(),
    MindMazeHubScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true, // Extend content behind nav area
      body: Stack(
        children: [
          // Main content
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: _pages,
          ),
          
          // Floating navigation
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: SoulBiosBottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onNavTap,
            ),
          ),
        ],
      ),
    );
  }
}