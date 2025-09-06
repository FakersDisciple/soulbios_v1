// API Models matching Python backend responses
import 'package:flutter/material.dart';

class ChatResponse {
  final String response;
  final String alicePersona;
  final String consciousnessLevel;
  final Map<String, double> consciousnessIndicators;
  final Map<String, dynamic> activatedPatterns;
  final int wisdomDepth;
  final double breakthroughPotential;
  final double personalizationScore;
  final String conversationId;
  final int processingTimeMs;
  final String? activeCharacter;
  final int? characterStage;
  final Map<String, dynamic>? characterProgress;

  ChatResponse({
    required this.response,
    required this.alicePersona,
    required this.consciousnessLevel,
    required this.consciousnessIndicators,
    required this.activatedPatterns,
    required this.wisdomDepth,
    required this.breakthroughPotential,
    required this.personalizationScore,
    required this.conversationId,
    required this.processingTimeMs,
    this.activeCharacter,
    this.characterStage,
    this.characterProgress,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      response: json['response'] ?? '',
      alicePersona: json['alice_persona'] ?? '',
      consciousnessLevel: json['consciousness_level'] ?? '',
      consciousnessIndicators: json['consciousness_indicators'] != null
          ? Map<String, double>.from(
              (json['consciousness_indicators'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))
            )
          : {},
      activatedPatterns: json['activated_patterns'] != null
          ? Map<String, dynamic>.from(json['activated_patterns'])
          : {},
      wisdomDepth: json['wisdom_depth'] ?? 0,
      breakthroughPotential: (json['breakthrough_potential'] ?? 0.0).toDouble(),
      personalizationScore: (json['personalization_score'] ?? 0.0).toDouble(),
      conversationId: json['conversation_id'] ?? '',
      processingTimeMs: json['processing_time_ms'] ?? 0,
      activeCharacter: json['active_character'],
      characterStage: json['character_stage'],
      characterProgress: json['character_progress'] != null 
          ? Map<String, dynamic>.from(json['character_progress'])
          : null,
    );
  }
}

class UserStatusResponse {
  final String userId;
  final List<String> collectionsCreated;
  final int totalConversations;
  final int totalPatterns;
  final Map<String, double> consciousnessHistory;
  final String createdAt;

  UserStatusResponse({
    required this.userId,
    required this.collectionsCreated,
    required this.totalConversations,
    required this.totalPatterns,
    required this.consciousnessHistory,
    required this.createdAt,
  });

  factory UserStatusResponse.fromJson(Map<String, dynamic> json) {
    return UserStatusResponse(
      userId: json['user_id'] ?? '',
      collectionsCreated: List<String>.from(json['collections_created'] ?? []),
      totalConversations: json['total_conversations'] ?? 0,
      totalPatterns: json['total_patterns'] ?? 0,
      consciousnessHistory: Map<String, double>.from(
        json['consciousness_history']?.map((k, v) => MapEntry(k, v.toDouble())) ?? {}
      ),
      createdAt: json['created_at'] ?? '',
    );
  }
}

class PatternAnalysisResponse {
  final String userId;
  final Map<String, dynamic> hierarchicalActivations;
  final Map<String, double> consciousnessIndicators;
  final Map<String, double> networkState;
  final String processingTimestamp;

  PatternAnalysisResponse({
    required this.userId,
    required this.hierarchicalActivations,
    required this.consciousnessIndicators,
    required this.networkState,
    required this.processingTimestamp,
  });

  factory PatternAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return PatternAnalysisResponse(
      userId: json['user_id'] ?? '',
      hierarchicalActivations: json['hierarchical_activations'] ?? {},
      consciousnessIndicators: Map<String, double>.from(
        json['consciousness_indicators']?.map((k, v) => MapEntry(k, v.toDouble())) ?? {}
      ),
      networkState: Map<String, double>.from(
        json['network_state']?.map((k, v) => MapEntry(k, v.toDouble())) ?? {}
      ),
      processingTimestamp: json['processing_timestamp'] ?? '',
    );
  }
}

class ConversationItem {
  final String id;
  final String message;
  final String role;
  final String timestamp;
  final String? alicePersona;
  final String? consciousnessLevel;
  final Map<String, dynamic> metadata;

  ConversationItem({
    required this.id,
    required this.message,
    required this.role,
    required this.timestamp,
    this.alicePersona,
    this.consciousnessLevel,
    required this.metadata,
  });

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    return ConversationItem(
      id: json['id'] ?? '',
      message: json['message'] ?? '',
      role: json['role'] ?? '',
      timestamp: json['timestamp'] ?? '',
      alicePersona: json['alice_persona'],
      consciousnessLevel: json['consciousness_level'],
      metadata: json['metadata'] ?? {},
    );
  }
}

