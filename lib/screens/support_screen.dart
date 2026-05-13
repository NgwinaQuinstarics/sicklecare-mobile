import 'package:flutter/material.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> emergencyContacts = const [
    {"name": "Cameroon Ambulance", "number": "112"},
    {"name": "Fire Brigade", "number": "118"},
    {"name": "Police", "number": "117"},
    {"name": "Sickle Cell Support", "number": "+237600000000"},
    {"name": "Emergency Hospital", "number": "+237233123456"},
  ];

  final List<Map<String, String>> chatMessages = [
    {
      "role": "ai",
      "text":
          "Hello 👋\nI'm your health support assistant.\nDescribe your symptoms or situation and I'll try to help."
    }
  ];

  // ================= SEND MESSAGE =================
  void sendMessage() {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      chatMessages.add({
        "role": "user",
        "text": text,
      });

      chatMessages.add({
        "role": "ai",
        "text": getAIResponse(text),
      });
    });

    _messageController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // ================= AI LOGIC =================
  String getAIResponse(String input) {
    input = input.toLowerCase();

    // PAIN
    if (input.contains("pain")) {
      return "Pain can have different causes. Please tell me where the pain is located and how severe it is.";
    }

    // FEVER
    else if (input.contains("fever")) {
      return "A fever may indicate infection. Drink water, rest, and monitor your temperature carefully.";
    }

    // HEADACHE
    else if (input.contains("headache")) {
      return "Headaches can result from stress, dehydration, or illness. Try resting and drinking water.";
    }

    // COUGH
    else if (input.contains("cough")) {
      return "Persistent cough may require medical attention if it lasts several days or causes breathing issues.";
    }

    // CHEST PAIN
    else if (input.contains("chest")) {
      return "Chest pain can be serious. Please seek emergency medical attention immediately if severe.";
    }

    // BREATHING
    else if (input.contains("breath") ||
        input.contains("breathing")) {
      return "Difficulty breathing is a medical emergency. Please contact emergency services immediately.";
    }

    // SICKLE CELL
    else if (input.contains("sickle")) {
      return "Sickle cell crisis can become serious quickly. Stay hydrated and seek medical support if symptoms worsen.";
    }

    // STRESS
    else if (input.contains("stress") ||
        input.contains("anxiety")) {
      return "Stress and anxiety can affect your health. Try resting and talking to someone you trust.";
    }

    // HELP
    else if (input.contains("help")) {
      return "I'm here to help. Please explain your symptoms or situation clearly.";
    }

    // GREETINGS
    else if (input.contains("hello") ||
        input.contains("hi")) {
      return "Hello 👋 How are you feeling today?";
    }

    // THANK YOU
    else if (input.contains("thank")) {
      return "You're welcome 💙 Stay safe and take care of yourself.";
    }

    // DEFAULT SMART RESPONSE
    else {
      return "Thank you for sharing. Based on what you said, I recommend monitoring your symptoms carefully and seeking medical attention if things worsen.";
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        title: const Text(
          "AI Health Support",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: Column(
        children: [

          // ================= EMERGENCY CONTACTS =================
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.red.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "Emergency Contacts",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: emergencyContacts.length,
                    itemBuilder: (context, index) {

                      final contact = emergencyContacts[index];

                      return Container(
                        width: 190,
                        margin: const EdgeInsets.only(right: 10),

                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),

                          child: Padding(
                            padding: const EdgeInsets.all(12),

                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [

                                Text(
                                  contact["name"]!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Text(
                                  contact["number"]!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),

                                const Spacer(),

                                SizedBox(
                                  width: double.infinity,

                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // Add phone launcher later
                                    },

                                    icon: const Icon(Icons.call),
                                    label: const Text("Call"),

                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ================= CHAT =================
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: chatMessages.length,

              itemBuilder: (context, index) {

                final msg = chatMessages[index];
                final isUser = msg["role"] == "user";

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,

                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),

                    padding: const EdgeInsets.all(14),

                    constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width * 0.75,
                    ),

                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blue
                          : Colors.white,

                      borderRadius: BorderRadius.circular(18),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                        )
                      ],
                    ),

                    child: Text(
                      msg["text"]!,
                      style: TextStyle(
                        color:
                            isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ================= INPUT =================
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,

            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: _messageController,

                    decoration: InputDecoration(
                      hintText: "Describe your symptoms...",

                      filled: true,
                      fillColor: Colors.grey.shade100,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.red,

                  child: IconButton(
                    onPressed: sendMessage,

                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}