import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:revive_eco_tech_app/home.dart';
import 'package:revive_eco_tech_app/launch_page.dart'; // Ensure this import matches your file structure
import 'package:revive_eco_tech_app/emailverification.dart';

// --- Constants ---
const kPrimaryColor = Color(0xFF013D5A);
const kCreamColor = Color(0xFFFCF3E3);
const kAccentColor = Color(0xFFA6CB4E);

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // 1. LOADING STATE (Branded)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: kCreamColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Show Logo for a professional "Splash" feel
                  Image.asset(
                    'assets/images/home/logo2.png', // Ensure you have this asset
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(
                    color: kAccentColor,
                    strokeWidth: 3,
                  ),
                ],
              ),
            ),
          );
        }

        // 2. LOGGED IN STATE
        if (snapshot.hasData) {
          final user = snapshot.data!;

          // Check if user authenticated via Phone
          final isPhoneUser = user.providerData.any(
                (userInfo) => userInfo.providerId == 'phone',
          );

          // ✅ LOGIC CHECK:
          // 1. Phone users -> Home (No email to verify)
          // 2. Email users (Verified) -> Home
          // 3. Email users (Unverified) -> Verification Page
          if (isPhoneUser || user.emailVerified) {
            return const HomePage();
          } else {
            return const EmailVerificationPage();
          }
        }

        // 3. LOGGED OUT STATE
        else {
          return const LaunchPage();
        }
      },
    );
  }
}