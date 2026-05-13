import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool obscure = true;

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      // ❗ DO NOT NAVIGATE HERE
      // AuthWrapper handles routing automatically
    } on FirebaseAuthException catch (e) {
      String message = "Login failed";

      switch (e.code) {
        case 'user-not-found':
          message = "No user found";
          break;
        case 'wrong-password':
          message = "Wrong password";
          break;
        case 'invalid-email':
          message = "Invalid email";
          break;
        case 'user-disabled':
          message = "Account disabled";
          break;
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

                const Text("Login",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

                const SizedBox(height: 20),

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
                  onPressed: isLoading ? null : login,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}