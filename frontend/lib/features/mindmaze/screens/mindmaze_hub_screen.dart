import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chamber.dart';
import '../models/mindmaze_insight.dart';
import '../models/character.dart';
import '../widgets/chamber_card.dart';
import '../widgets/insight_card.dart';
import '../models/alice_persona.dart';
import '../../../services/user_service.dart';
import '../../../services/alice_service.dart';
import '../../../services/character_service.dart';
import '../../../services/subscription_service.dart';
import '../../../providers/alice_state_provider.dart';
import '../../../screens/subscription_screen.dart';
import '../../../widgets/animated_chamber_card.dart';
import '../../../widgets/enhanced_alice_avatar.dart';
import '../../../widgets/enhanced_error_dialog.dart';
import 'entrance_hall_screen.dart';
import 'chamber_maze_screen.dart';
import 'alice_chat_screen.dart';

class MindMazeHubScreen extends ConsumerStatefulWidget {
  const MindMazeHubScreen({super.key});

  @override
  ConsumerState<MindMazeHubScreen> createState() => _MindMazeHubScreenState();
}

class _MindMazeHubScreenState extends ConsumerState<MindMazeHubScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  
  List<Chamber> chambers = [];
  List<MindMazeInsight> recentInsights = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseController.repeat(reverse: true);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      final aliceService = ref.read(aliceServiceProvider);
      
      // Load chambers and insights from API
      final results = await Future.wait([
        aliceService.getChamberProgress(),
        aliceService.generateInsights(limit: 3),
      ]);
      
      setState(() {
        chambers = results[0] as List<Chamber>;
        recentInsights = results[1] as List<MindMazeInsight>;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      final userState = ref.watch(userServiceProvider);
      
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A1A),
        body: SafeArea(
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  _buildHeader(userState),
                  Expanded(
                    child: isLoading 
                      ? _buildLoadingState()
                      : !userState.isConnected
                        ? _buildErrorState(userState)
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSafeSection(() => _buildInsightsSection(), 'Insights'),
                                const SizedBox(height: 24),
                                _buildSafeSection(() => _buildEntranceHallSection(), 'Entrance Hall'),
                                const SizedBox(height: 24),
                                _buildSafeSection(() => _buildChambersGrid(), 'Chambers'),
                                const SizedBox(height: 24),
                                _buildSafeSection(() => _buildCharacterProgressSection(), 'Characters'),
                                const SizedBox(height: 100), // Space for bottom nav
                              ],
                            ),
                          ),
                  ),
                ],
              ),
              
              // Enhanced Alice Avatar (with error handling)
              Positioned(
                top: 80,
                right: 20,
                child: _buildSafeAliceAvatar(),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return _buildFallbackMindMaze();
    }
  }

  Widget _buildSafeSection(Widget Function() builder, String sectionName) {
    try {
      return builder();
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D4A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.account_tree,
              color: Colors.amber,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              '$sectionName Loading...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This section is initializing',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSafeAliceAvatar() {
    try {
      final aliceState = ref.watch(aliceStateProvider);
      return EnhancedAliceAvatar(
        size: 80,
        showNotificationBadge: aliceState.shouldShowNotificationBadge,
        onTap: _openAliceChat,
      );
    } catch (e) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.amber, width: 2),
        ),
        child: const Icon(
          Icons.psychology,
          color: Colors.amber,
          size: 32,
        ),
      );
    }
  }

  Widget _buildFallbackMindMaze() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_tree,
                  color: Colors.amber,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Mind Maze Castle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Journey through consciousness chambers',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Loading chambers...',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.amber),
          SizedBox(height: 16),
          Text(
            'Connecting to Alice AI...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(UserState userState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Connection Failed',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            userState.error ?? 'Unable to connect to Alice AI',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(userServiceProvider.notifier).retryConnection();
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: const Text('Retry Connection'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(UserState userState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.amber, width: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_tree,
              color: Colors.amber,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mind Maze Castle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Journey through consciousness chambers',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Reserve space for Alice avatar (positioned absolutely)
          const SizedBox(width: 100),
          _buildOverallProgress(userState),
        ],
      ),
    );
  }

  Widget _buildOverallProgress(UserState userState) {
    final totalCompleted = chambers.fold<int>(
        0, (sum, chamber) => sum + chamber.completedQuestions);
    final totalQuestions = chambers.fold<int>(
        0, (sum, chamber) => sum + chamber.totalQuestions);
    final percentage = totalQuestions > 0 ? totalCompleted / totalQuestions : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D4A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '${(percentage * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (userState.isConnected)
                const Icon(Icons.cloud_done, color: Colors.green, size: 12)
              else
                const Icon(Icons.cloud_off, color: Colors.red, size: 12),
              const SizedBox(width: 4),
              const Text(
                'Complete',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.psychology, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Recent Insights',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Add spacing to prevent overlap with Alice
            SizedBox(width: _getInsightsHeaderSpacing()),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentInsights.length,
            itemBuilder: (context, index) {
              final insight = recentInsights[index];
              final chamber = chambers.firstWhere((c) => c.type == insight.chamber);
              return InsightCard(insight: insight, chamber: chamber);
            },
          ),
        ),
      ],
    );
  }

  double _getInsightsHeaderSpacing() {
    // Simplified spacing - just add some padding for Alice
    return 100; // Fixed spacing to avoid Alice overlap
  }

  Widget _buildEntranceHallSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.home, color: Colors.amber, size: 24),
            SizedBox(width: 8),
            Text(
              'Entrance Hall',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _openEntranceHall,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.05),
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.amber.withValues(alpha: 0.3),
                        const Color(0xFF2D2D4A),
                        const Color(0xFF1A1A2E),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Stack(
                    children: [
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home, color: Colors.amber, size: 48),
                            SizedBox(width: 16),
                            Column(
                              children: [
                                Text(
                                  'Enter Orientation Hall',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Begin your consciousness journey',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 16),
                            Icon(Icons.arrow_forward, color: Colors.amber, size: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChambersGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.room, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Consciousness Chambers',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Add spacing to prevent overlap with Alice
            SizedBox(width: _getChambersHeaderSpacing()),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getGridCrossAxisCount(),
            childAspectRatio: _getGridAspectRatio(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: chambers.length,
          itemBuilder: (context, index) {
            final chamber = chambers[index];
            
            return AnimatedChamberCard(
              chamber: chamber,
              onTap: () => _enterChamber(chamber),
              showUnlockAnimation: chamber.isUnlocked,
            );
          },
        ),
      ],
    );
  }

  double _getChambersHeaderSpacing() {
    // Simplified spacing - just add some padding for Alice
    return 100; // Fixed spacing to avoid Alice overlap
  }

  int _getGridCrossAxisCount() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive grid columns
    if (screenWidth < 400) {
      return 1; // Single column on very narrow screens
    } else if (screenWidth < 600) {
      return 2; // Two columns on medium screens
    } else {
      return 2; // Two columns on wide screens (could be 3 if needed)
    }
  }

  double _getGridAspectRatio() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Adjust aspect ratio based on screen width and column count
    if (screenWidth < 400) {
      return 1.5; // Wider cards for single column
    } else {
      return 1.1; // Standard ratio for two columns
    }
  }

  void _openEntranceHall() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EntranceHallScreen(),
      ),
    );
  }

  void _enterChamber(Chamber chamber) {
    // Check premium access first
    if (!SubscriptionService.instance.isChamberTypeAvailable(chamber.type.value)) {
      _showPremiumChamberDialog(chamber);
      return;
    }
    
    if (!chamber.isUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complete previous chambers to unlock ${chamber.name}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Trigger Alice chamber entry interaction
    ref.read(aliceStateProvider.notifier).enterChamber(
      chamber: chamber.type.value,
      previousVisits: chamber.completedQuestions > 0 ? 1 : 0,
      metadata: {
        'chamber_name': chamber.name,
        'completion_percentage': chamber.completionPercentage,
        'is_unlocked': chamber.isUnlocked,
      },
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChamberMazeScreen(chamber: chamber),
      ),
    );
  }

  void _openAliceChat() {
    // Record Alice interaction
    ref.read(aliceStateProvider.notifier).recordActivity(activityType: 'chat_opened');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AliceChatScreen(),
      ),
    );
  }



  Widget _buildCharacterProgressSection() {
    return Consumer(
      builder: (context, ref, child) {
        final characterState = ref.watch(characterStateProvider);
        
        if (characterState.isLoading) {
          return const SizedBox.shrink();
        }

        final unlockedCount = characterState.availableCharacters
            .where((c) => c.isUnlocked)
            .length;
        final totalCount = characterState.availableCharacters.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Character Guides',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D4A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '$unlockedCount/$totalCount Unlocked',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: characterState.availableCharacters.length,
                itemBuilder: (context, index) {
                  final character = characterState.availableCharacters[index];
                  return _CharacterProgressCard(character: character);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPremiumChamberDialog(Chamber chamber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.diamond, color: Colors.amber),
              const SizedBox(width: 8),
              Text('Premium Chamber'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('The ${chamber.name} is a premium chamber.'),
              const SizedBox(height: 12),
              Text('Free users have access to:'),
              const SizedBox(height: 8),
              ...SubscriptionService.freeChamberTypes.map(
                (type) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text('${type.toUpperCase()} Chamber'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Upgrade to Premium to unlock all chambers!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upgrade Now'),
            ),
          ],
        );
      },
    );
  }
}

