import 'character.dart';

enum NarrativeNodeType {
  dialogue,
  choice,
  insight,
  completion
}

class NarrativeNode {
  final String id;
  final NarrativeNodeType type;
  final String content;
  final List<NarrativeChoice> choices;
  final String? nextNodeId;
  final Map<String, dynamic> metadata;

  const NarrativeNode({
    required this.id,
    required this.type,
    required this.content,
    this.choices = const [],
    this.nextNodeId,
    this.metadata = const {},
  });

  factory NarrativeNode.fromJson(Map<String, dynamic> json) {
    return NarrativeNode(
      id: json['id'],
      type: NarrativeNodeType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      content: json['content'],
      choices: (json['choices'] as List<dynamic>?)
          ?.map((choice) => NarrativeChoice.fromJson(choice))
          .toList() ?? [],
      nextNodeId: json['nextNodeId'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'content': content,
      'choices': choices.map((choice) => choice.toJson()).toList(),
      'nextNodeId': nextNodeId,
      'metadata': metadata,
    };
  }
}

class NarrativeChoice {
  final String id;
  final String text;
  final String targetNodeId;
  final Map<String, dynamic> effects;

  const NarrativeChoice({
    required this.id,
    required this.text,
    required this.targetNodeId,
    this.effects = const {},
  });

  factory NarrativeChoice.fromJson(Map<String, dynamic> json) {
    return NarrativeChoice(
      id: json['id'],
      text: json['text'],
      targetNodeId: json['targetNodeId'],
      effects: Map<String, dynamic>.from(json['effects'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'targetNodeId': targetNodeId,
      'effects': effects,
    };
  }
}

class ChamberNarrative {
  final String chamberId;
  final CharacterArchetype characterArchetype;
  final Map<String, NarrativeNode> nodes;
  final String startNodeId;
  final List<String> completionNodeIds;

  const ChamberNarrative({
    required this.chamberId,
    required this.characterArchetype,
    required this.nodes,
    required this.startNodeId,
    required this.completionNodeIds,
  });

  NarrativeNode? getNode(String nodeId) => nodes[nodeId];
  NarrativeNode get startNode => nodes[startNodeId]!;

  factory ChamberNarrative.fromJson(Map<String, dynamic> json) {
    final nodesMap = <String, NarrativeNode>{};
    final nodesJson = json['nodes'] as Map<String, dynamic>;
    
    for (final entry in nodesJson.entries) {
      nodesMap[entry.key] = NarrativeNode.fromJson(entry.value);
    }

    return ChamberNarrative(
      chamberId: json['chamberId'],
      characterArchetype: CharacterArchetype.values.firstWhere(
        (e) => e.value == json['characterArchetype'],
      ),
      nodes: nodesMap,
      startNodeId: json['startNodeId'],
      completionNodeIds: List<String>.from(json['completionNodeIds']),
    );
  }

  Map<String, dynamic> toJson() {
    final nodesJson = <String, dynamic>{};
    for (final entry in nodes.entries) {
      nodesJson[entry.key] = entry.value.toJson();
    }

    return {
      'chamberId': chamberId,
      'characterArchetype': characterArchetype.value,
      'nodes': nodesJson,
      'startNodeId': startNodeId,
      'completionNodeIds': completionNodeIds,
    };
  }
}

class NarrativeState {
  final String currentNodeId;
  final Map<String, dynamic> variables;
  final List<String> visitedNodes;
  final int progressScore;

  const NarrativeState({
    required this.currentNodeId,
    this.variables = const {},
    this.visitedNodes = const [],
    this.progressScore = 0,
  });

  NarrativeState copyWith({
    String? currentNodeId,
    Map<String, dynamic>? variables,
    List<String>? visitedNodes,
    int? progressScore,
  }) {
    return NarrativeState(
      currentNodeId: currentNodeId ?? this.currentNodeId,
      variables: variables ?? this.variables,
      visitedNodes: visitedNodes ?? this.visitedNodes,
      progressScore: progressScore ?? this.progressScore,
    );
  }

  factory NarrativeState.fromJson(Map<String, dynamic> json) {
    return NarrativeState(
      currentNodeId: json['currentNodeId'],
      variables: Map<String, dynamic>.from(json['variables'] ?? {}),
      visitedNodes: List<String>.from(json['visitedNodes'] ?? []),
      progressScore: json['progressScore'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentNodeId': currentNodeId,
      'variables': variables,
      'visitedNodes': visitedNodes,
      'progressScore': progressScore,
    };
  }
}