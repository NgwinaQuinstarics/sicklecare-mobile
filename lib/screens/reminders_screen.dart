import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_drawer.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> reminders = [];
  final titleController = TextEditingController();
  TimeOfDay? selectedTime;

  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color bgGrey = Color(0xFFF8FAFC);
  static const Color textMain = Color(0xFF0F172A);
  static const Color successGreen = Color(0xFF15803D);
  static const Color criticalRed = Color(0xFFB91C1C);

  String get today {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  Future<void> loadReminders() async {
    final uid = user?.uid;
    if (uid == null) return;

    final doc = await firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .doc(today)
        .get();

    if (!mounted) return;

    if (doc.exists) {
      setState(() {
        reminders = List<Map<String, dynamic>>.from(
          doc.data()?['reminders'] ?? [],
        );
      });
    }
  }

  Future<void> saveReminders() async {
    final uid = user?.uid;
    if (uid == null) return;

    await firestore
        .collection('users')
        .doc(uid)
        .collection('daily')
        .doc(today)
        .set({
      'reminders': reminders,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void addReminder() {
    if (titleController.text.isEmpty || selectedTime == null) return;

    setState(() {
      reminders.add({
        'title': titleController.text,
        'hour': selectedTime!.hour,
        'minute': selectedTime!.minute,
        'completed': false,
      });

      titleController.clear();
      selectedTime = null;
    });

    saveReminders();
  }

  void toggleComplete(int index) {
    setState(() {
      reminders[index]['completed'] =
          !(reminders[index]['completed'] ?? false);
    });

    saveReminders();
  }

  void deleteReminder(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Reminder"),
        content: const Text("Are you sure you want to remove this reminder?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() => reminders.removeAt(index));
              saveReminders();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      drawer: const AppDrawer(),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryBlue),
        title: const Text(
          "DAILY SCHEDULE",
          style: TextStyle(
            color: textMain,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
      ),

      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header()),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _createCard(),
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "ACTIVE REMINDERS",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          reminders.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      "No reminders yet. Add your first task.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = reminders[index];
                        final time =
                            "${item['hour']}:${item['minute'].toString().padLeft(2, '0')}";

                        return _tile(index, item['title'], time,
                            item['completed'] ?? false);
                      },
                      childCount: reminders.length,
                    ),
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          SliverToBoxAdapter(child: _footer()),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _header() {
    final completed = reminders.where((e) => e['completed'] == true).length;

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Today's Progress",
                  style: TextStyle(color: Colors.grey)),
              Text(
                "$completed / ${reminders.length} done",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Icon(Icons.calendar_month, color: primaryBlue),
        ],
      ),
    );
  }

  Widget _createCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              hintText: "Add reminder",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) setState(() => selectedTime = picked);
            },
            child: Text(selectedTime == null
                ? "Pick Time"
                : selectedTime!.format(context)),
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: addReminder,
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Widget _tile(int index, String title, String time, bool done) {
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: done,
          activeColor: successGreen,
          onChanged: (_) => toggleComplete(index),
        ),
        title: Text(
          title,
          style: TextStyle(
            decoration: done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text("Time: $time"),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: criticalRed),
          onPressed: () => deleteReminder(index),
        ),
      ),
    );
  }

  Widget _footer() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "Consistency builds strength 💙",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}