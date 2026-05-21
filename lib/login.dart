import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'signup.dart';
import 'screens/settings/terms_screen.dart';
import 'screens/settings/privacy_policy_screen.dart';

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
  bool obscurePassword = true;

  /// CHECKBOX
  bool agreeToTerms = false;

  /// LOGIN FUNCTION
  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    /// CHECK TERMS
    if (!agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please accept Privacy Policy and Terms & Conditions",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login Successful"),
          backgroundColor: Colors.green,
        ),
      );

    } on FirebaseAuthException catch (e) {
      String message = "Login failed";

      switch (e.code) {
        case 'user-not-found':
          message = "No account found";
          break;

        case 'wrong-password':
          message = "Incorrect password";
          break;

        case 'invalid-email':
          message = "Invalid email";
          break;

        case 'invalid-credential':
          message = "Invalid email or password";
          break;

        case 'user-disabled':
          message = "Account disabled";
          break;

        case 'network-request-failed':
          message = "Check your internet connection";
          break;

        case 'too-many-requests':
          message = "Too many attempts. Try again later";
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong"),
          backgroundColor: Colors.red,
        ),
      );

    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// RESET PASSWORD
  Future<void> resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter your email first"),
        ),
      );

      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset email sent"),
          backgroundColor: Colors.green,
        ),
      );

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Reset failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,

      filled: true,
      fillColor: Colors.grey.shade100,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 2,
        ),
      ),
    );
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
                borderRadius: BorderRadius.circular(24),

                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.15),
                    blurRadius: 15,
                    spreadRadius: 3,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),

              child: Form(
                key: _formKey,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    /// LOGO
                    Image.asset(
                      'assets/logo.png',
                      height: 110,
                    ),

                    const SizedBox(height: 20),

                    /// TITLE
                    const Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Login to continue your health journey",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 35),

                    /// EMAIL
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,

                      decoration: inputDecoration(
                        label: "Email",
                        icon: Icons.email_outlined,
                      ),

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter your email";
                        }

                        if (!value.contains("@")) {
                          return "Enter a valid email";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    /// PASSWORD
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,

                      decoration: inputDecoration(
                        label: "Password",
                        icon: Icons.lock_outline,

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
                          return "Enter your password";
                        }

                        if (value.length < 6) {
                          return "Minimum 6 characters";
                        }

                        return null;
                      },
                    ),

                    /// FORGOT PASSWORD
                    Align(
                      alignment: Alignment.centerRight,

                      child: TextButton(
                        onPressed: resetPassword,

                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),

                    /// TERMS CHECKBOX
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Checkbox(
                          value: agreeToTerms,
                          activeColor: Colors.redAccent,

                          onChanged: (value) {
                            setState(() {
                              agreeToTerms = value ?? false;
                            });
                          },
                        ),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),

                            child: Wrap(
                              children: [

                                const Text(
                                  "I agree to the ",
                                  style: TextStyle(fontSize: 14),
                                ),

                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const PrivacyPolicyScreen(),
                                      ),
                                    );
                                  },

                                  child: const Text(
                                    "Privacy Policy",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      decoration:
                                          TextDecoration.underline,
                                    ),
                                  ),
                                ),

                                const Text(
                                  " and ",
                                  style: TextStyle(fontSize: 14),
                                ),

                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const TermsScreen(),
                                      ),
                                    );
                                  },

                                  child: const Text(
                                    "Terms & Conditions",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      decoration:
                                          TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,

                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),

                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// SIGNUP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        const Text(
                          "Don't have an account?",
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignupScreen(),
                              ),
                            );
                          },

                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
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
      ),
    );
  }
}