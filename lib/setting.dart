import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:revive_eco_tech_app/launch_page.dart';
import 'package:revive_eco_tech_app/profile.dart';
import 'privacy_policy_page.dart';
import 'terms_and_conditions_page.dart';
import 'about_us_page.dart';
import 'faq_page.dart';
import 'help_support_page.dart';
import 'package:easy_localization/easy_localization.dart';

// --- Constants ---
const kPrimaryColor = Color(0xFF013856);
const kAccentColor = Color(0xFFa7cd47);
const kCreamColor = Color(0xFFfcf3e2);
const kRedColor = Color(0xFFE53935);

class Settings_page extends StatefulWidget {
  const Settings_page({super.key});

  @override
  State<Settings_page> createState() => _SettingsState();
}

class _SettingsState extends State<Settings_page> {

  // ✅ Helper to check if user has a password provider
  bool _canChangePassword(User? user) {
    if (user == null) return false;
    // Check if 'password' is in the list of provider data
    return user.providerData.any((info) => info.providerId == 'password');
  }

  void _sendPasswordReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Password reset email sent! Check your inbox."),
          backgroundColor: kAccentColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error sending email. Try again later."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool showPasswordOption = _canChangePassword(user);

    // ✅ FIX 1: Set bottom: false so content extends behind the nav bar
    return SafeArea(
      top: false,
      bottom: false,
      child: SingleChildScrollView(
        // ✅ FIX 2: Added extra bottom padding (100.0) to clear the nav bar
        padding: const EdgeInsets.fromLTRB(20.0, 120.0, 20.0, 100.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section 1: Profile Preview ---
            if (user != null)
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                  final name = data['name'] ?? "User";
                  final email = data['email'] ?? user.email ?? "";

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const profile()),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 30),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryColor.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const CircleAvatar(
                              radius: 28,
                              backgroundColor: kAccentColor,
                              child: Icon(Icons.person, color: Colors.white, size: 30),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (email.isNotEmpty)
                                  Text(
                                    email,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // --- Section 2: Support ---
            _buildSectionHeader("Support"),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                title: "about_us".tr(),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AboutUsPage())),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.headset_mic_outlined,
               title: "help_support".tr(),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HelpSupportPage())),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.help_outline_rounded,
                title: "faqs".tr(),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FaqPage())),
              ),
            ]),

            const SizedBox(height: 24),

            // --- Section 3: Legal ---
            _buildSectionHeader("Legal"),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.lock_outline_rounded,
                title: "privacy_policy".tr(),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyPolicyPage())),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.description_outlined,
                title: "terms_conditions".tr(),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TermsAndConditionsPage())),
              ),
            ]),

            const SizedBox(height: 24),

            // --- Section 4: Account ---
            _buildSectionHeader("Account"),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [

                  // ✅ NEW: Change Password Tile (Conditional)
                  if (showPasswordOption) ...[
                    ListTile(
                      onTap: () async {
                        // Confirm before sending email
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: kCreamColor,
                            title: const Text("Change Password", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                            content: const Text("We will send a password reset link to your email address."),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text("Send Email", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold))
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && user?.email != null) {
                          _sendPasswordReset(user!.email!);
                        }
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.lock_reset_rounded, color: kPrimaryColor, size: 22),
                      ),
                      title: Text(
  'change_password'.tr(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: kPrimaryColor,
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
                    ),
                    _buildDivider(), // Divider between Change Password and Logout
                  ],

                  // Logout Tile
                  ListTile(
                    onTap: () async {
                      bool confirm = await _showLogoutDialog(context);
                      if (confirm) {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => LaunchPage()),
                                (route) => false,
                          );
                        }
                      }
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kRedColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.logout_rounded, color: kRedColor, size: 22),
                    ),
                   title: Text(
  'log_out'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kRedColor,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: kRedColor),
                  ),
                  _buildDivider(), // Divider between Logout and Delete Account

                  // ✅ NEW: Delete Account Tile
                  ListTile(
                    onTap: () => _handleAccountDeletion(context),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.delete_forever_rounded, color: Colors.red.shade900, size: 22),
                    ),
                    title: Text(
  'delete_account'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red.shade900,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.red.shade900),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kCreamColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: kPrimaryColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: kPrimaryColor,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[100],
      indent: 64,
    );
  }

  Future<bool> _showLogoutDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCreamColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Log Out", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to log out?", style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Log Out", style: TextStyle(color: kRedColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ??
        false;
  }

  // --- Account Deletion Logic ---
  Future<void> _handleAccountDeletion(BuildContext context) async {
    bool confirm = await _showDeleteDialog(context);
    if (!confirm) return;

    // Show a loading dialog that the user cannot dismiss
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: kRedColor)),
    );

    try {
      // Call the secure backend wipe
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('deleteUserAccount');
      await callable.call();

      // Wipe local auth cache and navigate out
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.pop(context); // Pop the loading circle
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LaunchPage()),
              (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account permanently deleted."), backgroundColor: Colors.black87),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Pop the loading circle
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Deletion failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<bool> _showDeleteDialog(BuildContext context) async {
    final TextEditingController confirmController = TextEditingController();

    return await showDialog(
      context: context,
      barrierDismissible: false, // Forces them to make a deliberate choice
      builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            // Check if they typed the exact word
            bool isButtonEnabled = confirmController.text.trim() == 'DELETE';

            return AlertDialog(
              backgroundColor: kCreamColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade900),
                  const SizedBox(width: 8),
                  Text("Delete Account", style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "This action is permanent and cannot be undone. All your personal data will be wiped.",
                    style: TextStyle(color: Colors.black87, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Type DELETE to confirm:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kPrimaryColor),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    onChanged: (value) {
                      // Triggers a rebuild of just the dialog to check the text
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: "DELETE",
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.red.shade900, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  // Button is completely dead unless isButtonEnabled is true
                  onPressed: isButtonEnabled ? () => Navigator.pop(context, true) : null,
                  child: const Text("Yes, Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
      ),
    ) ?? false;
  }

}


