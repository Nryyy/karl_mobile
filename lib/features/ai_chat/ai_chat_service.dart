import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'models/ai_chat_request.dart';
import 'models/ai_chat_response.dart';

class AiChatService {
  final String baseUrl;
  final http.Client _client;

  AiChatService({required this.baseUrl, http.Client? client})
      : _client = client ?? _createDefaultClient();

  static http.Client _createDefaultClient() {
    if (kDebugMode && !kIsWeb) {
      final ioClient = io.HttpClient()
        ..badCertificateCallback = (cert, host, port) => host == 'localhost';
      return IOClient(ioClient);
    }
    return http.Client();
  }

  Future<AiChatMessage> send(AiChatRequest req, {String? bearerToken}) async {
    final url = Uri.parse('$baseUrl/api/v1/chat');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json, text/plain',
    };
    if (bearerToken != null) headers['Authorization'] = 'Bearer $bearerToken';
    final res = await _client.post(
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
        if (body is String) {
          return AiChatMessage(role: 'assistant', content: _clean(body));
        }
        if (body is Map<String, dynamic>) {
          if (body.containsKey('content')) return AiChatMessage.fromJson(body);
          if (body.containsKey('message')) {
            return AiChatMessage.fromJson({'message': body['message']});
          }
          if (body.containsKey('output')) {
            return AiChatMessage.fromJson({'message': body['output']});
          }
          return AiChatMessage.fromJson(body);
        }
        if (body is List && body.isNotEmpty) {
          final first = body.first;
          if (first is Map<String, dynamic>) {
            final contentField = first['content'];
            if (contentField is Map<String, dynamic> &&
                contentField.containsKey('response')) {
              return AiChatMessage(
                role: 'assistant',
                content: _clean(contentField['response'].toString()),
              );
            }
            if (contentField is String) {
              try {
                final decoded = jsonDecode(contentField);
                if (decoded is Map<String, dynamic> &&
                    decoded.containsKey('response')) {
                  return AiChatMessage(
                    role: 'assistant',
                    content: _clean(decoded['response'].toString()),
                  );
                }
              } catch (_) {}
              return AiChatMessage(role: 'assistant', content: _clean(contentField));
            }
            return AiChatMessage.fromJson(first);
          }
          return AiChatMessage(role: 'assistant', content: _clean(first.toString()));
        }
      } catch (e) {
        // JSON parse failed (e.g. unquoted keys) — extract via regex
        return AiChatMessage(role: 'assistant', content: _extractFromPseudoJson(res.body));
      }
      return AiChatMessage(role: 'assistant', content: _clean(res.body));
    }

    throw Exception('AI chat failed: ${res.statusCode} ${res.body}');
  }

  /// Removes surrounding pseudo-JSON wrapper if content is plain text inside.
  String _clean(String raw) {
    final t = raw.trim();
    // If it still looks like [{content:{...}}], try regex extraction
    if ((t.startsWith('[') || t.startsWith('{')) && t.contains(':')) {
      final extracted = _extractFromPseudoJson(t);
      if (extracted != t) return extracted;
    }
    return t;
  }

  /// Extracts the largest meaningful value from pseudo-JSON using regex.
  /// Handles unquoted keys like [{content: {"key": "value"}}] or [{content: {response: "value"}}].
  String _extractFromPseudoJson(String raw) {
    // First try: find a "response" field (quoted or unquoted key)
    final responseMatch = RegExp('["\']?response["\']?\\s*:\\s*"((?:[^"\\\\]|\\\\.)+)"').firstMatch(raw);
    if (responseMatch != null) return responseMatch.group(1)!.replaceAll('\\"', '"');

    // Second try: collect all "key": "value" string pairs and build readable text
    final pairRegex = RegExp(
      '["\']?([\\w\\u0400-\\u04FF_\\- ]+)["\']?\\s*:\\s*"((?:[^"\\\\]|\\\\.)*)"',
      multiLine: true,
    );
    final matches = pairRegex.allMatches(raw).toList();

    // Skip wrapper keys like "content", "role", "output"
    const skipKeys = {'content', 'role', 'output', 'message', 'response'};

    final parts = <String>[];
    for (final m in matches) {
      final key = (m.group(1) ?? '').trim().toLowerCase();
      final val = (m.group(2) ?? '').replaceAll('\\"', '"').trim();
      if (val.isNotEmpty && !skipKeys.contains(key)) {
        parts.add(val);
      }
    }

    if (parts.isNotEmpty) return parts.join('\n\n');

    // Last resort: strip all JSON-like syntax and return plain text
    return raw
        .replaceAll(RegExp(r'\[\{.*?content\s*:\s*\{', dotAll: true), '')
        .replaceAll(RegExp(r'\}\s*\}\s*\]$'), '')
        .replaceAll(RegExp(r'["{}[\]]'), '')
        .replaceAll(RegExp(r',\s*\n'), '\n')
        .trim();
  }
}
