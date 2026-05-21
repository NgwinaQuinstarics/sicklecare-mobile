import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  Future<void> signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {

      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = credential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );

    } on FirebaseAuthException catch (e) {

      String message = "Signup failed";

      switch (e.code) {
        case 'email-already-in-use':
          message = "Email already in use";
          break;

        case 'weak-password':
          message = "Weak password";
          break;

        case 'invalid-email':
          message = "Invalid email";
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );

    } finally {

      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Container(
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),

                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),

              child: Form(
                key: _formKey,

                child: Column(
                  children: [

                    /// LOGO
                    Image.asset(
                      'assets/logo.png',
                      height: 100,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// NAME
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter full name";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    /// EMAIL
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter email";
                        }

                        if (!value.contains("@")) {
                          return "Enter valid email";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    /// PASSWORD
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter password";
                        }

                        if (value.length < 6) {
                          return "Minimum 6 characters";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    /// CONFIRM PASSWORD
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword =
                                  !obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value != passwordController.text) {
                          return "Passwords do not match";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 30),

                    /// SIGNUP BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,

                      child: ElevatedButton(
                        onPressed: isLoading ? null : signup,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),

                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Create Account",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        const Text("Already have an account?"),

                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Login"),
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
    );
  }
}