import 'package:flutter/material.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> messages = [];

  bool isTyping = false;

  static const Color userColor = Color(0xFF1E40AF);
  static const Color aiColor = Color(0xFFF1F5F9);

  /// ================= SEND MESSAGE =================
  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add({
        "role": "user",
        "text": text,
      });
      isTyping = true;
    });

    _controller.clear();
    scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 800));

    final response = generateAIResponse(text);

    setState(() {
      messages.add({
        "role": "ai",
        "text": response,
      });
      isTyping = false;
    });

    scrollToBottom();
  }

  /// ================= SIMPLE AI ENGINE =================
  String generateAIResponse(String input) {
    final msg = input.toLowerCase();

    if (msg.contains("pain")) {
      return "I understand you're in pain. Please rest, hydrate, and if pain is severe, contact a doctor immediately.";
    }

    if (msg.contains("water") || msg.contains("hydrate")) {
      return "Hydration is very important for sickle cell patients. Try to drink water every 30–60 minutes.";
    }

    if (msg.contains("fever")) {
      return "Fever may indicate an infection. Monitor your temperature and seek medical attention if it persists.";
    }

    if (msg.contains("hello") || msg.contains("hi")) {
      return "Hello 👋 I am your SickleCare AI Assistant. How are you feeling today?";
    }

    if (msg.contains("emergency")) {
      return "🚨 If this is an emergency, please call 119 (Ambulance Cameroon) immediately.";
    }

    return "I understand. Can you describe your symptoms more clearly so I can help you better?";
  }

  /// ================= SCROLL =================
  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Health Assistant 🤖"),
        backgroundColor: const Color(0xFF1E40AF),
      ),

      body: Column(
        children: [

          /// ================= CHAT LIST =================
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (isTyping && index == messages.length) {
                  return const _TypingBubble();
                }

                final msg = messages[index];
                final isUser = msg["role"] == "user";

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color: isUser ? userColor : aiColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg["text"],
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          /// ================= INPUT BOX =================
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black12,
                )
              ],
            ),
            child: Row(
              children: [

                /// TEXT FIELD
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ask me anything about your health...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                /// SEND BUTTON
                CircleAvatar(
                  backgroundColor: userColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => sendMessage(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= TYPING INDICATOR =================
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text("AI is typing..."),
      ),
    );
  }
}