import 'package:flutter/material.dart';

class OrbState {
  final String label;
  final double intensity;
  final Color color;
  final String activity;
  final IconData icon;

  OrbState({
    required this.label,
    required this.intensity,
    required this.color,
    required this.activity,
    required this.icon,
  });

  OrbState copyWith({
    String? label,
    double? intensity,
    Color? color,
    String? activity,
    IconData? icon,
  }) {
    return OrbState(
      label: label ?? this.label,
      intensity: intensity ?? this.intensity,
      color: color ?? this.color,
      activity: activity ?? this.activity,
      icon: icon ?? this.icon,
    );
  }
}