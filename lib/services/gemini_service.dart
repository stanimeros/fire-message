import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secure_storage_service.dart';
import 'token_service.dart';

class GeminiService {
  final _secureStorage = SecureStorageService();
  final _tokenService = TokenService();
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent';

  /// Get access token from service account credentials
  Future<String> _getAccessToken(String appId) async {
    return _tokenService.getGeminiAccessToken(appId);
  }

  /// Check if service account credentials are available for the app
  Future<bool> hasCredentials(String appId) async {
    final credentials = await _secureStorage.getAppCredentials(appId);
    return credentials != null && credentials.isNotEmpty;
  }

  /// Refine text using Gemini API
  /// [appId] is the ID of the app to use for service account credentials
  /// [originalText] is the text to refine
  /// [customPrompt] is the custom prompt to use (will include originalText automatically)
  /// [accessToken] optional pre-generated access token for better performance
  Future<String?> refineText(
    String appId,
    String originalText,
    String customPrompt, {
    String? accessToken,
  }) async {
    final prompt = '$customPrompt\n\n$originalText';

    try {
      // Use provided token or generate one
      final token = accessToken ?? await _getAccessToken(appId);

      // Use the Generative Language API with access token
      final url = Uri.parse(_geminiApiUrl);
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'thinkingConfig': {'thinkingLevel': 'minimal'} // Minimal reasoning for speed
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            return text?.trim();
          }
        }
        throw Exception('No response from Gemini API');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final error = errorData?['error'] as Map<String, dynamic>?;
        final message = error?['message'] as String? ?? 'Unknown error';
        throw Exception('Gemini API error: ${response.statusCode} - $message');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to refine text: $e');
    }
  }
}