class ConversationsResponse {
  final List<ConversationItem> conversations;
  final int total;

  ConversationsResponse({
    required this.conversations,
    required this.total,
  });

  factory ConversationsResponse.fromJson(Map<String, dynamic> json) {
    return ConversationsResponse(
      conversations: (json['conversations'] as List?)
          ?.map((item) => ConversationItem.fromJson(item))
          .toList() ?? [],
      total: json['total'] ?? 0,
    );
  }
}

// Enhanced MindMaze models with API integration
class ApiInsight {
  final String id;
  final String text;
  final String chamber;
  final String discoveredAt;
  final String pattern;
  final double confidenceScore;
  final Map<String, dynamic> metadata;

  ApiInsight({
    required this.id,
    required this.text,
    required this.chamber,
    required this.discoveredAt,
    required this.pattern,
    required this.confidenceScore,
    required this.metadata,
  });

  factory ApiInsight.fromJson(Map<String, dynamic> json) {
    return ApiInsight(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      chamber: json['chamber'] ?? '',
      discoveredAt: json['discovered_at'] ?? '',
      pattern: json['pattern'] ?? '',
      confidenceScore: (json['confidence_score'] ?? 0.0).toDouble(),
      metadata: json['metadata'] ?? {},
    );
  }
}

class ApiChamberProgress {
  final String chamberType;
  final int completedQuestions;
  final int totalQuestions;
  final bool isUnlocked;
  final List<String> unlockedRooms;
  final Map<String, dynamic> progressMetadata;

  ApiChamberProgress({
    required this.chamberType,
    required this.completedQuestions,
    required this.totalQuestions,
    required this.isUnlocked,
    required this.unlockedRooms,
    required this.progressMetadata,
  });

  factory ApiChamberProgress.fromJson(Map<String, dynamic> json) {
    return ApiChamberProgress(
      chamberType: json['chamber_type'] ?? '',
      completedQuestions: json['completed_questions'] ?? 0,
      totalQuestions: json['total_questions'] ?? 21,
      isUnlocked: json['is_unlocked'] ?? false,
      unlockedRooms: List<String>.from(json['unlocked_rooms'] ?? []),
      progressMetadata: json['progress_metadata'] ?? {},
    );
  }
}

class LifebookUploadResponse {
  final String status;
  final String documentId;
  final String filename;
  final int totalPages;
  final int chunksProcessed;
  final int processingTimeMs;
  final String message;

  LifebookUploadResponse({
    required this.status,
    required this.documentId,
    required this.filename,
    required this.totalPages,
    required this.chunksProcessed,
    required this.processingTimeMs,
    required this.message,
  });

