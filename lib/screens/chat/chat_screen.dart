import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  WebSocketChannel? _channel;
  final List<_ChatBubble> _messages = [];
  bool _connecting = true;
  bool _isTyping = false;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    setState(() => _connecting = true);
    try {
      _channel = await _chatService.connectWebSocket();
      setState(() {
        _connecting = false;
        _connected = true;
      });

      _channel!.stream.listen(
        (data) {
          final json = jsonDecode(data as String);
          final type = json['type'] as String;
          final msg = json['message'] as String;

          if (type == 'system') {
            // Connected message — skip or show
            return;
          } else if (type == 'typing') {
            setState(() => _isTyping = true);
            _scrollToBottom();
          } else if (type == 'response') {
            setState(() {
              _isTyping = false;
              _messages.add(
                _ChatBubble(text: msg, isUser: false, time: DateTime.now()),
              );
            });
            _scrollToBottom();
          } else if (type == 'error') {
            setState(() => _isTyping = false);
            _showError(msg);
          }
        },
        onError: (e) {
          setState(() {
            _connected = false;
            _isTyping = false;
          });
        },
        onDone: () {
          setState(() {
            _connected = false;
            _isTyping = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _connecting = false;
        _connected = false;
      });
      _showError('Could not connect to AI chat');
    }
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || !_connected) return;

    setState(() {
      _messages.add(
        _ChatBubble(text: text, isUser: true, time: DateTime.now()),
      );
      _isTyping = true;
    });

    _chatService.sendMessage(text);
    _msgCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _clearHistory() async {
    try {
      await _chatService.clearHistory();
      setState(() => _messages.clear());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chat history cleared')));
    } catch (_) {}
  }

  @override
  void dispose() {
    _chatService.disconnect();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Assistant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  _connected ? 'Online' : 'Connecting...',
                  style: TextStyle(
                    fontSize: 11,
                    color: _connected ? Colors.greenAccent : Colors.white60,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _clearHistory,
            tooltip: 'Clear history',
          ),
          if (!_connected)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _connect,
              tooltip: 'Reconnect',
            ),
        ],
      ),

      body: Column(
        children: [
          // ── Connecting banner ──────────────────────────
          if (_connecting)
            Container(
              color: Colors.orange.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Connecting to AI...',
                    style: TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ),

          if (!_connected && !_connecting)
            Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Disconnected',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: _connect,
                    child: const Text('Reconnect'),
                  ),
                ],
              ),
            ),

          // ── Messages ───────────────────────────────────
          Expanded(
            child:
                _messages.isEmpty && !_isTyping
                    ? _buildEmptyState()
                    : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isTyping && index == _messages.length) {
                          return _buildTypingIndicator();
                        }
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
          ),

          // ── Input ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5FA),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Ask anything about courses...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _connected ? const Color(0xFF6C63FF) : Colors.grey,
                      borderRadius: BorderRadius.circular(23),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatBubble bubble) {
    final isUser = bubble.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF6C63FF) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bubble.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFF1A1A2E),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${bubble.time.hour}:${bubble.time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser ? Colors.white60 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.grey,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _dot(0),
                const SizedBox(width: 4),
                _dot(200),
                const SizedBox(width: 4),
                _dot(400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder:
          (_, value, __) => Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Color(0xFF6C63FF).withOpacity(value),
              shape: BoxShape.circle,
            ),
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              size: 40,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'AI Learning Assistant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about courses,\ntopics, or your learning journey!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          // Suggestion chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children:
                [
                      'What is Python?',
                      'Best courses for beginners',
                      'How to learn Flutter?',
                      'Explain REST APIs',
                    ]
                    .map(
                      (suggestion) => GestureDetector(
                        onTap: () {
                          _msgCtrl.text = suggestion;
                          _sendMessage();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF6C63FF).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            suggestion,
                            style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble {
  final String text;
  final bool isUser;
  final DateTime time;

  _ChatBubble({required this.text, required this.isUser, required this.time});
}
