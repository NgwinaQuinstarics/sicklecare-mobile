import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool obscure = true;

  Future<void> signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // 1. Create Auth user
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = credential.user!.uid;

      // 2. CREATE USER PROFILE IN FIRESTORE (IMPORTANT FIX)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'age': 0,
        'contact': '',
        'genotype': 'SS',
        'notifications': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully")),
      );

      // ❗ DO NOT NAVIGATE — AuthWrapper handles it
    } on FirebaseAuthException catch (e) {
      String message = "Signup failed";

      if (e.code == 'email-already-in-use') {
        message = "Email already in use";
      } else if (e.code == 'weak-password') {
        message = "Weak password (min 6 chars)";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email";
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [

                const Text("Create Account",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

                const SizedBox(height: 20),

                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Full Name"),
                  validator: (v) => v!.isEmpty ? "Enter name" : null,
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (v) => v!.isEmpty ? "Enter email" : null,
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: passwordController,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: "Password",
                    suffixIcon: IconButton(
                      icon: Icon(obscure
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                  validator: (v) =>
                      v!.length < 6 ? "Min 6 characters" : null,
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: isLoading ? null : signup,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}