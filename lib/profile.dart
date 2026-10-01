import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:revive_eco_tech_app/launch_page.dart';
// Internal Pages (Keep your existing imports)
import 'package:revive_eco_tech_app/refer_page.dart';
import 'package:revive_eco_tech_app/review_and_rate_page.dart';
import 'history.dart';
import 'manage_addresses.dart';
import 'package:easy_localization/easy_localization.dart';


// --- Constants ---
const kPrimaryColor = Color(0xFF013856);
const kAccentColor = Color(0xFFa7cd47);
const kCreamColor = Color(0xFFfcf3e2);
const kCreamLight = Color(0xFFfefaef);

class profile extends StatefulWidget {
  const profile({super.key});

  @override
  State<profile> createState() => _profileState();
}

class _profileState extends State<profile> {

  @override
  void initState() {
    super.initState();
    _syncVerifiedData();
  }

  // ✅ BACKGROUND SYNC: Safely checks if the user clicked the link while away
  Future<void> _syncVerifiedData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await user.reload(); // Force Firebase to check if the link was clicked
      final refreshedUser = FirebaseAuth.instance.currentUser!;

      // If Auth says it's verified, but Firestore doesn't have it yet, sync it safely!
      if (refreshedUser.email != null && refreshedUser.emailVerified) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(refreshedUser.uid).get();
        if (doc.data()?['email'] != refreshedUser.email) {
          // Pass it through your Cloud Function so your security rules accept it
          final callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('updateUserProfile');
          await callable.call({'email': refreshedUser.email});
        }
      }
    } catch (e) {
      // Fail silently, it's just a background check
    }
  }

  // --- Robust Reset Password Logic ---
  // Future<void> _resetPassword(String email) async {
  //   if (email.isEmpty) {
  //     _showSnackBar("No email linked to account.", isError: true);
  //     return;
  //   }
  //   try {
  //     await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  //     _showSnackBar("Password reset link sent! Check your email.");
  //   } catch (e) {
  //     _showSnackBar("Error: ${e.toString()}", isError: true);
  //   }
  // }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.red : kAccentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- Show Edit Sheet ---
  void _showEditSheet(BuildContext context, Map<String, dynamic> userData, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GranularEditSheet(
        userData: userData,
        user: user,
        onSuccess: (msg) {
          _showSnackBar(msg);
        },
      ),
    );
  }

  // --- UI Builders ---
  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kPrimaryColor)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMenuOption({required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: kCreamColor, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: kPrimaryColor, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: kPrimaryColor)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
      ),
    );
  }
