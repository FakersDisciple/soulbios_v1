import 'package:flutter/material.dart';

class Position {
  final int x, y;
  
  const Position(this.x, this.y);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position && x == other.x && y == other.y;
  
  @override
  int get hashCode => x.hashCode ^ y.hashCode;
  
  @override
  String toString() => 'Position($x, $y)';
}

class MazeQuestion {
  final String id;
  final String text;
  final List<String> choices;
  final int correctIndex;
  final String hint;
  final String explanation;
  
  const MazeQuestion({
    required this.id,
    required this.text,
    required this.choices,
    required this.correctIndex,
    required this.hint,
    required this.explanation,
  });
  
  String get correctAnswer => choices[correctIndex];
}

class MazeObject {
  final String id;
  final String name;
  final Position position;
  final String description;
  final String? hintText;
  final bool isClickable;
  
  const MazeObject({
    required this.id,
    required this.name,
    required this.position,
    required this.description,
    this.hintText,
    this.isClickable = true,
  });
}

class MazeRoom {
  final String id;
  final String name;
  final String description;
  final Position gridPosition;
  final MazeQuestion? question;
  final List<MazeObject> objects;
  final List<String> connectedRooms;
  final bool isUnlocked;
  final bool isCompleted;
  final Color themeColor;
  
  const MazeRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.gridPosition,
    this.question,
    required this.objects,
    required this.connectedRooms,
    this.isUnlocked = false,
    this.isCompleted = false,
    required this.themeColor,
  });
}