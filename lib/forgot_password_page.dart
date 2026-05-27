import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Constants ---
const kPrimaryColor = Color(0xFF013D5A);
const kAccentColor = Color(0xFFA6CB4E);
const kCreamColor = Color(0xFFFCF3E3);

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: isError ? Colors.red : kAccentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      _showSnackBar("Password reset link sent! Check your email.");
      if (mounted) Navigator.pop(context); // Go back to login
    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred. Please try again.";
      if (e.code == 'user-not-found') {
        errorMessage = "No user found for that email.";
      }
      _showSnackBar(errorMessage, isError: true);
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kCreamColor,
        appBar: AppBar(
          title: const Text(
            'Reset Password',
            style: TextStyle(
              fontFamily: 'RedHatDisplay',
              fontWeight: FontWeight.bold,
              color: kCreamColor,
              letterSpacing: 1.0,
            ),
          ),
          centerTitle: true,
          backgroundColor: kPrimaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kCreamColor),
            onPressed: () => Navigator.pop(context),
          ),
          // ✅ 1. CEVUS: Signature Curvy Header
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Title Section
                  const Text(
                    'Forgot your password?',
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'RedHatDisplay',
                      fontWeight: FontWeight.w800,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Don't worry! Enter your email below and we'll send you a link to reset it.",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'RedHatDisplay',
                      color: kPrimaryColor.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ✅ 2. CEVUS: Consistent Input Style
                  Container(
                    decoration: BoxDecoration(
                      color: kCreamColor,
                      border: Border.all(color: kPrimaryColor, width: 2.5),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryColor.withOpacity(0.15),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(3, 3),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                          color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'E-mail',
                        hintStyle: TextStyle(
                          fontFamily: 'RedHatDisplay',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kPrimaryColor.withOpacity(0.6),
                        ),
                        prefixIcon: const Icon(
                          Icons.email_rounded,
                          size: 28,
                          color: kAccentColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        final emailRegex = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ✅ 3. CEVUS: Vibrant Gradient Button
                  GestureDetector(
                    onTap: _isLoading ? null : _sendResetLink,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        // Gradient for depth
                        gradient: const LinearGradient(
                          colors: [kAccentColor, Color(0xFFC0E862)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        // Glow Shadow
                        boxShadow: [
                          BoxShadow(
                            color: kAccentColor.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 3),
                        )
                            : const Text(
                          'Send Reset Link',
                          style: TextStyle(
                            fontFamily: 'RedHatDisplay',
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}