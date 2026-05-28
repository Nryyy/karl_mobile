class AiChatRequest {
  final String? systemPrompt;
  final String input;

  AiChatRequest({this.systemPrompt, required this.input});

  Map<String, dynamic> toJson() => {
    'systemPrompt': systemPrompt,
    'input': input,
  };
}
