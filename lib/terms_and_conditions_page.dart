import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'privacy_policy_page.dart';

// ==== Constants ====
const kPrimaryColor = Color(0xFF013D5A);
const kCreamColor = Color(0xFFFCF3E3);
const kAccentColor = Color(0xFFA6CB4E);

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  // ✅ FIXED: Number and Title are now perfectly center-aligned
  Widget _buildSectionCard({required int number, required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Number
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              // ✅ ALIGNMENT FIX: Aligns the Box and Text Centers
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10), // Balanced padding
                  decoration: BoxDecoration(
                    color: kCreamColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "$number",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                      fontSize: 16,
                      height: 1.0, // Ensures number doesn't have extra vertical space
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                      height: 1.2, // Tighter line height for the title
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Helper: Standard Paragraph
  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Colors.grey.shade800,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }

  // ✅ Helper: Bullet Point (Aligned)
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7.0), // Optical alignment for dot
            child: Icon(Icons.circle, size: 6, color: kAccentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Helper: Definition Text (Bold Term)
  Widget _buildDefinition(String term, String definition) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey.shade800),
          children: [
            TextSpan(
              text: "$term ",
              style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
            ),
            TextSpan(text: definition),
          ],
        ),
      ),
    );
  }

  // ✅ Helper: Legal Emphasis (ALL CAPS sections)
  Widget _buildEmphasisParagraph(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(left: BorderSide(color: Colors.grey.shade400, width: 3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade900,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCreamColor,
      // ✅ CEVUS: Premium Curved AppBar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          centerTitle: true,
          toolbarHeight: 70,
          title: const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Terms & Conditions',
              style: TextStyle(
                fontFamily: 'RedHatDisplay',
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 1.0,
                color: kCreamColor,
              ),
            ),
          ),
          backgroundColor: kPrimaryColor,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kCreamColor),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
        ),
      ),
      body: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              const Center(
                child: Text(
                  "Last Updated: August 18, 2025",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),

              // --- 1. Acceptance ---
              _buildSectionCard(
                number: 1,
                title: "Acceptance of Terms",
                children: [
                  _buildParagraph(
                      "By downloading, accessing, or using the Revive Eco Tech mobile application and any associated services (collectively, the \"App\"), you agree to be bound by these Terms and Conditions (\"Terms\"). If you do not agree to these Terms, please do not access or use the App."
                  ),
                ],
              ),

              // --- 2. Definitions ---
              _buildSectionCard(
                number: 2,
                title: "Definitions",
                children: [
                  _buildDefinition("\"We,\" \"us,\" \"our,\" and \"Company\"", "refer to Revive Eco Tech."),
                  _buildDefinition("\"You\" and \"your\"", "refer to the individual user accessing the App."),
                  _buildDefinition("\"Content\"", "refers to all information, data, text, software, graphics, messages, and other materials."),
                ],
              ),

              // --- 3. User Accounts ---
              _buildSectionCard(
                number: 3,
                title: "User Accounts",
                children: [
                  _buildDefinition("Account Creation:", "You may be required to register to access certain features. You agree to provide accurate information."),
                  _buildDefinition("Account Security:", "You are responsible for maintaining the confidentiality of your account credentials."),
                  _buildDefinition("Eligibility:", "You must be at least 18 years old to use the App. By using the App, you represent and warrant that you meet this age requirement."),
                ],
              ),

              // --- 4. Conduct ---
              _buildSectionCard(
                number: 4,
                title: "User Conduct & Responsibilities",
                children: [
                  _buildParagraph("You agree not to use the App to:"),
                  _buildBulletPoint("Violate any applicable law or regulation."),
                  _buildBulletPoint("Infringe upon intellectual property rights."),
                  _buildBulletPoint("Harass, abuse, or harm another person."),
                  _buildBulletPoint("Transmit spam or malicious code (viruses, etc.)."),
                  _buildBulletPoint("Use automated systems (robots/spiders) to access the App."),
                ],
              ),

              // --- 5. IP ---
              _buildSectionCard(
                number: 5,
                title: "Intellectual Property",
                children: [
                  _buildDefinition("Our Rights:", "The App, including logos and design, are the exclusive property of Revive Eco Tech."),
                  _buildDefinition("Your Content:", "For content you submit, you grant us a license to use/display it in connection with the App."),
                ],
              ),

              // --- 6. Privacy ---
              _buildSectionCard(
                number: 6,
                title: "Privacy",
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey.shade800),
                      children: [
                        const TextSpan(text: "Your privacy is important to us. Our Privacy Policy explains how we collect and use your data. Please review it "),
                        TextSpan(
                          text: "here",
                          style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()));
                            },
                        ),
                        const TextSpan(text: "."),
                      ],
                    ),
                  ),
                ],
              ),

              // --- 7. Third Party ---
              _buildSectionCard(
                number: 7,
                title: "Third-Party Links",
                children: [
                  _buildParagraph("The App may contain links to third-party websites not controlled by us. We assume no responsibility for their content or practices. You access them at your own risk."),
                ],
              ),

              // --- 8. Disclaimer ---
              _buildSectionCard(
                number: 8,
                title: "Disclaimer of Warranties",
                children: [
                  _buildEmphasisParagraph(
                      "THE APP IS PROVIDED ON AN \"AS IS\" AND \"AS AVAILABLE\" BASIS WITHOUT ANY WARRANTIES OF ANY KIND. WE DO NOT GUARANTEE THAT THE APP WILL BE UNINTERRUPTED, SECURE, OR ERROR-FREE."
                  ),
                ],
              ),

              // --- 9. Liability ---
              _buildSectionCard(
                number: 9,
                title: "Limitation of Liability",
                children: [
                  _buildEmphasisParagraph(
                      "TO THE FULLEST EXTENT PERMITTED BY LAW, IN NO EVENT WILL REVIVE ECO TECH BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL OR PUNITIVE DAMAGES."
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}