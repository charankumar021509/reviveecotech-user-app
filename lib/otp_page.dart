import 'package:flutter/material.dart';
import 'package:revive_eco_tech_app/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ UNCOMMENTED
import 'package:cloud_functions/cloud_functions.dart'; // ✅ ADDED: For role assignment
import 'package:sms_autofill/sms_autofill.dart';
import 'dart:async';

// --- Constants ---
const kPrimaryColor = Color(0xFF013856);
const kAccentColor = Color(0xFFa7cd47);
const kCreamColor = Color(0xFFfcf3e2);

class OtpPage extends StatefulWidget {
  final String verificationId;
  const OtpPage({super.key, required this.verificationId});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  // Timer Logic
  final ValueNotifier<int> _timerNotifier = ValueNotifier<int>(30);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _listenForSms();
  }

  void _startTimer() {
    _timerNotifier.value = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerNotifier.value > 0) {
        _timerNotifier.value--;
      } else {
        timer.cancel();
      }
    });
  }

  void _listenForSms() async {
    try {
      await SmsAutoFill().listenForCode();
    } catch (e) {
      // Ignore
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    SmsAutoFill().unregisterListener();
    _timer?.cancel();
    _timerNotifier.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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

  Future<void> _verifyOtp(String smsCode) async {
    if (smsCode.length != 6) {
      if (smsCode.isNotEmpty) {
        _showSnackBar("Please enter a valid 6-digit code.", isError: true);
      }
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: smsCode.trim(),
      );

      // Sign in with the credential
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // ✅ NEW LOGIC: Check if it's a new user to assign the role
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnap = await userDocRef.get();

        if (!docSnap.exists) {
          // Create base profile using merge to avoid race condition with auth trigger
          await userDocRef.set({
            'name': 'User-${user.uid.substring(0, 6)}',
            'phone': user.phoneNumber ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'email': '',
          }, SetOptions(merge: true));

          // Assign role via Cloud Function
          try {
            final httpsCallable = FirebaseFunctions.instance.httpsCallable('assignUserRole');
            await httpsCallable.call({'role': 'customer'});

            // CRITICAL: Force refresh token so claims take effect immediately
            await user.getIdToken(true);
            debugPrint('✅ Customer role assigned successfully via Phone Auth.');
          } catch (e) {
            debugPrint('❌ Error assigning role: $e');
          }
        }
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Invalid OTP", isError: true);
      setState(() => _isLoading = false);
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kCreamColor,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                height: 220,
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
                          child: const Icon(Icons.phonelink_ring_rounded, size: 50, color: kAccentColor),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Verification Code",
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

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    const Text(
                      "Enter Confirmation Code",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "We have sent a 6-digit code to your phone number.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      height: 60,
                      child: PinFieldAutoFill(
                        controller: _codeController,
                        codeLength: 6,
                        autoFocus: true,
                        enabled: !_isLoading,
                        onCodeChanged: (code) {
                          if (code?.length == 6) {
                            _verifyOtp(code!);
                          }
                        },
                        cursor: Cursor(color: kPrimaryColor, enabled: true, width: 2),
                        decoration: BoxLooseDecoration(
                          strokeColorBuilder: PinListenColorBuilder(kAccentColor, Colors.grey.shade400),
                          bgColorBuilder: FixedColorBuilder(Colors.white),
                          strokeWidth: 2,
                          radius: const Radius.circular(12),
                          textStyle: const TextStyle(fontSize: 20, color: kPrimaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    GestureDetector(
                      onTap: _isLoading ? null : () => _verifyOtp(_codeController.text),
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [kAccentColor, Color(0xFFC0E862)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(color: kAccentColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 3))
                              : const Text(
                            "Verify & Continue",
                            style: TextStyle(fontFamily: 'RedHatDisplay', fontWeight: FontWeight.bold, color: kPrimaryColor, fontSize: 18),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    ValueListenableBuilder<int>(
                      valueListenable: _timerNotifier,
                      builder: (context, timeLeft, child) {
                        final bool canResend = timeLeft == 0;
                        return TextButton(
                          onPressed: canResend ? () {
                            _showSnackBar("Code resent!");
                            _startTimer();
                          } : null,
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: canResend ? "Didn't receive code? " : "Resend code in ",
                                  style: TextStyle(color: kPrimaryColor.withOpacity(0.6), fontWeight: FontWeight.w600, fontFamily: 'RedHatDisplay'),
                                ),
                                TextSpan(
                                  text: canResend ? "Resend" : "00:${timeLeft.toString().padLeft(2, '0')}",
                                  style: TextStyle(color: canResend ? kPrimaryColor : kAccentColor, fontWeight: FontWeight.bold, fontFamily: 'RedHatDisplay'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
}