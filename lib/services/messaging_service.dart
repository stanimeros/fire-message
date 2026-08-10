import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/app_model.dart';
import 'secure_storage_service.dart';
import 'token_service.dart';

class MessagingService {
  final _secureStorage = SecureStorageService();
  final _tokenService = TokenService();

  Future<String> _getAccessToken(String appId) async {
    return _tokenService.getFcmAccessToken(appId);
  }

  Future<Map<String, String?>> sendNotification({
    required AppModel app,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? topic,
    String? condition,
    String? token,
    String? accessToken,
  }) async {
    String? fcmToken;
    String? projectId;
    
    // Handle pre-HTTP errors (token generation, credentials, etc.)
    try {
      // Use provided token or generate one
      fcmToken = accessToken ?? await _getAccessToken(app.id);

      // Get service account data to extract project_id
      final serviceAccount = await _secureStorage.getAppCredentials(app.id);
      projectId = serviceAccount?['project_id'];
    } catch (e) {
      debugPrint('Pre-HTTP error: $e');
      // Try to extract status code from error message if it contains one
      final statusCodeMatch = RegExp(r'\b(\d{3})\b').firstMatch(e.toString());
      final extractedCode = statusCodeMatch?.group(1);
      
      return {
        'code': extractedCode ?? 'ERROR',
        'message': e.toString(),
      };
    }
    
    // Use FCM HTTP v1 API endpoint
    final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');
    
    // Build the message payload according to v1 API format
    final message = <String, dynamic>{
      'notification': {
        'title': title,
        'body': body,
      },
      'data': ?data,
    };

    // Add image URL to platform-specific fields if provided
    if (imageUrl != null && imageUrl.isNotEmpty) {
      message['android'] = {
        'notification': {
          'image': imageUrl,
        },
      };
      message['apns'] = {
        'payload': {
          'aps': {
            'mutable-content': 1,
          },
        },
        'fcm_options': {
          'image': imageUrl,
        },
      };
      message['webpush'] = {
        'headers': {
          'image': imageUrl,
        },
      };
    }
    
    // Set target (token, topic, or condition)
    if (condition != null && condition.isNotEmpty) {
      message['condition'] = condition;
    } else if (topic != null && topic.isNotEmpty) {
      message['topic'] = topic;
    } else if (token != null && token.isNotEmpty) {
      message['token'] = token;
    } else {
      return {
        'code': '400',
        'message': 'Either topic, condition, or token must be provided',
      };
    }
    
    final payload = <String, dynamic>{
      'message': message,
    };

    http.Response response;
    try {
      response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $fcmToken',
        },
        body: jsonEncode(payload),
      );
    } catch (e) {
      debugPrint('Network error: $e');
      return {
        'code': 'NETWORK_ERROR',
        'message': 'Network error: ${e.toString()}',
      };
    }

    final code = response.statusCode;
    Map<String, dynamic> responseData = {};
    
    try {
      if (response.body.isNotEmpty) {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Failed to parse response: $e');
      return {
        'code': code.toString(),
        'message': 'Failed to parse response: ${response.body}',
      };
    }

    if (code == 200) {
      if (responseData['name'] != null) {
        // Return the actual response message from FCM
        final messageId = responseData['name']?.toString() ?? '';
        return {
          'code': code.toString(),
          'message': messageId.isNotEmpty ? 'Message ID: $messageId' : 'Notification sent successfully',
        };
      }
    }

    // Handle error response - always return the HTTP status code
    final errorObj = responseData['error'] as Map<String, dynamic>?;
    final errorMessage = errorObj?['message']?.toString() ?? 
      responseData['message']?.toString() ?? 
      'Unknown error occurred';

    return {
      'code': code.toString(),
      'message': errorMessage,
    };
  }
}

