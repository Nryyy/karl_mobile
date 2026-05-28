class AiChatMessage {
  final String role;
  final String content;

  AiChatMessage({required this.role, required this.content});

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('role') && json.containsKey('content')) {
      return AiChatMessage(
        role: json['role'] ?? 'assistant',
        content: json['content'] ?? '',
      );
    }
    if (json.containsKey('message')) {
      return AiChatMessage(
        role: 'assistant',
        content: json['message'].toString(),
      );
    }
    if (json.containsKey('output')) {
      return AiChatMessage(
        role: 'assistant',
        content: json['output'].toString(),
      );
    }
    return AiChatMessage(role: 'assistant', content: json.toString());
  }

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}
