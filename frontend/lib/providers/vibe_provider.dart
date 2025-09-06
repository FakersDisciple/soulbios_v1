import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to manage active vibe colors
final activeVibeColorsProvider = StateProvider<List<Color>>((ref) => []);