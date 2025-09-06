import 'package:flutter/material.dart';

enum ChamberType {
  emotion,
  pattern,
  fortress,
  wisdom,
  transcendent,
}

extension ChamberTypeExtension on ChamberType {
  String get displayName {
    switch (this) {
      case ChamberType.emotion:
        return 'Emotion Chamber';
      case ChamberType.pattern:
        return 'Pattern Chamber';
      case ChamberType.fortress:
        return 'Fortress Chamber';
      case ChamberType.wisdom:
        return 'Wisdom Chamber';
      case ChamberType.transcendent:
        return 'Transcendent Chamber';
    }
  }

  String get value {
    switch (this) {
      case ChamberType.emotion:
        return 'emotion';
      case ChamberType.pattern:
        return 'pattern';
      case ChamberType.fortress:
        return 'fortress';
      case ChamberType.wisdom:
        return 'wisdom';
      case ChamberType.transcendent:
        return 'transcendent';
    }
  }
}

class Chamber {
  final ChamberType type;
  final String name;
  final String description;
  final Color themeColor;
  final IconData icon;
  final bool isUnlocked;
  final int completedQuestions;
  final int totalQuestions;

  const Chamber({
    required this.type,
    required this.name,
    required this.description,
    required this.themeColor,
    required this.icon,
    this.isUnlocked = true,
    this.completedQuestions = 0,
    this.totalQuestions = 21,
  });

  double get completionPercentage => 
      totalQuestions > 0 ? completedQuestions / totalQuestions : 0.0;

  bool get isCompleted => completedQuestions >= totalQuestions;

  Chamber copyWith({
    ChamberType? type,
    String? name,
    String? description,
    Color? themeColor,
    IconData? icon,
    bool? isUnlocked,
    int? completedQuestions,
    int? totalQuestions,
  }) {
    return Chamber(
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      themeColor: themeColor ?? this.themeColor,
      icon: icon ?? this.icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      completedQuestions: completedQuestions ?? this.completedQuestions,
      totalQuestions: totalQuestions ?? this.totalQuestions,
    );
  }
}