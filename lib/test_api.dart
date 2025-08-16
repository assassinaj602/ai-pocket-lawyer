import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Test the OpenRouter API connection
Future<void> testOpenRouterAPI() async {
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];

    print('Testing OpenRouter API...');
    print('API Key: ${apiKey?.substring(0, 20)}...');

    if (apiKey == null || apiKey.isEmpty) {
      print('❌ No API key found');
      return;
    }

    final dio = Dio();
    dio.options = BaseOptions(
      baseUrl: 'https://openrouter.ai/api/v1',
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    );

    final response = await dio.post(
      '/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://ai-pocket-lawyer.com',
          'X-Title': 'AI Pocket Lawyer',
        },
      ),
      data: {
        'model': 'meta-llama/llama-3.1-8b-instruct:free',
        'messages': [
          {
            'role': 'user',
            'content':
                'Hello! This is a test message. Please respond with "API connection successful!"',
          },
        ],
        'max_tokens': 50,
      },
    );

    print('✅ API Response Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final content = response.data['choices'][0]['message']['content'];
      print('✅ API Response: $content');
    } else {
      print('❌ API Error: ${response.data}');
    }
  } catch (e) {
    print('❌ Error testing API: $e');
  }
}
