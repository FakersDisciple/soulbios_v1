
import '../features/mindmaze/models/chamber_narrative.dart';
import '../features/mindmaze/models/character.dart';

class NarrativeService {
  static final NarrativeService _instance = NarrativeService._internal();
  factory NarrativeService() => _instance;
  NarrativeService._internal();

  final Map<String, ChamberNarrative> _narratives = {};
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Load narrative data for each chamber-character combination
    await _loadEmotionChamberNarratives();
    await _loadFortressChamberNarratives();
    
    _initialized = true;
  }

  Future<void> _loadEmotionChamberNarratives() async {
    // Compassionate Friend - Emotion Chamber
    _narratives['emotion_compassionate_friend'] = ChamberNarrative(
      chamberId: 'emotion',
      characterArchetype: CharacterArchetype.compassionateFriend,
      startNodeId: 'emotion_cf_start',
      completionNodeIds: ['emotion_cf_complete'],
      nodes: {
        'emotion_cf_start': const NarrativeNode(
          id: 'emotion_cf_start',
          type: NarrativeNodeType.dialogue,
          content: "I can sense the emotional currents flowing through this chamber. Your feelings are like colors painting the walls around us - each one valid and beautiful in its own way. What emotion feels strongest for you right now?",
          choices: [
            NarrativeChoice(
              id: 'cf_emotion_anxious',
              text: "I'm feeling anxious and overwhelmed",
              targetNodeId: 'emotion_cf_anxiety_path',
            ),
            NarrativeChoice(
              id: 'cf_emotion_sad',
              text: "There's a deep sadness I can't shake",
              targetNodeId: 'emotion_cf_sadness_path',
            ),
            NarrativeChoice(
              id: 'cf_emotion_confused',
              text: "I'm confused about what I'm feeling",
              targetNodeId: 'emotion_cf_confusion_path',
            ),
          ],
        ),
        'emotion_cf_anxiety_path': const NarrativeNode(
          id: 'emotion_cf_anxiety_path',
          type: NarrativeNodeType.dialogue,
          content: "I can feel the weight of what you're carrying. Anxiety often shows up when our hearts are trying to protect us from something. Let's sit with this feeling together - you don't have to face it alone.",
          nextNodeId: 'emotion_cf_insight_1',
        ),
        'emotion_cf_sadness_path': const NarrativeNode(
          id: 'emotion_cf_sadness_path',
          type: NarrativeNodeType.dialogue,
          content: "Your sadness is sacred - it shows how deeply you can love and care. Sometimes our tears are the soul's way of washing clean what needs healing. I'm here to hold space for whatever you're feeling.",
          nextNodeId: 'emotion_cf_insight_1',
        ),
        'emotion_cf_confusion_path': const NarrativeNode(
          id: 'emotion_cf_confusion_path',
          type: NarrativeNodeType.dialogue,
          content: "Confusion is often wisdom in disguise - your psyche is processing something important. Sometimes we need to sit in the not-knowing before clarity emerges. What if we explored this uncertainty together?",
          nextNodeId: 'emotion_cf_insight_1',
        ),
        'emotion_cf_insight_1': const NarrativeNode(
          id: 'emotion_cf_insight_1',
          type: NarrativeNodeType.insight,
          content: "💝 Insight: Your emotions are messengers, not enemies. Each feeling carries wisdom about what you need for healing and growth.",
          nextNodeId: 'emotion_cf_complete',
        ),
        'emotion_cf_complete': const NarrativeNode(
          id: 'emotion_cf_complete',
          type: NarrativeNodeType.completion,
          content: "You've shown such courage in exploring your emotional landscape. Remember, I'm always here when you need a compassionate presence to witness your journey.",
        ),
      },
    );

    // Resilient Explorer - Emotion Chamber
    _narratives['emotion_resilient_explorer'] = ChamberNarrative(
      chamberId: 'emotion',
      characterArchetype: CharacterArchetype.resilientExplorer,
      startNodeId: 'emotion_re_start',
      completionNodeIds: ['emotion_re_complete'],
      nodes: {
        'emotion_re_start': const NarrativeNode(
          id: 'emotion_re_start',
          type: NarrativeNodeType.dialogue,
          content: "Welcome to the Emotion Chamber, brave explorer! This is where we transform emotional challenges into stepping stones for growth. I can sense your inner strength - what emotional territory are you ready to explore today?",
          choices: [
            NarrativeChoice(
              id: 're_emotion_fear',
              text: "I want to face my fears",
              targetNodeId: 'emotion_re_fear_path',
            ),
            NarrativeChoice(
              id: 're_emotion_anger',
              text: "I'm dealing with anger or frustration",
              targetNodeId: 'emotion_re_anger_path',
            ),
            NarrativeChoice(
              id: 're_emotion_growth',
              text: "I want to grow beyond my comfort zone",
              targetNodeId: 'emotion_re_growth_path',
            ),
          ],
        ),
        'emotion_re_fear_path': const NarrativeNode(
          id: 'emotion_re_fear_path',
          type: NarrativeNodeType.dialogue,
          content: "Fear is just excitement without breath! What if we reframed this fear as your growth edge calling? Every hero's journey begins with facing what scares them most. You're stronger than you realize - let's prove it together!",
          nextNodeId: 'emotion_re_insight_1',
        ),
        'emotion_re_anger_path': const NarrativeNode(
          id: 'emotion_re_anger_path',
          type: NarrativeNodeType.dialogue,
          content: "I hear the fire in your voice - that's your inner warrior wanting to break through! Anger often shows us where our boundaries need strengthening. Let's channel this powerful energy into positive transformation!",
          nextNodeId: 'emotion_re_insight_1',
        ),
        'emotion_re_growth_path': const NarrativeNode(
          id: 'emotion_re_growth_path',
          type: NarrativeNodeType.dialogue,
          content: "Yes! I can feel your enthusiasm for growth. The comfort zone is a beautiful place, but nothing ever grows there. What would it look like to lean into this discomfort with curiosity and courage?",
          nextNodeId: 'emotion_re_insight_1',
        ),
        'emotion_re_insight_1': const NarrativeNode(
          id: 'emotion_re_insight_1',
          type: NarrativeNodeType.insight,
          content: "🚀 Insight: Every emotion is energy in motion. When you learn to surf the waves instead of fighting them, you become unstoppable.",
          nextNodeId: 'emotion_re_complete',
        ),
        'emotion_re_complete': const NarrativeNode(
          id: 'emotion_re_complete',
          type: NarrativeNodeType.completion,
          content: "You've shown incredible courage in this exploration! Remember, every challenge is just another adventure waiting to reveal your hidden strengths. Keep pushing those boundaries!",
        ),
      },
    );

    // Wise Detective - Emotion Chamber
    _narratives['emotion_wise_detective'] = ChamberNarrative(
      chamberId: 'emotion',
      characterArchetype: CharacterArchetype.wiseDetective,
      startNodeId: 'emotion_wd_start',
      completionNodeIds: ['emotion_wd_complete'],
      nodes: {
        'emotion_wd_start': const NarrativeNode(
          id: 'emotion_wd_start',
          type: NarrativeNodeType.dialogue,
          content: "Fascinating... I'm detecting complex emotional patterns in this chamber. Every emotion is a clue in the mystery of your consciousness. Let's investigate what your psyche is trying to reveal. What emotional pattern keeps recurring in your life?",
          choices: [
            NarrativeChoice(
              id: 'wd_emotion_patterns',
              text: "I keep repeating the same emotional cycles",
              targetNodeId: 'emotion_wd_cycles_path',
            ),
            NarrativeChoice(
              id: 'wd_emotion_triggers',
              text: "Certain situations always trigger me",
              targetNodeId: 'emotion_wd_triggers_path',
            ),
            NarrativeChoice(
              id: 'wd_emotion_mystery',
              text: "I have emotions I don't understand",
              targetNodeId: 'emotion_wd_mystery_path',
            ),
          ],
        ),
        'emotion_wd_cycles_path': const NarrativeNode(
          id: 'emotion_wd_cycles_path',
          type: NarrativeNodeType.dialogue,
          content: "Ah, I see this pattern emerging again. Emotional cycles are like archaeological layers - each repetition is trying to teach you something deeper. What do you think this pattern is trying to show you about your needs or boundaries?",
          nextNodeId: 'emotion_wd_insight_1',
        ),
        'emotion_wd_triggers_path': const NarrativeNode(
          id: 'emotion_wd_triggers_path',
          type: NarrativeNodeType.dialogue,
          content: "Excellent observation! Triggers are actually gifts - they point directly to unhealed parts of your psyche. These reactions are breadcrumbs leading us to deeper understanding. What story might these triggers be connected to?",
          nextNodeId: 'emotion_wd_insight_1',
        ),
        'emotion_wd_mystery_path': const NarrativeNode(
          id: 'emotion_wd_mystery_path',
          type: NarrativeNodeType.dialogue,
          content: "Mystery emotions are the most intriguing clues of all! Your unconscious is communicating through feelings that your conscious mind hasn't decoded yet. Let's investigate what these emotions might be protecting or revealing.",
          nextNodeId: 'emotion_wd_insight_1',
        ),
        'emotion_wd_insight_1': const NarrativeNode(
          id: 'emotion_wd_insight_1',
          type: NarrativeNodeType.insight,
          content: "🔍 Insight: Your emotions are a sophisticated intelligence system. When you learn to read their language, they become your greatest allies in understanding yourself.",
          nextNodeId: 'emotion_wd_complete',
        ),
        'emotion_wd_complete': const NarrativeNode(
          id: 'emotion_wd_complete',
          type: NarrativeNodeType.completion,
          content: "Brilliant detective work! You've uncovered important clues about your emotional patterns. Keep investigating - the deeper mysteries of your consciousness await your discovery.",
        ),
      },
    );
  }

  Future<void> _loadFortressChamberNarratives() async {
    // Compassionate Friend - Fortress Chamber
    _narratives['fortress_compassionate_friend'] = ChamberNarrative(
      chamberId: 'fortress',
      characterArchetype: CharacterArchetype.compassionateFriend,
      startNodeId: 'fortress_cf_start',
      completionNodeIds: ['fortress_cf_complete'],
      nodes: {
        'fortress_cf_start': const NarrativeNode(
          id: 'fortress_cf_start',
          type: NarrativeNodeType.dialogue,
          content: "I can feel the walls you've built around your heart - they've protected you through so much. These defenses served you well, but now we can explore which ones still serve you and which ones might be ready to soften. What feels most protected in your life right now?",
          choices: [
            NarrativeChoice(
              id: 'cf_fortress_trust',
              text: "I struggle to trust others",
              targetNodeId: 'fortress_cf_trust_path',
            ),
            NarrativeChoice(
              id: 'cf_fortress_vulnerability',
              text: "Being vulnerable feels dangerous",
              targetNodeId: 'fortress_cf_vulnerability_path',
            ),
            NarrativeChoice(
              id: 'cf_fortress_isolation',
              text: "I feel safer when I'm alone",
              targetNodeId: 'fortress_cf_isolation_path',
            ),
          ],
        ),
        'fortress_cf_trust_path': const NarrativeNode(
          id: 'fortress_cf_trust_path',
          type: NarrativeNodeType.dialogue,
          content: "Your caution with trust makes perfect sense - it shows how precious your heart is and how carefully you want to protect it. Trust isn't about removing all walls, it's about choosing which doors to open and when. You get to decide the pace.",
          nextNodeId: 'fortress_cf_insight_1',
        ),
        'fortress_cf_vulnerability_path': const NarrativeNode(
          id: 'fortress_cf_vulnerability_path',
          type: NarrativeNodeType.dialogue,
          content: "Of course vulnerability feels dangerous - it requires such courage to let others see your tender places. Your protective instincts have kept you safe. Now we can explore small, safe ways to let your authentic self be seen.",
          nextNodeId: 'fortress_cf_insight_1',
        ),
        'fortress_cf_isolation_path': const NarrativeNode(
          id: 'fortress_cf_isolation_path',
          type: NarrativeNodeType.dialogue,
          content: "Solitude can be such a healing sanctuary, especially when the world feels overwhelming. Your need for space is valid and important. We can explore how to honor this need while also staying connected to what nourishes you.",
          nextNodeId: 'fortress_cf_insight_1',
        ),
        'fortress_cf_insight_1': const NarrativeNode(
          id: 'fortress_cf_insight_1',
          type: NarrativeNodeType.insight,
          content: "💝 Insight: Your protective walls were built with love and wisdom. As you heal, you can transform them from barriers into boundaries that honor both your safety and your growth.",
          nextNodeId: 'fortress_cf_complete',
        ),
        'fortress_cf_complete': const NarrativeNode(
          id: 'fortress_cf_complete',
          type: NarrativeNodeType.completion,
          content: "You've shown such gentleness with your own protective patterns. Remember, healing happens at the pace of trust, and you're exactly where you need to be in this moment.",
        ),
      },
    );

    // Resilient Explorer - Fortress Chamber
    _narratives['fortress_resilient_explorer'] = ChamberNarrative(
      chamberId: 'fortress',
      characterArchetype: CharacterArchetype.resilientExplorer,
      startNodeId: 'fortress_re_start',
      completionNodeIds: ['fortress_re_complete'],
      nodes: {
        'fortress_re_start': const NarrativeNode(
          id: 'fortress_re_start',
          type: NarrativeNodeType.dialogue,
          content: "I see a mighty fortress here - walls built from your experiences and strength! But every great explorer knows that the most magnificent treasures are found beyond the walls. What adventure awaits if we explore what lies beyond your comfort zone?",
          choices: [
            NarrativeChoice(
              id: 're_fortress_barriers',
              text: "I want to break through my barriers",
              targetNodeId: 'fortress_re_barriers_path',
            ),
            NarrativeChoice(
              id: 're_fortress_connection',
              text: "I want to connect more deeply with others",
              targetNodeId: 'fortress_re_connection_path',
            ),
            NarrativeChoice(
              id: 're_fortress_authentic',
              text: "I want to be more authentic",
              targetNodeId: 'fortress_re_authentic_path',
            ),
          ],
        ),
        'fortress_re_barriers_path': const NarrativeNode(
          id: 'fortress_re_barriers_path',
          type: NarrativeNodeType.dialogue,
          content: "Yes! I can feel your warrior spirit ready to break free! These barriers were once your strength, but now they might be limiting your expansion. What would it feel like to transform these walls into bridges to new possibilities?",
          nextNodeId: 'fortress_re_insight_1',
        ),
        'fortress_re_connection_path': const NarrativeNode(
          id: 'fortress_re_connection_path',
          type: NarrativeNodeType.dialogue,
          content: "Beautiful! Deep connection is the ultimate adventure - it requires courage to let others see your true self. Every meaningful relationship starts with someone brave enough to lower their drawbridge first. Are you ready to be that brave?",
          nextNodeId: 'fortress_re_insight_1',
        ),
        'fortress_re_authentic_path': const NarrativeNode(
          id: 'fortress_re_authentic_path',
          type: NarrativeNodeType.dialogue,
          content: "Authenticity is the greatest rebellion against a world that wants you to conform! Your true self is your superpower - when you show up authentically, you give others permission to do the same. Let's unleash your authentic brilliance!",
          nextNodeId: 'fortress_re_insight_1',
        ),
        'fortress_re_insight_1': const NarrativeNode(
          id: 'fortress_re_insight_1',
          type: NarrativeNodeType.insight,
          content: "🚀 Insight: Your fortress was built to protect your treasures. Now you're strong enough to share those treasures with the world. True security comes from knowing you can handle whatever comes.",
          nextNodeId: 'fortress_re_complete',
        ),
        'fortress_re_complete': const NarrativeNode(
          id: 'fortress_re_complete',
          type: NarrativeNodeType.completion,
          content: "You've shown incredible courage in exploring beyond your walls! Remember, every time you choose growth over safety, you become more of who you're meant to be. Keep adventuring!",
        ),
      },
    );

    // Wise Detective - Fortress Chamber
    _narratives['fortress_wise_detective'] = ChamberNarrative(
      chamberId: 'fortress',
      characterArchetype: CharacterArchetype.wiseDetective,
      startNodeId: 'fortress_wd_start',
      completionNodeIds: ['fortress_wd_complete'],
      nodes: {
        'fortress_wd_start': const NarrativeNode(
          id: 'fortress_wd_start',
          type: NarrativeNodeType.dialogue,
          content: "Intriguing... I'm detecting sophisticated defense mechanisms in this fortress. Every wall tells a story about what you've learned to protect. Let's investigate the architecture of your psyche. What pattern of protection do you notice in your relationships?",
          choices: [
            NarrativeChoice(
              id: 'wd_fortress_walls',
              text: "I build walls when I feel threatened",
              targetNodeId: 'fortress_wd_walls_path',
            ),
            NarrativeChoice(
              id: 'wd_fortress_masks',
              text: "I wear masks to hide my true self",
              targetNodeId: 'fortress_wd_masks_path',
            ),
            NarrativeChoice(
              id: 'wd_fortress_distance',
              text: "I create distance when things get too close",
              targetNodeId: 'fortress_wd_distance_path',
            ),
          ],
        ),
        'fortress_wd_walls_path': const NarrativeNode(
          id: 'fortress_wd_walls_path',
          type: NarrativeNodeType.dialogue,
          content: "Fascinating defensive architecture! These walls were intelligently designed by your psyche to protect something valuable. What do you think your unconscious mind is trying to safeguard? What treasure lies behind these walls?",
          nextNodeId: 'fortress_wd_insight_1',
        ),
        'fortress_wd_masks_path': const NarrativeNode(
          id: 'fortress_wd_masks_path',
          type: NarrativeNodeType.dialogue,
          content: "Ah, the mask strategy - a sophisticated form of camouflage! Your psyche learned to show the world what it wanted to see while keeping your authentic self safe. What story do these masks tell about your early experiences with acceptance?",
          nextNodeId: 'fortress_wd_insight_1',
        ),
        'fortress_wd_distance_path': const NarrativeNode(
          id: 'fortress_wd_distance_path',
          type: NarrativeNodeType.dialogue,
          content: "The distance protocol - a clever way to maintain control over intimacy levels! This pattern suggests your psyche learned that closeness can be unpredictable. What does this tell us about your relationship with vulnerability and trust?",
          nextNodeId: 'fortress_wd_insight_1',
        ),
        'fortress_wd_insight_1': const NarrativeNode(
          id: 'fortress_wd_insight_1',
          type: NarrativeNodeType.insight,
          content: "🔍 Insight: Your protective patterns are evidence of your psyche's intelligence and adaptability. Understanding their origin story helps you choose when to use them consciously rather than automatically.",
          nextNodeId: 'fortress_wd_complete',
        ),
        'fortress_wd_complete': const NarrativeNode(
          id: 'fortress_wd_complete',
          type: NarrativeNodeType.completion,
          content: "Excellent detective work! You've uncovered the hidden logic behind your protective patterns. This awareness gives you the power to choose your responses consciously. The mystery of your psyche continues to unfold!",
        ),
      },
    );
  }

  ChamberNarrative? getNarrative(String chamberId, CharacterArchetype character) {
    final key = '${chamberId}_${character.value}';
    return _narratives[key];
  }

  List<ChamberNarrative> getAllNarratives() {
    return _narratives.values.toList();
  }

  Future<NarrativeState> processChoice(
    ChamberNarrative narrative,
    NarrativeState currentState,
    String choiceId,
  ) async {
    final currentNode = narrative.getNode(currentState.currentNodeId);
    if (currentNode == null) return currentState;

    final choice = currentNode.choices.firstWhere(
      (c) => c.id == choiceId,
      orElse: () => throw ArgumentError('Choice not found: $choiceId'),
    );

    // Apply choice effects to variables
    final newVariables = Map<String, dynamic>.from(currentState.variables);
    choice.effects.forEach((key, value) {
      newVariables[key] = value;
    });

    // Update visited nodes
    final newVisitedNodes = List<String>.from(currentState.visitedNodes);
    if (!newVisitedNodes.contains(choice.targetNodeId)) {
      newVisitedNodes.add(choice.targetNodeId);
    }

    // Calculate progress score
    final progressIncrement = (choice.effects['progress'] as int?) ?? 10;
    final newProgressScore = currentState.progressScore + progressIncrement;

    return currentState.copyWith(
      currentNodeId: choice.targetNodeId,
      variables: newVariables,
      visitedNodes: newVisitedNodes,
      progressScore: newProgressScore,
    );
  }

  bool isNarrativeComplete(ChamberNarrative narrative, NarrativeState state) {
    return narrative.completionNodeIds.contains(state.currentNodeId);
  }
}