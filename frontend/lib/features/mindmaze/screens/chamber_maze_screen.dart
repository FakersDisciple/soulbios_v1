import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../models/chamber.dart';
import '../models/maze_models.dart';
import '../models/character.dart';
import '../widgets/chamber_character_panel.dart';
import '../widgets/narrative_dialogue_widget.dart';
import '../../../providers/alice_state_provider.dart';
import '../../../services/character_service.dart' as character_svc;
import '../../../services/image_generation_service.dart';
import '../../../services/subscription_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_service.dart';
import '../models/chamber_narrative.dart';
import 'chamber_image_gallery_screen.dart';
import '../../../screens/subscription_screen.dart';
import '../../../widgets/enhanced_error_dialog.dart';
import '../../../widgets/animated_loading_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChamberMazeScreen extends ConsumerStatefulWidget {
  final Chamber chamber;

  const ChamberMazeScreen({super.key, required this.chamber});

  @override
  ConsumerState<ChamberMazeScreen> createState() => _ChamberMazeScreenState();
}

class _ChamberMazeScreenState extends ConsumerState<ChamberMazeScreen>
    with TickerProviderStateMixin {
  // Game State
  late Map<String, MazeRoom> rooms;
  late String currentRoomId;
  late Set<Position> revealedPositions;
  late Set<String> completedRooms;
  late List<String> navigationHistory;
  late int correctAnswers;

  // Animation Controllers
  late AnimationController _fogController;
  late AnimationController _pathRevealController;

  // Question State
  String? selectedAnswer;
  int? selectedChoiceIndex;
  String? currentHint;
  bool showingQuestion = false;

  // Character State
  Character? selectedCharacter;
  bool showingNarrative = false;
  NarrativeState? narrativeState;

  @override
  void initState() {
    super.initState();
    // Initialize animations
    _fogController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pathRevealController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    // Initialize game state
    _initializeGameState();
    _fogController.repeat();
    
    // Trigger Alice chamber entry after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aliceStateProvider.notifier).enterChamber(
        chamber: widget.chamber.type.value,
        previousVisits: widget.chamber.completedQuestions > 0 ? 1 : 0,
        metadata: {
          'chamber_name': widget.chamber.name,
          'completion_percentage': widget.chamber.completionPercentage,
          'is_unlocked': widget.chamber.isUnlocked,
        },
      );
    });
  }

  void _initializeGameState() {
    rooms = _getStaticRoomsForChamber(widget.chamber.type.name);
    currentRoomId = 'entrance';
    revealedPositions = {const Position(7, 14)}; // Starting position
    completedRooms = {};
    navigationHistory = [];
    correctAnswers = 0;
    showingQuestion = false;
  }

  @override
  void dispose() {
    _fogController.dispose();
    _pathRevealController.dispose();
    super.dispose();
  }

  // Getters
  MazeRoom get currentRoom => rooms[currentRoomId]!;
  bool get canExit => correctAnswers >= 3; // 3 questions per chamber
  Color get chamberColor => widget.chamber.themeColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Stack(
          children: [
            // Main chamber interface
            Column(
              children: [
                _buildGameHeader(),
                // Top - Room visualization
                Expanded(
                  flex: 3,
                  child: _buildRoomView(),
                ),
                // Bottom - Three panels: Mini-map, Character, and Question
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Character panel at top of bottom section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ChamberCharacterPanel(
                          chamberType: widget.chamber.type.value,
                          selectedCharacter: selectedCharacter,
                          onCharacterSelected: _onCharacterSelected,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Mini-map and Question panel side by side
                      Expanded(
                        child: Row(
                          children: [
                            // Mini-map (left half)
                            Expanded(
                              flex: 1,
                              child: _buildMiniMap(),
                            ),
                            // Question panel (right half)
                            Expanded(
                              flex: 1,
                              child: _buildQuestionPanel(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Narrative dialogue overlay
            if (showingNarrative && selectedCharacter != null)
              NarrativeDialogueWidget(
                chamberId: widget.chamber.type.value,
                character: selectedCharacter!,
                onNarrativeComplete: _onNarrativeComplete,
                onClose: _closeNarrative,
              ),
            
            // Generate Scene button
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: _showGenerateImageDialog,
                backgroundColor: chamberColor,
                child: const Icon(
                  Icons.image,
                  color: Colors.white,
                ),
                tooltip: 'Generate Scene',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        border: Border(bottom: BorderSide(color: chamberColor, width: 2)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Icon(widget.chamber.icon, color: chamberColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.chamber.name} Chamber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentRoom.name,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: canExit ? Colors.green : const Color(0xFF2D2D4A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canExit ? Colors.green : chamberColor,
          width: 2,
        ),
      ),
      child: Text(
        canExit ? 'COMPLETE' : '$correctAnswers/3',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRoomView() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            chamberColor.withValues(alpha: 0.2),
            const Color(0xFF2D2D4A),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chamberColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Expanded(child: _buildRoomVisualization()),
          _buildRoomActions(),
        ],
      ),
    );
  }



  Widget _buildRoomVisualization() {
    return Container(
      margin: const EdgeInsets.all(8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Room background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  chamberColor.withValues(alpha: 0.1),
                  Colors.grey.shade800,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade600),
            ),
          ),
          // Interactive objects
          ...currentRoom.objects.map((obj) => _buildClickableObject(obj)),
          // Door objects (X markers for navigation)
          ..._buildDoorObjects(),
          // Hint overlay
          if (currentHint != null) _buildHintOverlay(),
        ],
      ),
    );
  }

  Widget _buildClickableObject(MazeObject object) {
    final position = _getObjectScreenPosition(object.position);
    return Positioned(
      left: position.dx.clamp(0, 230), // Prevent overflow
      top: position.dy.clamp(0, 150),  // Prevent overflow
      child: GestureDetector(
        onTap: () => _onObjectTapped(object),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: chamberColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: object.hintText != null ? Colors.amber : chamberColor,
              width: object.hintText != null ? 3 : 2,
            ),
            boxShadow: object.hintText != null
                ? [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getObjectIcon(object.id),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  object.name.split(' ').first,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          // Exit button (only show when chamber is complete)
          if (canExit)
            ElevatedButton.icon(
              onPressed: _exitChamber,
              icon: const Icon(Icons.exit_to_app, size: 16),
              label: const Text('Complete Chamber'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildDoorObjects() {
    List<Widget> doors = [];
    
    // Add door for each connected room (always show doors)
    for (int i = 0; i < currentRoom.connectedRooms.length; i++) {
      final roomId = currentRoom.connectedRooms[i];
      final connectedRoom = rooms[roomId];
      if (connectedRoom != null) {
        // Position doors at different locations
        final doorPosition = _getDoorPosition(i);
        final isUnlocked = completedRooms.contains(currentRoom.id);
        final isExitDoor = roomId == 'exit';
        final doorColor = isExitDoor 
            ? Colors.purple 
            : (isUnlocked ? Colors.green : Colors.orange);
        
        doors.add(
          Positioned(
            left: doorPosition.dx,
            top: doorPosition.dy,
            child: GestureDetector(
              onTap: () => _onDoorTapped(roomId),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: doorColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: doorColor, 
                    width: 3
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: doorColor.withValues(alpha: 0.6),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isExitDoor ? '🚪' : 'X',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isExitDoor ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    
    return doors;
  }

  Widget _buildMiniMap() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border.all(color: chamberColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Mini-map header
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D4A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: Row(
              children: [
                Icon(Icons.map, color: chamberColor, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Chamber Map',
                    style: TextStyle(
                      color: chamberColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Fog of war grid
          Expanded(child: _buildSimpleFogGrid()),
        ],
      ),
    );
  }

  Widget _buildSimpleFogGrid() {
    return Container(
      padding: const EdgeInsets.all(4),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 15,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
        ),
        itemCount: 225, // 15x15 grid
        itemBuilder: (context, index) {
          final x = index % 15;
          final y = index ~/ 15;
          final position = Position(x, y);
          final isRevealed = revealedPositions.contains(position);
          final isCurrentRoom = currentRoom.gridPosition == position;
          final roomAtPosition = rooms.values
              .where((room) => room.gridPosition == position)
              .firstOrNull;

          Color tileColor = isRevealed 
              ? Colors.grey.shade600 
              : Colors.grey.shade900;
          Widget? content;

          if (roomAtPosition != null && isRevealed) {
            tileColor = chamberColor.withValues(alpha: 0.8);
            if (isCurrentRoom) {
              content = Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.black, size: 8),
              );
            } else if (completedRooms.contains(roomAtPosition.id)) {
              content = const Icon(Icons.check_circle, color: Colors.green, size: 8);
            } else {
              content = Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: chamberColor,
                  shape: BoxShape.circle,
                ),
              );
            }
          }

          return Container(
            decoration: BoxDecoration(
              color: tileColor,
              border: Border.all(color: Colors.grey.shade700, width: 0.3),
            ),
            child: Center(child: content),
          );
        },
      ),
    );
  }

  Widget _buildQuestionPanel() {
    if (currentRoom.question == null || showingQuestion == false) {
      return Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: chamberColor.withValues(alpha: 0.5)),
        ),
        child: const Center(
          child: Text(
            'Click on doors (X) to navigate\nand answer questions',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final question = currentRoom.question!;
    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3), // Parchment color
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.brown, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: chamberColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              question.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Answer choices and submit button - Use all available space
          Expanded(
            child: Column(
              children: [
                // Answer choices - Take most of the space but evenly distributed
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: question.choices.asMap().entries.map((entry) {
                      final index = entry.key;
                      final choice = entry.value;
                      final label = ['A', 'B', 'C', 'D'][index];
                      final isSelected = selectedChoiceIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() {
                          selectedChoiceIndex = index;
                          selectedAnswer = choice;
                        }),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? chamberColor.withValues(alpha: 0.2)
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? chamberColor
                                  : Colors.grey.shade400,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: chamberColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Center(
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  choice,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Submit button - Take remaining space
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedAnswer != null ? _submitAnswer : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'Submit Answer',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildHintOverlay() {
    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber, width: 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.black, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                currentHint!,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => currentHint = null),
              child: const Icon(Icons.close, color: Colors.black, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // Game Logic Methods
  void _submitAnswer() {
    final question = currentRoom.question!;
    final isCorrect = selectedChoiceIndex == question.correctIndex;

    if (isCorrect) {
      _onCorrectAnswer();
    } else {
      _onIncorrectAnswer(question);
    }
  }

  void _onCorrectAnswer() {
    final newRevealedPositions = Set<Position>.from(revealedPositions);
    
    // Reveal connected rooms
    for (final roomId in currentRoom.connectedRooms) {
      final connectedRoom = rooms[roomId];
      if (connectedRoom != null) {
        newRevealedPositions.add(connectedRoom.gridPosition);
        _revealPathBetween(currentRoom.gridPosition,
            connectedRoom.gridPosition, newRevealedPositions);
      }
    }

    setState(() {
      revealedPositions = newRevealedPositions;
      completedRooms = {...completedRooms, currentRoom.id};
      correctAnswers = correctAnswers + 1;
      showingQuestion = false;
      selectedChoiceIndex = null;
      selectedAnswer = null;
    });

    // Trigger Alice chamber progress interaction
    final completionPercentage = correctAnswers / 3.0; // 3 questions per chamber
    ref.read(aliceStateProvider.notifier).updateChamberProgress(
      chamber: widget.chamber.type.value,
      completionPercentage: completionPercentage,
      activityType: 'question_answered',
      activityData: {
        'room_id': currentRoom.id,
        'room_name': currentRoom.name,
        'question_id': currentRoom.question?.id,
        'correct_answers': correctAnswers,
      },
    );

    // Record user activity for Alice
    ref.read(aliceStateProvider.notifier).recordActivity();

    // Success feedback
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Correct! Doors revealed - click X to navigate.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _onIncorrectAnswer(MazeQuestion question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not quite right'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('The correct answer was: ${question.correctAnswer}'),
            const SizedBox(height: 10),
            Text(question.explanation),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                selectedChoiceIndex = null;
                selectedAnswer = null;
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _revealPathBetween(
      Position from, Position to, Set<Position> revealed) {
    final dx = (to.x - from.x).abs();
    final dy = (to.y - from.y).abs();
    final steps = math.max(dx, dy);

    for (int i = 0; i <= steps; i++) {
      final progress = steps > 0 ? i / steps : 0.0;
      final x = (from.x + (to.x - from.x) * progress).round();
      final y = (from.y + (to.y - from.y) * progress).round();
      revealed.add(Position(x, y));
    }
  }

  void _navigateToRoom(String roomId) {
    setState(() {
      navigationHistory = [...navigationHistory, currentRoomId];
      currentRoomId = roomId;
    });
  }

  void _exitChamber() {
    // Trigger Alice chamber completion interaction
    ref.read(aliceStateProvider.notifier).completeChamber(
      chamber: widget.chamber.type.value,
      completionData: {
        'total_questions': 3,
        'correct_answers': correctAnswers,
        'completion_percentage': 1.0,
        'rooms_completed': completedRooms.length,
        'chamber_name': widget.chamber.name,
      },
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.chamber.name} Complete!'),
        content: Text(
            'You have discovered $correctAnswers insights. Your journey continues.'),
        actions: [
          TextButton(
            onPressed: () {
              // Trigger Alice chamber exit interaction
              ref.read(aliceStateProvider.notifier).exitChamber(
                chamber: widget.chamber.type.value,
                completionPercentage: 1.0,
              );
              
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Exit to chamber selection
            },
            child: const Text('Return to Castle'),
          ),
        ],
      ),
    );
  }

  void _onCharacterSelected(Character character) {
    setState(() {
      selectedCharacter = character;
    });

    // Update Alice with selected character for chamber interactions
    ref.read(aliceStateProvider.notifier).setActiveCharacter(
      character,
      context: {
        'chamber_type': widget.chamber.type.name,
        'chamber_name': widget.chamber.name,
        'character_narrative': ref
            .read(character_svc.characterServiceProvider)
            .getCharacterChamberNarrative(character.archetype, widget.chamber.type.value),
      },
    );

    // Start narrative dialogue if supported
    _startNarrativeDialogue(character);
  }

  Future<void> _startNarrativeDialogue(Character character) async {
    final characterService = ref.read(character_svc.characterServiceProvider);
    final hasNarrative = await characterService.hasNarrativeSupport(
      widget.chamber.type.value,
      character.archetype,
    );

    if (hasNarrative) {
      setState(() {
        showingNarrative = true;
      });
    } else {
      // Show fallback message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            characterService.getCharacterNarrativeIntro(
              character.archetype,
              widget.chamber.type.value,
            ),
          ),
          backgroundColor: character.primaryColor,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _onNarrativeComplete(NarrativeState finalState) {
    setState(() {
      narrativeState = finalState;
      showingNarrative = false;
    });

    // Award progress based on narrative completion
    final progressBonus = (finalState.progressScore / 100).clamp(0.0, 1.0);
    
    // Update Alice with narrative completion
    ref.read(aliceStateProvider.notifier).updateChamberProgress(
      chamber: widget.chamber.type.value,
      completionPercentage: progressBonus,
      activityType: 'narrative_completed',
      activityData: {
        'character_archetype': selectedCharacter?.archetype.value,
        'narrative_score': finalState.progressScore,
        'visited_nodes': finalState.visitedNodes.length,
      },
    );

    // Show completion message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Narrative journey completed! Gained ${finalState.progressScore} insight points.',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _closeNarrative() {
    setState(() {
      showingNarrative = false;
    });
  }

  // Image Generation Methods
  void _showGenerateImageDialog() async {
    final subscriptionService = SubscriptionService.instance;
    
    // Check if user can generate images
    final canGenerate = await subscriptionService.canGenerateImage();
    if (!canGenerate) {
      _showImageLimitDialog();
      return;
    }
    
    // Check if chamber type is available
    if (!subscriptionService.isChamberTypeAvailable(widget.chamber.type.value)) {
      _showPremiumChamberDialog();
      return;
    }
    
    final imageService = ImageGenerationService();
    final suggestions = imageService.getChamberPromptSuggestions(widget.chamber.type.value);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedPrompt = suggestions.first;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.image, color: chamberColor),
                  const SizedBox(width: 8),
                  Text('Generate ${widget.chamber.name} Scene'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose a scene to generate:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedPrompt,
                        isExpanded: true,
                        items: suggestions.map((String prompt) {
                          return DropdownMenuItem<String>(
                            value: prompt,
                            child: Text(
                              prompt,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedPrompt = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (selectedCharacter != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedCharacter!.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: selectedCharacter!.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: selectedCharacter!.primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Style: ${selectedCharacter!.name} perspective',
                              style: TextStyle(
                                color: selectedCharacter!.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'This will create a unique AI-generated image for your chamber experience.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _generateChamberImage(selectedPrompt);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: chamberColor,
                  ),
                  child: const Text(
                    'Generate Image',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _generateChamberImage(String prompt) async {
    final imageService = ref.read(imageGenerationServiceProvider);
    
    try {
      // Show enhanced loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const AnimatedLoadingWidget(
              type: LoadingType.imageGeneration,
              message: 'Creating your chamber scene...',
            ),
          ),
        ),
      );
      
      // Generate image with chamber and character context
      final response = await imageService.generateImageWithConfirmation(
        context: context,
        userId: 'chamber_user_${widget.chamber.type.value}', // In production, use actual user ID
        prompt: prompt,
        chamberType: widget.chamber.type.value,
        characterArchetype: selectedCharacter?.archetype.value,
      );
      
      // Hide loading dialog
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      if (response != null && response.isSuccess && response.imageUrl != null) {
        // Record usage for free tier tracking
        await SubscriptionService.instance.recordImageGeneration();
        
        // Cache the image locally
        if (response.imageId != null) {
          await imageService.cacheImageLocally(response.imageId!, response.imageUrl!);
        }
        
        // Show the generated image
        _showGeneratedImageModal(response.imageUrl!, response.promptUsed);
        
        // Update Alice with image generation activity
        ref.read(aliceStateProvider.notifier).recordActivity();
        
        // Show success feedback with animation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Scene generated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'View Gallery',
              textColor: Colors.white,
              onPressed: _showImageGallery,
            ),
          ),
        );
      } else if (response != null && response.hasError) {
        _showImageGenerationError(response.errorMessage ?? 'Unknown error occurred');
      }
    } catch (e) {
      // Hide loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      _showImageGenerationError('Image generation failed: $e');
    }
  }

  void _showGeneratedImageModal(String imageUrl, String promptUsed) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: chamberColor, width: 2),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: chamberColor.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.image, color: chamberColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.chamber.name} Scene',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              
              // Image
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        height: 200,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 48),
                              SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Prompt info
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generated from:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      promptUsed,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showImageGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('View Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: chamberColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showGenerateImageDialog();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Generate New'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImageGenerationError(String errorMessage) {
    ErrorDialogHelper.showImageGenerationError(
      context,
      customMessage: errorMessage,
      onRetry: _showGenerateImageDialog,
    );
  }

  void _showImageLimitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<int>(
          future: SubscriptionService.instance.getRemainingFreeGenerations(),
          builder: (context, snapshot) {
            final remaining = snapshot.data ?? 0;
            
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('Daily Limit Reached'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You\'ve used all $SubscriptionService.freeImageGenerationsPerDay free image generations for today.'),
                  const SizedBox(height: 12),
                  Text('Remaining: $remaining'),
                  const SizedBox(height: 16),
                  Text(
                    'Upgrade to Premium for unlimited image generation!',
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
      },
    );
  }

  void _showPremiumChamberDialog() {
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
              Text('The ${widget.chamber.name} is a premium chamber.'),
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
                'Upgrade to Premium to unlock all chambers and unlimited features!',
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

  void _showImageGallery() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChamberImageGalleryScreen(
          chamberType: widget.chamber.type.value,
          chamberName: widget.chamber.name,
          chamberColor: chamberColor,
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

  void _onObjectTapped(MazeObject object) {
    HapticFeedback.lightImpact();
    
    // Record user activity for Alice
    ref.read(aliceStateProvider.notifier).recordActivity();
    
    if (object.hintText != null) {
      setState(() {
        currentHint = object.hintText;
      });
      
      // Request contextual hint from Alice with character context
      ref.read(aliceStateProvider.notifier).getContextualHint(
        hintKey: 'object_interaction',
        context: {
          'object_id': object.id,
          'object_name': object.name,
          'room_id': currentRoom.id,
          'selected_character': selectedCharacter?.archetype.value,
        },
      );
      
      // Auto-hide hint after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && currentHint == object.hintText) {
          setState(() => currentHint = null);
        }
      });
    }
    
    // Show object description
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(object.description),
        backgroundColor: chamberColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Helper methods
  Offset _getObjectScreenPosition(Position gridPos) {
    const roomWidth = 280.0;
    const roomHeight = 180.0;
    const gridWidth = 10;
    const gridHeight = 8;
    
    return Offset(
      (gridPos.x / gridWidth) * (roomWidth - 50), // Account for object width
      (gridPos.y / gridHeight) * (roomHeight - 50), // Account for object height
    );
  }

  Offset _getDoorPosition(int doorIndex) {
    // Position doors at different locations around the room
    // Use relative positioning that works with expanded room
    switch (doorIndex % 4) {
      case 0: // Top center
        return const Offset(200, 20);
      case 1: // Right center  
        return const Offset(350, 120);
      case 2: // Bottom center
        return const Offset(200, 220);
      case 3: // Left center
        return const Offset(50, 120);
      default:
        return const Offset(200, 20);
    }
  }

  void _onDoorTapped(String roomId) {
    final targetRoom = rooms[roomId];
    if (targetRoom == null) return;
    
    // Record user activity for Alice
    ref.read(aliceStateProvider.notifier).recordActivity();
    
    // Handle exit door
    if (roomId == 'exit') {
      _exitChamber();
      return;
    }
    
    // Navigate to the room and show its question
    setState(() {
      navigationHistory = [...navigationHistory, currentRoomId];
      currentRoomId = roomId;
      showingQuestion = true;
      selectedChoiceIndex = null;
      selectedAnswer = null;
    });
    
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Entered ${targetRoom.name}'),
        backgroundColor: chamberColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  IconData _getObjectIcon(String objectId) {
    if (objectId.contains('orb')) return Icons.circle;
    if (objectId.contains('mirror')) return Icons.face;
    if (objectId.contains('tome')) return Icons.menu_book;
    if (objectId.contains('stone')) return Icons.diamond;
    if (objectId.contains('crystal')) return Icons.auto_awesome;
    if (objectId.contains('chalice')) return Icons.local_drink;
    if (objectId.contains('shield')) return Icons.shield;
    if (objectId.contains('compass')) return Icons.explore;
    if (objectId.contains('key')) return Icons.vpn_key;
    if (objectId.contains('book')) return Icons.menu_book;
    if (objectId.contains('candle')) return Icons.local_fire_department;
    return Icons.help_outline;
  }

  // Static room data for testing
  Map<String, MazeRoom> _getStaticRoomsForChamber(String chamber) {
    return {
      'entrance': MazeRoom(
        id: 'entrance',
        name: 'Gateway',
        description: 'The entrance to the $chamber chamber',
        gridPosition: const Position(7, 14),
        question: MazeQuestion(
          id: '${chamber}_test',
          text: 'What is the first step in understanding your $chamber patterns?',
          choices: [
            'Self-awareness and observation',
            'Immediate action',
            'Seeking external validation',
            'Avoiding the issue'
          ],
          correctIndex: 0,
          hint: 'Think about the foundation of personal growth',
          explanation:
              'Self-awareness through observation is the foundation of understanding any personal pattern.',
        ),
        objects: [
          MazeObject(
            id: 'crystal',
            name: 'Insight Crystal',
            position: const Position(2, 3),
            description: 'A glowing crystal of wisdom',
            hintText: 'Look within to find the answers you seek',
          ),
        ],
        connectedRooms: ['inner_sanctum'],
        isUnlocked: true,
        isCompleted: false,
        themeColor: widget.chamber.themeColor,
      ),
      'inner_sanctum': MazeRoom(
        id: 'inner_sanctum',
        name: 'Inner Sanctum',
        description: 'The heart of the $chamber chamber',
        gridPosition: const Position(5, 10),
        question: MazeQuestion(
          id: '${chamber}_inner',
          text: 'How do you integrate new insights about your $chamber?',
          choices: [
            'Practice and consistent application',
            'Just thinking about it',
            'Telling others about it',
            'Writing it down once'
          ],
          correctIndex: 0,
          hint: 'Integration requires action, not just understanding',
          explanation:
              'True integration comes through consistent practice and application of insights.',
        ),
        objects: [
          MazeObject(
            id: 'mirror',
            name: 'Truth Mirror',
            position: const Position(4, 2),
            description: 'A mirror that shows inner truth',
            hintText: 'The truth you seek is already within you',
          ),
        ],
        connectedRooms: ['wisdom_vault'],
        isUnlocked: false,
        isCompleted: false,
        themeColor: widget.chamber.themeColor,
      ),
      'wisdom_vault': MazeRoom(
        id: 'wisdom_vault',
        name: 'Wisdom Vault',
        description: 'The final chamber of $chamber mastery',
        gridPosition: const Position(3, 6),
        question: MazeQuestion(
          id: '${chamber}_final',
          text: 'What is the ultimate goal of working with your $chamber?',
          choices: [
            'To become a better version of yourself',
            'To impress others',
            'To avoid all challenges',
            'To control everything'
          ],
          correctIndex: 0,
          hint: 'Growth is about becoming, not controlling',
          explanation:
              'The ultimate goal is personal growth and becoming the best version of yourself.',
        ),
        objects: [
          MazeObject(
            id: 'book',
            name: 'Wisdom Tome',
            position: const Position(3, 4),
            description: 'An ancient book of wisdom',
            hintText: 'Wisdom comes from experience, not just knowledge',
          ),
        ],
        connectedRooms: ['exit'],
        isUnlocked: false,
        isCompleted: false,
        themeColor: widget.chamber.themeColor,
      ),
      'exit': MazeRoom(
        id: 'exit',
        name: 'Chamber Exit',
        description: 'The way out of the $chamber chamber',
        gridPosition: const Position(1, 3),
        question: null, // No question for exit
        objects: [],
        connectedRooms: [],
        isUnlocked: false,
        isCompleted: false,
        themeColor: widget.chamber.themeColor,
      ),
    };
  }
}

// Extension for null safety
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}