import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color background = Color(0xFFF8FAFC);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController subjectController =
      TextEditingController();

  final TextEditingController feedbackController =
      TextEditingController();

  int selectedRating = 0;

  bool isLoading = false;

  /// ================= SUBMIT FEEDBACK =================
  Future<void> submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a rating"),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('feedback')
          .add({

        'userId': user?.uid ?? '',
        'email': user?.email ?? '',

        'subject': subjectController.text.trim(),

        'message': feedbackController.text.trim(),

        'rating': selectedRating,

        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Feedback submitted successfully 💙",
          ),
        ),
      );

      subjectController.clear();
      feedbackController.clear();

      setState(() {
        selectedRating = 0;
      });

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error submitting feedback: $e",
          ),
        ),
      );
    } finally {

      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,

        title: const Text(
          "Feedback & Support",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// ================= HEADER =================
              Center(
                child: Column(
                  children: [

                    Container(
                      width: 110,
                      height: 110,
                      padding: const EdgeInsets.all(18),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),

                      child: Image.asset(
                        "assets/logo.png",
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "We Value Your Feedback",
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Help us improve SickleCare by sharing your experience, reporting issues, or suggesting new features.",
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color: Colors.grey,
                        height: 1.6,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              /// ================= SUBJECT =================
              _buildLabel("Subject"),

              const SizedBox(height: 10),

              TextFormField(
                controller: subjectController,

                decoration: _inputDecoration(
                  "Enter feedback subject",
                  Icons.subject,
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter subject";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 25),

              /// ================= MESSAGE =================
              _buildLabel("Your Feedback"),

              const SizedBox(height: 10),

              TextFormField(
                controller: feedbackController,
                maxLines: 6,

                decoration: _inputDecoration(
                  "Describe your experience or issue...",
                  Icons.feedback_outlined,
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter feedback";
                  }

                  if (value.trim().length < 10) {
                    return "Feedback too short";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 30),

              /// ================= RATING =================
              _buildLabel("Rate Your Experience"),

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: List.generate(5, (index) {
                  final star = index + 1;

                  return IconButton(
                    iconSize: 38,

                    onPressed: () {
                      setState(() {
                        selectedRating = star;
                      });
                    },

                    icon: Icon(
                      star <= selectedRating
                          ? Icons.star
                          : Icons.star_border,

                      color: Colors.amber,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 40),

              /// ================= SUBMIT BUTTON =================
              SizedBox(
                width: double.infinity,
                height: 58,

                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  onPressed: isLoading
                      ? null
                      : submitFeedback,

                  icon: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,

                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.send_rounded),

                  label: Text(
                    isLoading
                        ? "Submitting..."
                        : "Submit Feedback",

                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              /// ================= INFO CARD =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Column(
                  children: const [

                    Icon(
                      Icons.security,
                      color: primaryBlue,
                      size: 40,
                    ),

                    SizedBox(height: 15),

                    Text(
                      "Your feedback is securely stored and only used to improve app quality and user experience.",
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= INPUT DECORATION =================
  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,

      prefixIcon: Icon(icon),

      filled: true,
      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),

        borderSide: const BorderSide(
          color: primaryBlue,
          width: 1.5,
        ),
      ),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
    );
  }

  /// ================= LABEL =================
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }
}