Future<double> _fetchTotalEarnings() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return 0;

  final snapshot = await FirebaseFirestore.instance
      .collection('pickups')
      .where('userId', isEqualTo: user.uid)
      .get();

  double total = 0;

  for (var doc in snapshot.docs) {
    final data = doc.data();

    // Count only completed orders that are not declined
    if (data['status'] == 'Completed' &&
        data['declinedStatus'] != true) {
      total += (data['finalPrice'] as num?)?.toDouble() ?? 0;
    }
  }

  return total;
}
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Please log in.")));

    return Scaffold(
      backgroundColor: kCreamColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          // if (snapshot.connectionState == ConnectionState.waiting) {
          //   return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          // }
          // Only show the spinner if we have absolutely no cached data yet
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          }

          // ✅ 2. NEW: The Security Catch
          if (snapshot.hasError) {
            // Safely clear the dead session from the app's memory
            // WidgetsBinding.instance.addPostFrameCallback((_) {
            //   FirebaseAuth.instance.signOut();
            // });
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                // Show the toast right before navigating
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Session expired. Please log in again for security.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.orange.shade800, // Orange implies a security warning without being a scary red "error"
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
                // This forces the entire app to reset to the LaunchPage
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LaunchPage()),
                      (route) => false,
                );
              }
            });

            // Show a graceful security message instead of a blank screen
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security_rounded, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text("Session Expired", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                  const SizedBox(height: 8),
                  const Text("For your security, please log back in.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final displayName = data['name'] ?? "User";
          //final displayEmail = data['email'] ?? user.email ?? '';
          final displayPhone = data['phone'] ?? '';

          // ✅ FIX: STRICT UI LOGIC
          // Only show the email if it is explicitly verified, or already secured in Firestore.
          String displayEmail = data['email'] ?? '';
          if (displayEmail.isEmpty && user.email != null && user.emailVerified) {
            displayEmail = user.email!;
          }

          final double totalWeight =
(data['totalWeight']
    as num? ?? 0)
    .toDouble();
          // ✅ FIX: Profile Strength Logic Updated
          int filledFields = 0;
          bool isNameFilled = displayName.isNotEmpty && displayName != "User" && !displayName.startsWith("User-");

          if (isNameFilled) filledFields++;
          if (displayEmail.isNotEmpty) filledFields++;
          if (displayPhone.isNotEmpty) filledFields++;

          double progress = filledFields / 3.0;
          bool isComplete = progress >= 0.999;

          String formattedPhone = displayPhone.startsWith('+') ? displayPhone : "+91 $displayPhone";

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- App Bar ---
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: kPrimaryColor,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kCreamColor),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text('Profile', style: TextStyle(fontFamily: 'RedHatDisplay', fontWeight: FontWeight.bold, fontSize: 20, color: kCreamColor)),
                centerTitle: true,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
                flexibleSpace: FlexibleSpaceBar(
                  background: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [kPrimaryColor, Color(0xFF025075)]),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                  child: const CircleAvatar(
                                    radius: 55,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(radius: 51, backgroundColor: kAccentColor, child: Icon(Icons.person, size: 65, color: Colors.white)),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _showEditSheet(context, data, user),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: const Icon(Icons.edit, size: 22, color: kPrimaryColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(displayName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 10),
                            if (displayPhone.isNotEmpty)
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.phone_rounded, color: kAccentColor.withOpacity(0.9), size: 16),
                                const SizedBox(width: 8),
                                Text(formattedPhone, style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500)),
                              ]),
                            if (displayEmail.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.email_rounded, color: kAccentColor.withOpacity(0.9), size: 16),
                                const SizedBox(width: 8),
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                                  child: Text(displayEmail, style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 1),
                                ),
                                
                              ]),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // --- Stats & Menu ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))]),
                        child: Row(
                         children: [

  _buildStatItem(

    Icons.recycling,

    "${totalWeight.toStringAsFixed(1)} kg",

    "recycled".tr(),

    Colors.green,
  ),

  Container(
    height: 40,
    width: 1,
    color: Colors.grey[200],
  ),

  FutureBuilder<double>(

    future: _fetchTotalEarnings(),

    builder: (context, snapshot) {

      final earnings =
          snapshot.data ?? 0;

      return _buildStatItem(

        Icons.currency_rupee,

        "₹${earnings.toStringAsFixed(0)}",

        "earned".tr(),

        Colors.orange,
      );
    },
  ),
],                        ),
                      ),

                      // Profile Strength & Achievement Badge
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        child: isComplete
                            ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: kAccentColor.withOpacity(0.5), width: 2),
                              boxShadow: [BoxShadow(color: kAccentColor.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(backgroundColor: kAccentColor, radius: 16, child: Icon(Icons.check, color: Colors.white, size: 20)),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Profile 100% Complete", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text("All details verified.", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        )
                            : Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(gradient: const LinearGradient(colors: [kPrimaryColor, Color(0xFF025075)]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]),
                          child: Column(
                            children: [
                              Row(children: [
                                const Icon(Icons.verified_user_outlined, color: kAccentColor, size: 20),
                                const SizedBox(width: 8),
                                const Text("Profile Strength", style: TextStyle(color: kAccentColor, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text("${(progress * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ]),
                              const SizedBox(height: 10),
                              ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white24, color: kAccentColor, minHeight: 6)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(displayPhone.isEmpty && displayEmail.isEmpty ? "Add Phone & Email" : displayPhone.isEmpty ? "Add Phone Number" : "Add Email Address", style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  SizedBox(height: 32, child: ElevatedButton(onPressed: () => _showEditSheet(context, data, user), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kPrimaryColor, padding: const EdgeInsets.symmetric(horizontal: 16)), child: const Text("Complete Now", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),

                      // Menu Options
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                           _buildMenuOption(

  icon: Icons.location_on_outlined,

  title: "manage_addresses".tr(),

  onTap: () => Navigator.push(

    context,

    MaterialPageRoute(
      builder: (_) =>
          const ManageAddressesPage(),
    ),
  ),
),
                           _buildMenuOption(

  icon: Icons.history,

  title: "history".tr(),

  onTap: () => Navigator.push(

    context,

    MaterialPageRoute(
      builder: (_) => HistoryScreen(),
    ),
  ),
),
                           _buildMenuOption(

  icon: Icons.star_outline_rounded,

  title: "review_rate".tr(),

  onTap: () => Navigator.push(

    context,

    MaterialPageRoute(
      builder: (_) =>
          ReviewAndRatePage(),
    ),
  ),
),
                            // Builder(builder: (context) {
                            //   bool hasPassword = user.providerData.any((info) => info.providerId == 'password');
                            //   if (hasPassword) return _buildMenuOption(icon: Icons.lock_reset_outlined, title: "Reset Password", onTap: () => _resetPassword(displayEmail));
                            //   return const SizedBox.shrink();
                            // }),
                            _buildMenuOption(

  icon: Icons.language,

  title: "language".tr(),

  onTap: () {

    showModalBottomSheet(

      context: context,

      builder: (context) {

        return Container(

          padding:
              const EdgeInsets.all(20),

          child: Column(

            mainAxisSize:
                MainAxisSize.min,

            children: [

              const Text(

                "Choose Language",

                style: TextStyle(

                  fontSize: 20,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              ListTile(

                leading:
                    const Icon(Icons.language),

                title:
                    const Text("English"),

                onTap: () {

                  context.setLocale(
                    const Locale('en'),
                  );

                  Navigator.pop(context);
                },
              ),

              ListTile(

                leading:
                    const Icon(Icons.language),

                title:
                    const Text("Hindi"),

                onTap: () {

                  context.setLocale(
                    const Locale('hi'),
                  );

                  Navigator.pop(context);
                },
              ),

              ListTile(

                leading:
                    const Icon(Icons.language),

                title:
                    const Text("Telugu"),

                onTap: () {

                  context.setLocale(
                    const Locale('te'),
                  );

                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  },
),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMPROVED EDIT SHEET: Handles State, Keyboard, and Region Correctly
// ─────────────────────────────────────────────────────────────────────────────

class _GranularEditSheet extends StatefulWidget {
  final Map<String, dynamic> userData;
  final User user;
  final Function(String)? onSuccess;

  const _GranularEditSheet({required this.userData, required this.user, this.onSuccess});

  @override
  State<_GranularEditSheet> createState() => _GranularEditSheetState();
}

class _GranularEditSheetState extends State<_GranularEditSheet> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;

  // ✅ Added Password Controllers for Upgrade Flow
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  final FocusNode nameNode = FocusNode();
  final FocusNode phoneNode = FocusNode();
  final FocusNode emailNode = FocusNode();

  bool isNameLoading = false;
  bool isPhoneLoading = false;
  bool isEmailLoading = false;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  late String originalName;
  late String originalPhone;
  late String originalEmail;

  final phoneRegex = RegExp(r'^[0-9]{10}$');
  final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

  String? phoneError;
  String? emailError;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.userData['name'] ?? '');
    phoneController = TextEditingController(text: widget.userData['phone'] ?? '');
    emailController = TextEditingController(text: widget.userData['email'] ?? '');

    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();

    // LISTENERS: Essential for button state updates
    nameController.addListener(() => setState(() {}));
    phoneController.addListener(() => setState(() {}));
    emailController.addListener(() => setState(() {}));
    passwordController.addListener(() => setState(() {}));
    confirmPasswordController.addListener(() => setState(() {}));

    originalName = nameController.text;
    originalPhone = phoneController.text;
    originalEmail = emailController.text;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameNode.dispose();
    phoneNode.dispose();
    emailNode.dispose();
    super.dispose();
  }

  void _validatePhone(String val) {
    setState(() {
      if (val.isEmpty) phoneError = null;
      else if (!phoneRegex.hasMatch(val.trim())) phoneError = "Enter 10 digits";
      else phoneError = null;
    });
  }

  void _validateEmail(String val) {
    setState(() {
      if (val.isEmpty) emailError = null;
      else if (!emailRegex.hasMatch(val.trim())) emailError = "Invalid email";
      else emailError = null;
    });
  }

  // ✅ FIX: "Top-Toast" prevents messages from hiding behind the bottom sheet
  void _showToast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: isError ? Colors.red : kAccentColor,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * 0.8, // Drops from top of screen
        left: 20,
        right: 20,
      ),
      dismissDirection: DismissDirection.up,
    ));
  }

  // --- UPDATE NAME ---
  Future<void> _updateName() async {
    final newName = nameController.text.trim();
    if (newName.isEmpty || newName == originalName) return;

    setState(() => isNameLoading = true);
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('updateUserProfile');
      await callable.call({'name': newName});

      if (mounted) {
        setState(() { originalName = newName; isNameLoading = false; });
        FocusScope.of(context).unfocus();
        Navigator.pop(context);
        widget.onSuccess?.call("Name updated successfully!");
      }
    } catch (e) {
      if (mounted) setState(() => isNameLoading = false);
      _showToast("Update Failed: ${e.toString()}", isError: true);
    }
  }

  // --- UPDATE PHONE ---
  Future<void> _verifyAndUpdatePhone() async {
    final newPhone = phoneController.text.trim();
    if (phoneError != null || newPhone.isEmpty || isPhoneLoading) return;

    setState(() => isPhoneLoading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "+91$newPhone",
        verificationCompleted: (credential) async {
          await widget.user.updatePhoneNumber(credential);
          await _updateCloudProfile(phone: newPhone);
          if (mounted) setState(() => isPhoneLoading = false);
        },
        verificationFailed: (e) {
          if (mounted) setState(() => isPhoneLoading = false);
          _showToast("Verification Failed: ${e.message}", isError: true);
        },
        codeSent: (verificationId, _) {
          if (mounted) setState(() => isPhoneLoading = false);
          _showOtpDialog(verificationId, newPhone);
        },
        codeAutoRetrievalTimeout: (_) { if (mounted) setState(() => isPhoneLoading = false); },
      );
    } catch (e) {
      if (mounted) setState(() => isPhoneLoading = false);
      _showToast(e.toString(), isError: true);
    }
  }

  void _showOtpDialog(String verificationId, String newPhone) {
    TextEditingController otpController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Verify Phone"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter code sent to +91 $newPhone", textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(fontSize: 20, letterSpacing: 4, fontWeight: FontWeight.bold),
                decoration: InputDecoration(counterText: "", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              ),
              if (isVerifying) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator(color: kAccentColor))
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kAccentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: isVerifying ? null : () async {
                setDialogState(() => isVerifying = true);
                try {
                  PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: otpController.text.trim());
                  await widget.user.updatePhoneNumber(credential);
                  await _updateCloudProfile(phone: newPhone);
                  if (context.mounted) {
                    Navigator.pop(context);
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);
                    widget.onSuccess?.call("Phone Verified & Updated!");
                  }
                } on FirebaseAuthException catch (e) {
                  setDialogState(() => isVerifying = false);
                  if (e.code == 'credential-already-in-use') {
                    _showToast("Number already in use by another account.", isError: true);
                  } else {
                    _showToast("Error: ${e.message}", isError: true);
                  }
                } catch (e) {
                  setDialogState(() => isVerifying = false);
                  _showToast("Error: ${e.toString()}", isError: true);
                }
              },
              child: const Text("Verify"),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIX: Upgrade Email with Password Logic
  Future<void> _verifyAndUpdateEmail() async {
    final newEmail = emailController.text.trim();
    if (emailError != null || newEmail.isEmpty || isEmailLoading) return;

    setState(() => isEmailLoading = true);
    try {
      bool hasPasswordProvider = widget.user.providerData.any((info) => info.providerId == 'password');

      if (!hasPasswordProvider) {
        // Upgrade flow: Create credential and link it
        final password = passwordController.text;
        AuthCredential credential = EmailAuthProvider.credential(
          email: newEmail,
          password: password,
        );

        await widget.user.linkWithCredential(credential);
        await widget.user.sendEmailVerification();
        //await _updateCloudProfile(email: newEmail);

        if (mounted) {
          setState(() {
            originalEmail = newEmail;
            isEmailLoading = false;
            passwordController.clear();
            confirmPasswordController.clear();
          });
          FocusScope.of(context).unfocus();
          Navigator.pop(context); // Pop sheet so the success toast is fully visible on main screen
          widget.onSuccess?.call("Account upgraded! Verification email sent.");
        }
      } else {
        // Standard flow: User already has a password
        await widget.user.verifyBeforeUpdateEmail(newEmail);
        //await _updateCloudProfile(email: newEmail);

        if (mounted) {
          setState(() { originalEmail = newEmail; isEmailLoading = false; });
          FocusScope.of(context).unfocus();
          Navigator.pop(context);
          widget.onSuccess?.call("Verification email sent! Link expires in 1 hour.");
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => isEmailLoading = false);
      if (e.code == 'requires-recent-login') {
        _showToast("Please log out and log back in to verify a new email.", isError: true);
      } else {
        _showToast("Error: ${e.message}", isError: true);
      }
    } catch (e) {
      if (mounted) setState(() => isEmailLoading = false);
      _showToast("Error: ${e.toString()}", isError: true);
    }
  }

  // --- CLOUD SYNC ---
  Future<void> _updateCloudProfile({String? phone, String? email}) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('updateUserProfile');
      final Map<String, dynamic> payload = {};
      if (phone != null) payload['phone'] = phone;
      if (email != null) payload['email'] = email;
      await callable.call(payload);
    } catch (e) {
      _showToast("Cloud sync failed. Profile might update late.", isError: true);
    }
  }

  // --- PASSWORD VALIDATORS ---
  bool _isPasswordValid(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  Widget _buildPasswordRequirements(String password) {
    bool hasMinLength = password.length >= 8;
    bool hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    bool hasNumber = RegExp(r'[0-9]').hasMatch(password);
    bool hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    Widget makeRow(String text, bool met) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Row(
          children: [
            Icon(met ? Icons.check_circle : Icons.circle_outlined, size: 16, color: met ? Colors.green : Colors.grey),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(fontSize: 12, color: met ? Colors.green[800] : Colors.grey[600]))
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          makeRow("At least 8 characters", hasMinLength),
          makeRow("At least one Uppercase letter (A-Z)", hasUppercase),
          makeRow("At least one Number (0-9)", hasNumber),
          makeRow("At least one Special Character (!@#...)", hasSpecial),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isGoogle = widget.user.providerData.any((info) => info.providerId == 'google.com');
    bool hasPasswordProvider = widget.user.providerData.any((info) => info.providerId == 'password');

    return Container(
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24
      ),
      decoration: const BoxDecoration(
          color: kCreamLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: kPrimaryColor)),
                IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context))
              ],
            ),
            const SizedBox(height: 24),

            _buildGranularField(
                label: "Full Name",
                controller: nameController,
                node: nameNode,
                icon: Icons.person_outline,
                isLoading: isNameLoading,
                isChanged: nameController.text.trim() != originalName,
                btnText: "Save",
                onAction: _updateName
            ),

            _buildGranularField(
                label: "Phone Number",
                controller: phoneController,
                node: phoneNode,
                icon: Icons.phone_outlined,
                isLoading: isPhoneLoading,
                isChanged: phoneController.text.trim() != originalPhone,
                btnText: "Verify",
                onAction: _verifyAndUpdatePhone,
                inputType: TextInputType.phone,
                errorText: phoneError,
                onChanged: _validatePhone
            ),

            // ✅ RENDER UPGRADE UI OR STANDARD EMAIL UI
            if (!hasPasswordProvider && !isGoogle)
              _buildEmailUpgradeSection()
            else
              _buildGranularField(
                  label: "Email Address",
                  controller: emailController,
                  node: emailNode,
                  icon: Icons.email_outlined,
                  isLoading: isEmailLoading,
                  isChanged: emailController.text.trim() != originalEmail,
                  btnText: "Verify",
                  onAction: _verifyAndUpdateEmail,
                  isLocked: isGoogle,
                  helperText: isGoogle ? "Managed by Google Account" : "Link expires in 1 hour",
                  errorText: emailError,
                  onChanged: _validateEmail,
                  inputType: TextInputType.emailAddress
              ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW SECTION: Custom UI block specifically for Phone-to-Email Account Upgrade
  Widget _buildEmailUpgradeSection() {
    bool isPassValid = _isPasswordValid(passwordController.text);
    bool isMatch = passwordController.text.isNotEmpty && passwordController.text == confirmPasswordController.text;
    bool isEmailValid = emailController.text.isNotEmpty && emailError == null;
    bool isChanged = emailController.text.trim() != originalEmail;

    bool isButtonDisabled = isEmailLoading || !isEmailValid || !isPassValid || !isMatch || !isChanged;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Link Email Address", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kPrimaryColor)),
          const SizedBox(height: 6),
          const Text("Since you signed in with a phone number, create a password so you can securely log in with this email.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),

          // Email Input
          TextField(
            controller: emailController,
            focusNode: emailNode,
            keyboardType: TextInputType.emailAddress,
            onChanged: _validateEmail,
            style: const TextStyle(fontWeight: FontWeight.w600, color: kPrimaryColor),
            decoration: InputDecoration(
              hintText: "Enter Email",
              prefixIcon: const Icon(Icons.email_outlined, color: kPrimaryColor),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: emailError != null ? Colors.red.shade300 : Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: emailError != null ? Colors.red : kPrimaryColor, width: 2)),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
          ),
          if (emailError != null) Padding(padding: const EdgeInsets.only(top: 6, left: 4), child: Text(emailError!, style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w500))),

          const SizedBox(height: 16),

          // Password Input
          TextField(
            controller: passwordController,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(fontWeight: FontWeight.w600, color: kPrimaryColor),
            decoration: InputDecoration(
              hintText: "Create Password",
              prefixIcon: const Icon(Icons.lock_outline, color: kPrimaryColor),
              suffixIcon: IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: kAccentColor),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimaryColor, width: 2)),
            ),
          ),
          if (passwordController.text.isNotEmpty) _buildPasswordRequirements(passwordController.text),

          const SizedBox(height: 12),

          // Confirm Password Input
          TextField(
            controller: confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            style: const TextStyle(fontWeight: FontWeight.w600, color: kPrimaryColor),
            decoration: InputDecoration(
              hintText: "Confirm Password",
              prefixIcon: const Icon(Icons.lock_outline, color: kPrimaryColor),
              suffixIcon: IconButton(
                icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: kAccentColor),
                onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              ),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimaryColor, width: 2)),
            ),
          ),
          if (confirmPasswordController.text.isNotEmpty && confirmPasswordController.text != passwordController.text)
            Padding(padding: const EdgeInsets.only(top: 6, left: 4), child: Text("Passwords do not match", style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w500))),

          const SizedBox(height: 20),

          // Verify Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isButtonDisabled ? null : _verifyAndUpdateEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentColor,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isEmailLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text("Link & Verify Email", style: TextStyle(color: isButtonDisabled ? Colors.grey.shade600 : kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGranularField({
    required String label,
    required TextEditingController controller,
    required FocusNode node,
    required IconData icon,
    required VoidCallback onAction,
    required bool isChanged,
    required bool isLoading,
    required String btnText,
    String? errorText,
    bool isLocked = false,
    TextInputType inputType = TextInputType.text,
    String? helperText,
    Function(String)? onChanged,
  }) {
    bool isButtonDisabled = isLoading || errorText != null || !isChanged || isLocked;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kPrimaryColor)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: node,
                  readOnly: isLocked,
                  keyboardType: inputType,
                  onChanged: (val) {
                    if (onChanged != null) onChanged(val);
                  },
                  style: const TextStyle(fontWeight: FontWeight.w600, color: kPrimaryColor),
                  decoration: InputDecoration(
                    prefixIcon: Icon(icon, color: isLocked ? Colors.grey : kPrimaryColor),
                    filled: true,
                    fillColor: isLocked ? Colors.grey.shade100 : Colors.white,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: errorText != null ? Colors.red.shade300 : Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: errorText != null ? Colors.red : kPrimaryColor, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                ),
              ),
              if (!isLocked) ...[
                const SizedBox(width: 12),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isButtonDisabled ? null : onAction,
                    style: ElevatedButton.styleFrom(backgroundColor: kAccentColor, disabledBackgroundColor: Colors.grey.shade300, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16)),
                    child: isLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : Text(btnText, style: TextStyle(color: isButtonDisabled ? Colors.grey.shade600 : kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                )
              ]
            ],
          ),
          if (errorText != null) Padding(padding: const EdgeInsets.only(top: 6, left: 4), child: Text(errorText, style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w500))),
          if (helperText != null && errorText == null) Padding(padding: const EdgeInsets.only(top: 6, left: 4), child: Row(children: [Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600), const SizedBox(width: 6), Text(helperText, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))])),
        ],
      ),
    );
  }
}