  factory LifebookUploadResponse.fromJson(Map<String, dynamic> json) {
    return LifebookUploadResponse(
      status: json['status'] ?? '',
      documentId: json['document_id'] ?? '',
      filename: json['filename'] ?? '',
      totalPages: json['total_pages'] ?? 0,
      chunksProcessed: json['chunks_processed'] ?? 0,
      processingTimeMs: json['processing_time_ms'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}

class AvailableCharactersResponse {
  final List<Map<String, dynamic>> characters;
  final Map<String, dynamic> unlockRequirements;
  final String? activeCharacter;

  AvailableCharactersResponse({
    required this.characters,
    required this.unlockRequirements,
    this.activeCharacter,
  });

  factory AvailableCharactersResponse.fromJson(Map<String, dynamic> json) {
    return AvailableCharactersResponse(
      characters: List<Map<String, dynamic>>.from(json['characters'] ?? []),
      unlockRequirements: Map<String, dynamic>.from(json['unlock_requirements'] ?? {}),
      activeCharacter: json['active_character'],
    );
  }
}

class CharacterProgressResponse {
  final Map<String, dynamic> progress;
  final List<String> unlockedCharacters;
  final Map<String, dynamic> stageProgressions;

  CharacterProgressResponse({
    required this.progress,
    required this.unlockedCharacters,
    required this.stageProgressions,
  });

  factory CharacterProgressResponse.fromJson(Map<String, dynamic> json) {
    return CharacterProgressResponse(
      progress: Map<String, dynamic>.from(json['progress'] ?? {}),
      unlockedCharacters: List<String>.from(json['unlocked_characters'] ?? []),
      stageProgressions: Map<String, dynamic>.from(json['stage_progressions'] ?? {}),
    );
  }
}

// New models for enhanced Journey features
class DataDestination {
  final String iconPath;
  final String description;
  final String type;
  final Color color;

  DataDestination({
    required this.iconPath,
    required this.description,
    required this.type,
    required this.color,
  });

  factory DataDestination.fromJson(Map<String, dynamic> json) {
    return DataDestination(
      iconPath: json['icon_path'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      color: Color(json['color'] ?? 0xFF6366F1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'icon_path': iconPath,
      'description': description,
      'type': type,
      'color': color.value,
    };
  }
}

class PatternNode {
  final String id;
  final String label;
  final Color color;
  final List<String> connectionIds;
  final double x;
  final double y;
  final bool isRevealed;
  final String pattern;
  final DateTime discoveredAt;

  PatternNode({
    required this.id,
    required this.label,
    required this.color,
    required this.connectionIds,
    this.x = 0.0,
    this.y = 0.0,
    this.isRevealed = false,
    required this.pattern,
    required this.discoveredAt,
  });

  factory PatternNode.fromJson(Map<String, dynamic> json) {
    return PatternNode(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      color: Color(json['color'] ?? 0xFF6366F1),
      connectionIds: List<String>.from(json['connection_ids'] ?? []),
      x: (json['x'] ?? 0.0).toDouble(),
      y: (json['y'] ?? 0.0).toDouble(),
      isRevealed: json['is_revealed'] ?? false,
      pattern: json['pattern'] ?? '',
      discoveredAt: DateTime.parse(json['discovered_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'color': color.value,
      'connection_ids': connectionIds,
      'x': x,
      'y': y,
      'is_revealed': isRevealed,
      'pattern': pattern,
      'discovered_at': discoveredAt.toIso8601String(),
    };
  }

  PatternNode copyWith({
    String? id,
    String? label,
    Color? color,
    List<String>? connectionIds,
    double? x,
    double? y,
    bool? isRevealed,
    String? pattern,
    DateTime? discoveredAt,
  }) {
    return PatternNode(
      id: id ?? this.id,
      label: label ?? this.label,
      color: color ?? this.color,
      connectionIds: connectionIds ?? this.connectionIds,
      x: x ?? this.x,
      y: y ?? this.y,
      isRevealed: isRevealed ?? this.isRevealed,
      pattern: pattern ?? this.pattern,
      discoveredAt: discoveredAt ?? this.discoveredAt,
    );
  }
}

class MemoryEntry {
  final String id;
  final String content;
  final DateTime timestamp;
  final String? voiceNotePath;
  final Map<String, dynamic> metadata;
  final List<String> tags;
  final double? sentimentScore;
  final String? emotionalState;

  MemoryEntry({
    required this.id,
    required this.content,
    required this.timestamp,
    this.voiceNotePath,
    required this.metadata,
    required this.tags,
    this.sentimentScore,
    this.emotionalState,
  });

  factory MemoryEntry.fromJson(Map<String, dynamic> json) {
    return MemoryEntry(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      voiceNotePath: json['voice_note_path'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      sentimentScore: json['sentiment_score']?.toDouble(),
      emotionalState: json['emotional_state'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'voice_note_path': voiceNotePath,
      'metadata': metadata,
      'tags': tags,
      'sentiment_score': sentimentScore,
      'emotional_state': emotionalState,
    };
  }
}

class ImageGenerationRequest {
  final String userId;
  final String prompt;
  final String? chamberType;
  final String? characterArchetype;
  final String style;
  final bool confirmed;

  const ImageGenerationRequest({
    required this.userId,
    required this.prompt,
    this.chamberType,
    this.characterArchetype,
    this.style = 'mystical',
    this.confirmed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'prompt': prompt,
      'chamber_type': chamberType,
      'character_archetype': characterArchetype,
      'style': style,
      'confirmed': confirmed,
    };
  }
}

class ImageGenerationResponse {
  final String status;
  final String? imageUrl;
  final String? imageId;
  final String promptUsed;
  final int generationTimeMs;
  final bool cached;
  final String? errorMessage;

  const ImageGenerationResponse({
    required this.status,
    this.imageUrl,
    this.imageId,
    required this.promptUsed,
    required this.generationTimeMs,
    this.cached = false,
    this.errorMessage,
  });

  factory ImageGenerationResponse.fromJson(Map<String, dynamic> json) {
    return ImageGenerationResponse(
      status: json['status'],
      imageUrl: json['image_url'],
      imageId: json['image_id'],
      promptUsed: json['prompt_used'],
      generationTimeMs: json['generation_time_ms'],
      cached: json['cached'] ?? false,
      errorMessage: json['error_message'],
    );
  }

  bool get isSuccess => status == 'success';
  bool get requiresConfirmation => status == 'confirmation_required';
  bool get hasError => status == 'error';
}