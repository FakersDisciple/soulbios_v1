import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/api_models.dart'; // Make sure this path is correct

class ApiService {
  // --- Configuration ---
  static const String _prodBaseUrl = 'https://soulbios-v1-747hyhhxdq-uc.a.run.app';
  static const String _prodApiKey = 'FVaiUzD7ipeSQi37RcuGQAbIsjkGqed8S0J2IT0znsnFolkPTAHfvceAYbAkNJc5';
  
  static const String _devBaseUrl = 'http://localhost:8000';
  static const String _devApiKey = 'test-key-12345';

  // --- Dio Client Initialization (static) ---
  static final Dio _dio = _createDio();

  static Dio _createDio() {
    final bool isProd = !kDebugMode;
    final String baseUrl = isProd ? _prodBaseUrl : _devBaseUrl;
    
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 45),
    );
    
    final dio = Dio(options);

    // Use an interceptor to guarantee the API key is added to every request.
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final String apiKey = isProd ? _prodApiKey : _devApiKey;
        options.headers['X-API-Key'] = apiKey;
        return handler.next(options);
      },
    ));

    // Add logging for debug mode.
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true, requestHeader: true));
    }
    
    return dio;
  }

  // --- ALL API METHODS ---

  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  static Future<ChatResponse> chatWithAlice({required String userId, required String message, Map<String, dynamic>? metadata}) async {
    try {
      final response = await _dio.post('/chat', data: {'user_id': userId, 'message': message, 'metadata': metadata});
      return ChatResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  static Future<UserStatusResponse> getUserStatus(String userId) async {
    try {
      final response = await _dio.get('/users/$userId/status');
      return UserStatusResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  static Future<ConversationsResponse> getUserConversations({required String userId, int limit = 50}) async {
    try {
      final response = await _dio.get('/users/$userId/conversations', queryParameters: {'limit': limit});
      return ConversationsResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
  
  static Future<PatternAnalysisResponse> analyzePatterns({required String userId, required String message, Map<String, dynamic>? metadata}) async {
    try {
      final response = await _dio.post('/users/$userId/analyze', data: {'message': message, 'metadata': metadata});
      return PatternAnalysisResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  static Future<ImageGenerationResponse> generateImage({
    required String userId,
    required String prompt,
    String? chamberType,
    String? characterArchetype,
    String style = 'mystical',
    bool confirmed = false,
  }) async {
    try {
      final requestBody = {
        'userId': userId,
        'prompt': prompt,
        'chamberType': chamberType,
        'characterArchearchetype': characterArchetype,
        'style': style,
        'confirmed': confirmed,
      };
      final response = await _dio.post('/generate/image', data: requestBody);
      return ImageGenerationResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}


// --- FULLY IMPLEMENTED API EXCEPTION CLASS ---
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, {this.statusCode});
  
  factory ApiException.fromDioException(DioException dioException) {
    String message;
    int? statusCode = dioException.response?.statusCode;

    if (statusCode == 403) {
      return ApiException('Authentication Failed. API Key is invalid.', statusCode: statusCode);
    }
    
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Request timed out. Please check your connection.';
        break;
      case DioExceptionType.badResponse:
        final responseData = dioException.response?.data;
        if (responseData is Map && responseData.containsKey('detail')) {
          message = responseData['detail'];
        } else {
          message = 'Server error ($statusCode). Please try again later.';
        }
        break;
      case DioExceptionType.connectionError:
        message = 'Connection error. Check if the backend is running.';
        break;
      default:
        message = 'An unexpected network error occurred.';
    }
    return ApiException(message, statusCode: statusCode);
  }
  
  @override
  String toString() => 'ApiException: $message';
}