class _CharacterProgressCard extends StatelessWidget {
  final Character character;

  const _CharacterProgressCard({required this.character});

  @override
  Widget build(BuildContext context) {
    final cardColor = _getCharacterColor(character.archetype);
    
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: character.isUnlocked 
            ? const Color(0xFF2D2D4A)
            : Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: character.isUnlocked
              ? cardColor.withValues(alpha: 0.5)
              : Colors.grey,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Character icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: character.isUnlocked ? cardColor : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCharacterIcon(character.archetype),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            // Character name
            Text(
              character.name,
              style: TextStyle(
                color: character.isUnlocked ? Colors.white : Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Status
            if (character.isUnlocked)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 16,
              )
            else
              const Icon(
                Icons.lock,
                color: Colors.grey,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Color _getCharacterColor(CharacterArchetype archetype) {
    switch (archetype) {
      case CharacterArchetype.compassionateFriend:
        return Colors.blue;
      case CharacterArchetype.resilientExplorer:
        return Colors.orange;
      case CharacterArchetype.wiseDetective:
        return Colors.purple;
    }
  }

  IconData _getCharacterIcon(CharacterArchetype archetype) {
    switch (archetype) {
      case CharacterArchetype.compassionateFriend:
        return Icons.favorite;
      case CharacterArchetype.resilientExplorer:
        return Icons.explore;
      case CharacterArchetype.wiseDetective:
        return Icons.psychology;
    }
  }
}