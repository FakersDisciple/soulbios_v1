import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';
import '../models/api_models.dart';

// User state provider
final userServiceProvider = StateNotifierProvider<UserService, UserState>((ref) {
  return UserService();
});

class UserState {
  final String? userId;
  final UserStatusResponse? status;
  final bool isLoading;
  final String? error;
  final bool isConnected;

  UserState({
    this.userId,
    this.status,
    this.isLoading = false,
    this.error,
    this.isConnected = false,
  });

  UserState copyWith({
    String? userId,
    UserStatusResponse? status,
    bool? isLoading,
    String? error,
    bool? isConnected,
  }) {
    return UserState(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

class UserService extends StateNotifier<UserState> {
  UserService() : super(UserState()) {
    _initializeUser();
  }

  // Initialize user (create demo user for now)
  Future<void> _initializeUser() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Check API health first
      await ApiService.healthCheck();
      
      // Generate demo user ID (in production, this would be from auth)
      final userId = _generateDemoUserId();
      
      // Get or create user status
      final status = await ApiService.getUserStatus(userId);
      
      state = state.copyWith(
        userId: userId,
        status: status,
        isLoading: false,
        isConnected: true,
      );
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isConnected: false,
      );
    }
  }

  // Generate demo user ID (replace with real auth)
  String _generateDemoUserId() {
    // Use a consistent user ID for testing
    return 'flutter_demo_user_123';
  }

  // Refresh user status
  Future<void> refreshStatus() async {
    if (state.userId == null) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final status = await ApiService.getUserStatus(state.userId!);
      state = state.copyWith(
        status: status,
        isLoading: false,
        isConnected: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isConnected: false,
      );
    }
  }

  // Chat with Alice via deepconf backend
  Future<ChatResponse?> chatWithAlice(String message, {Map<String, dynamic>? metadata}) async {
    if (state.userId == null) return null;
    
    try {
      final response = await ApiService.chatWithAlice(
        userId: state.userId!,
        message: message,
        metadata: metadata,
      );
      
      // Update connection status on successful chat
      state = state.copyWith(isConnected: true, error: null);
      
      return response;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isConnected: false);
      return null;
    }
  }

  // Analyze patterns
  Future<PatternAnalysisResponse?> analyzePatterns(String message, {Map<String, dynamic>? metadata}) async {
    if (state.userId == null) return null;
    
    try {
      return await ApiService.analyzePatterns(
        userId: state.userId!,
        message: message,
        metadata: metadata,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Get conversations
  Future<ConversationsResponse?> getConversations({int limit = 50}) async {
    if (state.userId == null) return null;
    
    try {
      return await ApiService.getUserConversations(
        userId: state.userId!,
        limit: limit,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Get current user status
  UserStatusResponse? getUserStatus() {
    return state.status;
  }

  // Retry connection
  Future<void> retryConnection() async {
    await _initializeUser();
  }
}