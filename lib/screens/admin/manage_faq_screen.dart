import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageFaqScreen extends StatefulWidget {
  const ManageFaqScreen({super.key});

  @override
  State<ManageFaqScreen> createState() => _ManageFaqScreenState();
}

class _ManageFaqScreenState extends State<ManageFaqScreen> {
  final firestore = FirebaseFirestore.instance;

  final questionController = TextEditingController();
  final answerController = TextEditingController();

  // ✅ ADD FAQ
  Future<void> addFAQ() async {
    if (questionController.text.isEmpty ||
        answerController.text.isEmpty) {
      return; // ✅ FIXED (added braces)
    }

    await firestore
        .collection('admin')
        .doc('faqs')
        .collection('items')
        .add({
      'question': questionController.text.trim(),
      'answer': answerController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    questionController.clear();
    answerController.clear();
  }

  // ✅ DELETE FAQ
  Future<void> deleteFAQ(String id) async {
    await firestore
        .collection('admin')
        .doc('faqs')
        .collection('items')
        .doc(id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage FAQs"),
        backgroundColor: Colors.redAccent,
      ),
      body: Column(
        children: [

          // ➕ ADD FAQ FORM
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(
                    labelText: "Question",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: answerController,
                  decoration: const InputDecoration(
                    labelText: "Answer",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: addFAQ,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text("Add FAQ"),
                )
              ],
            ),
          ),

          // 📋 FAQ LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('admin')
                  .doc('faqs')
                  .collection('items')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text("No FAQs yet"),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data =
                        doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(
                          data['question'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle:
                            Text(data['answer'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red),
                          onPressed: () => deleteFAQ(doc.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}