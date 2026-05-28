import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models/ai_chat_request.dart';
import 'models/ai_chat_response.dart';

class AiChatService {
  final String baseUrl;

  AiChatService({required this.baseUrl});

  Future<AiChatMessage> send(AiChatRequest req, {String? bearerToken}) async {
    final url = Uri.parse('$baseUrl/api/v1/chat');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json, text/plain',
    };
    if (bearerToken != null) headers['Authorization'] = 'Bearer $bearerToken';
    final res = await http.post(
      url,
      headers: headers,
      body: jsonEncode(req.toJson()),
    );

    if (res.statusCode == 200) {
      final contentType = (res.headers['content-type'] ?? '').toLowerCase();

      // Plain text response
      if (contentType.contains('text/plain')) {
        return AiChatMessage(role: 'assistant', content: res.body);
      }

      // Try JSON response
      try {
        final body = jsonDecode(res.body);
        if (body is String)
          return AiChatMessage(role: 'assistant', content: body);
        if (body is Map<String, dynamic>) {
          // Common shapes: { content }, { message }, { output }, or message fields
          if (body.containsKey('content')) return AiChatMessage.fromJson(body);
          if (body.containsKey('message'))
            return AiChatMessage.fromJson({'message': body['message']});
          if (body.containsKey('output'))
            return AiChatMessage.fromJson({'message': body['output']});
          // fallback to full map
          return AiChatMessage.fromJson(body);
        }
        if (body is List && body.isNotEmpty) {
          final first = body.first;
          if (first is Map<String, dynamic>)
            return AiChatMessage.fromJson(first);
          return AiChatMessage(role: 'assistant', content: first.toString());
        }
      } catch (_) {
        // fallthrough to treat as plain text
        return AiChatMessage(role: 'assistant', content: res.body);
      }
    }

    throw Exception('AI chat failed: ${res.statusCode} ${res.body}');
  }
}
