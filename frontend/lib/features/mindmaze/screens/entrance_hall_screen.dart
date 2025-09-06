import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/chamber.dart';
import 'chamber_maze_screen.dart';

class EntranceHallScreen extends StatefulWidget {
  const EntranceHallScreen({super.key});

  @override
  State<EntranceHallScreen> createState() => _EntranceHallScreenState();
}

class _EntranceHallScreenState extends State<EntranceHallScreen>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late AnimationController _chamberRevealController;
  bool isLoading = true;
  bool showChamberSelection = false;

  final List<Chamber> availableChambers = [
    const Chamber(
      type: ChamberType.emotion,
      name: "Emotion Chamber",
      description: "Explore your emotional landscape",
      themeColor: Colors.blue,
      icon: Icons.favorite,
    ),
    const Chamber(
      type: ChamberType.pattern,
      name: "Pattern Library",
      description: "Discover your behavioral patterns",
      themeColor: Colors.purple,
      icon: Icons.library_books,
    ),
    const Chamber(
      type: ChamberType.fortress,
      name: "Fortress Tower",
      description: "Face your defensive patterns",
      themeColor: Colors.grey,
      icon: Icons.security,
      isUnlocked: false,
    ),
    const Chamber(
      type: ChamberType.wisdom,
      name: "Wisdom Sanctum",
      description: "Synthesize your insights",
      themeColor: Colors.orange,
      icon: Icons.lightbulb,
      isUnlocked: false,
    ),
    const Chamber(
      type: ChamberType.transcendent,
      name: "Transcendent Peak",
      description: "Achieve unity consciousness",
      themeColor: Colors.white,
      icon: Icons.star,
      isUnlocked: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _chamberRevealController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _startLoadingSequence();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _chamberRevealController.dispose();
    super.dispose();
  }

  void _startLoadingSequence() async {
    _loadingController.forward();
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      isLoading = false;
      showChamberSelection = true;
    });
    _chamberRevealController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Colors.amber.withValues(alpha: 0.1),
                  const Color(0xFF1A1A2E),
                  const Color(0xFF0A0A1A),
                ],
              ),
            ),
          ),
          if (isLoading) _buildLoadingScreen(),
          if (showChamberSelection) _buildChamberSelection(),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loadingController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (_loadingController.value * 0.4),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.home,
                    color: Colors.amber,
                    size: 48,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Entering Consciousness Castle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Preparing your personalized journey...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: Colors.white30,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChamberSelection() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Entrance Hall',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Choose your consciousness chamber',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Chamber selection
            Expanded(
              child: AnimatedBuilder(
                animation: _chamberRevealController,
                builder: (context, child) {
                  return GridView.builder(
                    padding: const EdgeInsets.only(bottom: 80), // Add bottom padding
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: availableChambers.length,
                    itemBuilder: (context, index) {
                      final delay = index * 0.1;
                      final animationValue = math.max(
                          0.0, _chamberRevealController.value - delay);
                      return Transform.translate(
                        offset: Offset(0, (1 - animationValue) * 50),
                        child: Opacity(
                          opacity: animationValue,
                          child: _buildChamberOptionCard(availableChambers[index]),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChamberOptionCard(Chamber chamber) {
    return GestureDetector(
      onTap: chamber.isUnlocked ? () => _startChamberMaze(chamber) : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: chamber.isUnlocked
              ? LinearGradient(
                  colors: [
                    chamber.themeColor.withValues(alpha: 0.3),
                    const Color(0xFF2D2D4A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [
                    Color(0x33808080),
                    Color(0xFF2D2D4A),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: chamber.isUnlocked
                ? chamber.themeColor.withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Icon section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: chamber.isUnlocked
                      ? chamber.themeColor.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  chamber.icon,
                  color: chamber.isUnlocked ? chamber.themeColor : Colors.grey,
                  size: 28,
                ),
              ),
              // Text section
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      chamber.name,
                      style: TextStyle(
                        color: chamber.isUnlocked ? Colors.white : Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chamber.description,
                      style: TextStyle(
                        color: chamber.isUnlocked ? Colors.white70 : Colors.grey,
                        fontSize: 10,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Lock indicator
              if (!chamber.isUnlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, color: Colors.grey, size: 10),
                      SizedBox(width: 2),
                      Text(
                        'Locked',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _startChamberMaze(Chamber chamber) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChamberMazeScreen(chamber: chamber),
      ),
    );
  }
}