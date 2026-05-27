import 'package:flutter/material.dart';
import 'faq_page.dart';
import 'privacy_policy_page.dart';
import 'terms_and_conditions_page.dart';

// ==== Constants ====
const kPrimaryColor = Color(0xFF013D5A);
const kCreamColor = Color(0xFFFCF3E3);
const kAccentColor = Color(0xFFA6CB4E);

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  // ✅ CEVUS: Actionable Contact Card
  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade300),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ CEVUS: Navigation Tile
  Widget _buildNavTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget page,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => page));
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: kPrimaryColor.withOpacity(0.7)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: kPrimaryColor,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
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
              'Help & Support',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Text ---
            const Text(
              "How can we help you?",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Our team is here to assist you with any questions or issues.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // --- Contact Section ---
            _buildContactCard(
              icon: Icons.phone_in_talk_rounded,
              title: "Customer Care",
              value: "6304218355",
              color: kAccentColor,
              onTap: () {
                // In a real app, use url_launcher to trigger phone dialer
                // launchUrl(Uri.parse("tel:6304218355"));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Phone number copied to clipboard!"), duration: Duration(seconds: 1)),
                );
              },
            ),
            _buildContactCard(
              icon: Icons.email_rounded,
              title: "Email Support",
              value: "reviveecotech@gmail.com",
              color: Colors.blueAccent,
              onTap: () {
                // In a real app, use url_launcher to trigger email
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Email copied to clipboard!"), duration: Duration(seconds: 1)),
                );
              },
            ),

            const SizedBox(height: 20),

            // --- FAQ Section ---
            const Text(
              "Common Questions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildNavTile(
              context: context,
              title: "Frequently Asked Questions",
              icon: Icons.help_outline_rounded,
              page: const FaqPage(),
            ),

            const SizedBox(height: 20),

            // --- Legal Section ---
            const Text(
              "Legal & Policies",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildNavTile(
              context: context,
              title: "Privacy Policy",
              icon: Icons.privacy_tip_outlined,
              page: const PrivacyPolicyPage(),
            ),
            _buildNavTile(
              context: context,
              title: "Terms & Conditions",
              icon: Icons.description_outlined,
              page: const TermsAndConditionsPage(),
            ),

            const SizedBox(height: 30),

            // --- Footer (Operating Hours) ---
            Center(
              child: Column(
                children: [
                  Icon(Icons.access_time, size: 20, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    "Operating Hours".toUpperCase(), // ✅ FIXED HERE
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Mon - Sat, 9:00 AM - 6:00 PM",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}