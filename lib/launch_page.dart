import 'package:flutter/material.dart';
import 'login.dart'; // Ensure this matches your file structure

// --- Constants ---
const kPrimaryColor = Color(0xFF013D5A);
const kCreamColor = Color(0xFFFCF3E3);

// ✅ Renamed to LaunchPage (PascalCase standard)
// ⚠️ Note: Update your main.dart to call 'home: const LaunchPage()' if it breaks.
class LaunchPage extends StatelessWidget {
  const LaunchPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Media query is efficient here for responsive layouts
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // --- Background Image ---
          Positioned.fill(
            child: Image.asset(
              'assets/images/HOME SCREEN 1.png',
              fit: BoxFit.cover,
            ),
          ),

          // --- Bottom Buttons Section ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              // Combined padding logic for cleaner layout
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 50),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- 1. Get Started (Sign Up) ---
                  _buildButton(
                    context: context,
                    label: "Get Started",
                    backgroundColor: kPrimaryColor,
                    textColor: kCreamColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // Navigate to Sign Up tab (Index 1)
                          builder: (_) => Login(initialTabIndex: 1),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20), // Spacing between buttons

                  // --- 2. Login (Sign In) ---
                  _buildButton(
                    context: context,
                    label: "Login",
                    backgroundColor: kCreamColor,
                    textColor: kPrimaryColor,
                    isOutlined: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // Navigate to Login tab (Index 0)
                          builder: (_) => Login(initialTabIndex: 0),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ CEVUS Helper: Reusable Button Widget
  Widget _buildButton({
    required BuildContext context,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity, // Makes button fill width
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor, // Controls the splash/ripple color
          elevation: 8, // Standard material shadow
          shadowColor: Colors.black.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isOutlined
                ? const BorderSide(color: kPrimaryColor, width: 2.0)
                : BorderSide.none,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'RedHatDisplay',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.0,
            color: textColor,
          ),
        ),
      ),
    );
  }
}