import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:revive_eco_tech_app/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Constants ---
const kPrimaryColor = Color(0xFF013D5A);
const kAccentColor = Color(0xFFA6CB4E);
const kCreamColor = Color(0xFFFCF3E3);

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool isVerified = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSnackBar("Please check your inbox to verify your email.",
          isError: false, isInfo: true);
    });
    // Initial check (silent)
    _checkVerification(silent: true);
  }

  void _showSnackBar(String message, {bool isError = false, bool isInfo = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: isError ? Colors.red : (isInfo ? kPrimaryColor : kAccentColor),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> _checkVerification({bool silent = false}) async {
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      setState(() {
        isVerified = user?.emailVerified ?? false;
        isLoading = false;
      });

      if (isVerified) {
        if (user != null) {
          final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
          final docSnap = await userDocRef.get();

          if (!docSnap.exists) {
            await userDocRef.set({
              'name': user.displayName ?? 'User-${user.uid.substring(0, 6)}',
              'phone': '',
              'createdAt': FieldValue.serverTimestamp(),
              'email': user.email,
            });
          }
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        if (!silent) {
          _showSnackBar("Email not verified yet. Check your inbox & spam folder.", isError: true);
        }
      }
    } catch (e) {
      if (!silent) _showSnackBar("Error checking status: $e", isError: true);
      setState(() => isLoading = false);
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      _showSnackBar("Verification email resent! Check your inbox.");
    } catch (e) {
      _showSnackBar("Failed to resend email. Wait a moment and try again.", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCreamColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ✅ 1. CEVUS: Curvy Header
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: kPrimaryColor,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
                ],
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mark_email_unread_outlined, size: 60, color: kAccentColor),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Verify Your Email',
                        style: TextStyle(
                          fontFamily: 'RedHatDisplay',
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: kCreamColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ✅ 2. Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  Text(
                    "One Last Step!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'RedHatDisplay',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: kPrimaryColor.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "We have sent a verification link to:\n${FirebaseAuth.instance.currentUser?.email ?? 'your email'}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'RedHatDisplay',
                      fontSize: 16,
                      height: 1.5,
                      color: kPrimaryColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "(Please check your Spam folder if you don't see it)",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'RedHatDisplay',
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 50),

                  // ✅ 3. CEVUS: Vibrant Primary Button
                  SizedBox(
                    height: 60,
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [kAccentColor, Color(0xFFC0E862)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kAccentColor.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => _checkVerification(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: kPrimaryColor)
                            : const Text(
                          "I've Verified, Continue",
                          style: TextStyle(
                            fontFamily: 'RedHatDisplay',
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ 4. Clean Outline Button
                  SizedBox(
                    height: 60,
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: resendVerificationEmail,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kPrimaryColor, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        foregroundColor: kPrimaryColor, // Ripple color
                      ),
                      child: const Text(
                        "Resend Email",
                        style: TextStyle(
                          fontFamily: 'RedHatDisplay',
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Back to Login option (just in case)
                  TextButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text(
                      "Sign in with different account",
                      style: TextStyle(
                          color: kPrimaryColor.withOpacity(0.6),
                          fontWeight: FontWeight.w600
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}