import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

import 'ai_chat_service.dart';
import 'models/ai_chat_response.dart';
import 'models/ai_chat_request.dart';

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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.aiChatTitle ?? 'AI Chat'),
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final entry = _messages[i];
                final m = entry.message;
                final isUser = m.role == 'user';
                final isSystem = m.role == 'system';

                final userBubbleColor = Theme.of(context).colorScheme.primary;
                final aiBubbleColor = Colors.white;
                final systemBubbleColor = Colors.red.shade50;

                final bubbleColor = isSystem
                    ? systemBubbleColor
                    : isUser
                    ? userBubbleColor
                    : aiBubbleColor;

                final userRadius = const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                );
                final aiRadius = const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                );
                final bubbleRadius = isUser ? userRadius : aiRadius;

                void copyContent() {
                  Clipboard.setData(ClipboardData(text: m.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)?.copied ?? 'Copied',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.smart_toy_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          child: GestureDetector(
                            onLongPress: copyContent,
                            child: Container(
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: bubbleRadius,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isUser)
                                    Text(
                                      m.content,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                    )
                                  else
                                    MarkdownBody(
                                      data: m.content,
                                      styleSheet: MarkdownStyleSheet(
                                        p: const TextStyle(
                                          color: Color(0xFF1A1A2E),
                                          fontSize: 15,
                                          height: 1.5,
                                        ),
                                        strong: const TextStyle(
                                          color: Color(0xFF1A1A2E),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                        em: const TextStyle(
                                          color: Color(0xFF1A1A2E),
                                          fontStyle: FontStyle.italic,
                                          fontSize: 15,
                                        ),
                                        code: TextStyle(
                                          backgroundColor: Colors.grey.shade200,
                                          color: const Color(0xFF5C2D91),
                                          fontFamily: 'monospace',
                                          fontSize: 13,
                                        ),
                                        codeblockDecoration: BoxDecoration(
                                          color: const Color(0xFF1E1E2E),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        codeblockPadding: const EdgeInsets.all(12),
                                        blockquoteDecoration: BoxDecoration(
                                          border: Border(
                                            left: BorderSide(
                                              color: Theme.of(context).colorScheme.primary,
                                              width: 3,
                                            ),
                                          ),
                                        ),
                                        blockquotePadding: const EdgeInsets.only(left: 10),
                                        listBullet: const TextStyle(
                                          color: Color(0xFF1A1A2E),
                                          fontSize: 15,
                                        ),
                                        h1: const TextStyle(
                                          color: Color(0xFF1A1A2E),
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        h2: const TextStyle(
                                          color: Color(0xFF1A1A2E),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        h3: const TextStyle(
                                          color: Color(0xFF1A1A2E),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _formatTime(entry.time),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isUser
                                                ? Colors.white70
                                                : Colors.grey.shade500,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: copyContent,
                                        child: Icon(
                                          Icons.copy_rounded,
                                          size: 14,
                                          color: isUser
                                              ? Colors.white70
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6FA),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: _ctrl,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText:
                                AppLocalizations.of(context)?.typeMessageHint ??
                                'Type a message...',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isSending
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 44,
                              height: 44,
                              child: Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : Material(
                              key: const ValueKey('send'),
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(22),
                              child: InkWell(
                                onTap: _send,
                                borderRadius: BorderRadius.circular(22),
                                child: const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
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
