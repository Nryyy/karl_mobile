import 'package:flutter/material.dart';

import 'ai_chat_service.dart';
import 'models/ai_chat_response.dart';
import 'models/ai_chat_request.dart';
import 'package:flutter/services.dart';

class ChatScreen extends StatefulWidget {
  final AiChatService service;
  final String? bearerToken;

  const ChatScreen({super.key, required this.service, this.bearerToken});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<_MessageEntry> _messages = [];
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        _MessageEntry(
          AiChatMessage(role: 'user', content: text),
          DateTime.now(),
        ),
      );
      _isSending = true;
      _ctrl.clear();
    });
    try {
      final resp = await widget.service.send(
        AiChatRequest(input: text),
        bearerToken: widget.bearerToken,
      );
      setState(() {
        _messages.add(_MessageEntry(resp, DateTime.now()));
      });
      // scroll to bottom after a short delay so UI updates
      await Future.delayed(const Duration(milliseconds: 80));
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } catch (e) {
      setState(() {
        _messages.add(
          _MessageEntry(
            AiChatMessage(role: 'system', content: 'Error: $e'),
            DateTime.now(),
          ),
        );
      });
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final entry = _messages[i];
                final m = entry.message;
                final isUser = m.role == 'user';
                final isSystem = m.role == 'system';
                final bg = isSystem
                    ? Colors.red.shade50
                    : isUser
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade100;
                final textColor = isUser ? Colors.white : Colors.black87;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.2),
                          child: const Icon(
                            Icons.smart_toy,
                            size: 18,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Material(
                            elevation: 0.5,
                            borderRadius: BorderRadius.circular(12),
                            color: bg,
                            child: InkWell(
                              onLongPress: () {
                                Clipboard.setData(
                                  ClipboardData(text: m.content),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Скопійовано')),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.content,
                                      style: TextStyle(color: textColor),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatTime(entry.time),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey.shade600,
                                              ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.copy,
                                            size: 18,
                                            color: Colors.grey.shade600,
                                          ),
                                          onPressed: () {
                                            Clipboard.setData(
                                              ClipboardData(text: m.content),
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('Скопійовано'),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (isUser) const SizedBox(width: 8),
                      if (isUser)
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.2),
                          child: const Icon(
                            Icons.person,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: TextField(
                      controller: _ctrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _isSending
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : IconButton(
                          onPressed: _send,
                          icon: const Icon(Icons.send),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final dt = t.toLocal();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _MessageEntry {
  final AiChatMessage message;
  final DateTime time;

  _MessageEntry(this.message, this.time);
}
