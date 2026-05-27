import 'package:flutter/material.dart';
import 'package:revive_eco_tech_app/home.dart';
import 'package:revive_eco_tech_app/emailverification.dart';
import 'package:revive_eco_tech_app/otp_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:revive_eco_tech_app/auth/google_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart'; // ✅ ADDED: Required for Cloud Functions
import 'package:revive_eco_tech_app/forgot_password_page.dart';

class Login extends StatefulWidget {
  final int initialTabIndex;
  const Login({Key? key, this.initialTabIndex = 0}) : super(key: key);
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  bool _isLoginPasswordVisible = false;
  bool _isSignupPasswordVisible = false;
  bool _isSignupConfirmPasswordVisible = false;

  final firebaseServices = FirebaseServices();

  bool _isPhoneAuth = false;
  bool _isLoading = false;

  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _signupPasswordController = TextEditingController();
  final TextEditingController _signupConfirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  late TabController _tabController;

  // Constants
  static const Color kPrimaryColor = Color(0xFF013D5A);
  static const Color kAccentColor = Color(0xFFA6CB4E);
  static const Color kCreamColor = Color(0xFFFCF3E3);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTabIndex);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void showErrorToUser(BuildContext context, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ✅ ADDED: Helper function to assign the customer role and refresh the Auth token
  Future<void> _assignCustomerRole() async {
    try {
      final httpsCallable = FirebaseFunctions.instance.httpsCallable('assignUserRole');

      // Call the Cloud Function
      await httpsCallable.call({'role': 'customer'});

      // CRITICAL: Force refresh the token so custom claims take effect immediately
      await FirebaseAuth.instance.currentUser?.getIdToken(true);

      debugPrint('✅ Customer role assigned successfully and token refreshed.');
    } catch (e) {
      debugPrint('❌ Error assigning role: $e');
    }
  }

  Future<void> createUserProfile(User user) async {
    final userDocRef =
    FirebaseFirestore.instance.collection('users').doc(user.uid);
    final docSnap = await userDocRef.get();

    if (!docSnap.exists) {
      await userDocRef.set({
        'name': user.displayName ?? 'User-${user.uid.substring(0, 6)}',
        'phone': user.phoneNumber ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'email': user.email,
      });

      // ✅ ADDED: Trigger the role assignment right after initial profile creation
      await _assignCustomerRole();
    }
  }

  Future<void> _sendOtp() async {
    final formKey = _tabController.index == 0 ? _loginFormKey : _signupFormKey;

    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    final phoneNumber = "+91${_phoneController.text.trim()}";

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          showErrorToUser(context, "Verification completed automatically.");
        },
        verificationFailed: (FirebaseAuthException e) {
          showErrorToUser(context, "Failed to send OTP: ${e.message}");
          setState(() => _isLoading = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtpPage(verificationId: verificationId),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      showErrorToUser(context, "An error occurred: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- WIDGETS ---

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Row(
        children: [
          Expanded(child: Divider(color: kPrimaryColor.withOpacity(0.3))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text("OR",
                style: TextStyle(
                    color: kPrimaryColor.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Divider(color: kPrimaryColor.withOpacity(0.3))),
        ],
      ),
    );
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
            Icon(
              met ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: met ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: met ? Colors.green[800] : Colors.grey[600],
              ),
            )
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(35, 5, 30, 10),
      child: Column(
        children: [
          makeRow("At least 8 characters", hasMinLength),
          makeRow("At least one Uppercase letter (A-Z)", hasUppercase),
          makeRow("At least one Number (0-9)", hasNumber),
          makeRow("At least one Special Character (!@#...)", hasSpecial),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefixWidget,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
      decoration: BoxDecoration(
        color: kCreamColor,
        border: Border.all(color: kPrimaryColor, width: 2.0),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(
            color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'RedHatDisplay',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kPrimaryColor.withOpacity(0.5),
          ),
          prefixIcon: prefixWidget ?? Icon(icon, size: 24, color: kAccentColor),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kCreamColor,
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              // ✅ 1. Curvy Header Image
              Container(
                height: 280,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
                  ],
                  image: DecorationImage(
                    image: AssetImage('assets/images/HOME_SCREEN_6[1].png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ 2. Floating Curvy Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: kPrimaryColor.withOpacity(0.1), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Login'),
                      Tab(text: 'Signup'),
                    ],
                    indicator: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: kCreamColor,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'RedHatDisplay',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // 3. Form Content
              _tabController.index == 0 ? _buildLoginForm() : _buildSignupForm(),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Login Form ----
  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 30, bottom: 10),
            child: Text(
              'Login to your account',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'RedHatDisplay',
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
          ),
          if (_isPhoneAuth)
            _buildPhoneInput()
          else ...[
            _buildTextField(
              controller: _loginEmailController,
              hint: 'E-mail',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (_isPhoneAuth) return null;
                if (value == null || value.isEmpty) return 'Please enter email';
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) return 'Invalid email address';
                return null;
              },
            ),
            _buildTextField(
              controller: _loginPasswordController,
              hint: 'Password',
              icon: Icons.lock_rounded,
              obscureText: !_isLoginPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isLoginPasswordVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: kAccentColor,
                ),
                onPressed: () => setState(
                        () => _isLoginPasswordVisible = !_isLoginPasswordVisible),
              ),
              validator: (value) {
                if (_isPhoneAuth) return null;
                if (value == null || value.isEmpty) return 'Enter password';
                return null;
              },
            ),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_isPhoneAuth)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ForgotPasswordPage()),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  const SizedBox(),
                TextButton(
                  onPressed: () {
                    _loginEmailController.clear();
                    _loginPasswordController.clear();
                    _phoneController.clear();
                    setState(() => _isPhoneAuth = !_isPhoneAuth);
                  },
                  child: Text(
                    _isPhoneAuth ? 'Use Email' : 'Use Phone',
                    style: const TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildActionButton(isLogin: true),
          _buildDivider(),
          _buildGoogleButton(isLogin: true),
        ],
      ),
    );
  }

  // ---- Signup Form ----
  Widget _buildSignupForm() {
    return Form(
      key: _signupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 30, bottom: 10),
            child: Text(
              'Join our community',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'RedHatDisplay',
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
          ),
          if (_isPhoneAuth)
            _buildPhoneInput()
          else ...[
            _buildTextField(
              controller: _signupEmailController,
              hint: 'E-mail',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (_isPhoneAuth) return null;
                if (value == null || value.isEmpty) return 'Please enter email';
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) return 'Invalid email address';
                return null;
              },
            ),
            _buildTextField(
              controller: _signupPasswordController,
              hint: 'Password',
              icon: Icons.lock_rounded,
              obscureText: !_isSignupPasswordVisible,
              onChanged: (val) => setState(() {}),
              suffixIcon: IconButton(
                icon: Icon(
                  _isSignupPasswordVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: kAccentColor,
                ),
                onPressed: () => setState(
                        () => _isSignupPasswordVisible = !_isSignupPasswordVisible),
              ),
              validator: (value) {
                if (_isPhoneAuth) return null;
                if (value == null || value.length < 8) {
                  return 'Must be at least 8 chars';
                }
                return null;
              },
            ),
            if (_signupPasswordController.text.isNotEmpty)
              _buildPasswordRequirements(_signupPasswordController.text),
            _buildTextField(
              controller: _signupConfirmPasswordController,
              hint: 'Confirm Password',
              icon: Icons.lock_rounded,
              obscureText: !_isSignupConfirmPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isSignupConfirmPasswordVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: kAccentColor,
                ),
                onPressed: () => setState(() =>
                _isSignupConfirmPasswordVisible =
                !_isSignupConfirmPasswordVisible),
              ),
              validator: (value) {
                if (_isPhoneAuth) return null;
                if (value != _signupPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],

          Padding(
            padding: const EdgeInsets.only(right: 30, top: 5),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _signupEmailController.clear();
                  _signupPasswordController.clear();
                  _phoneController.clear();
                  setState(() => _isPhoneAuth = !_isPhoneAuth);
                },
                child: Text(
                  _isPhoneAuth ? 'Use Email instead' : 'Use Phone instead',
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          _buildActionButton(isLogin: false),
          _buildDivider(),
          _buildGoogleButton(isLogin: false),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return _buildTextField(
      controller: _phoneController,
      hint: '10-digit number',
      icon: Icons.phone_rounded,
      keyboardType: TextInputType.phone,
      prefixWidget: const Padding(
        padding: EdgeInsets.all(14.0),
        child: Text(
          '+91',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor),
        ),
      ),
      validator: (value) {
        if (_isPhoneAuth) {
          if (value == null || value.isEmpty) return 'Enter phone number';
          if (value.length != 10) return 'Enter valid 10-digit number';
        }
        return null;
      },
    );
  }

  // ✅ CEVUS FIX 1: Vibrant Gradient Button
  Widget _buildActionButton({required bool isLogin}) {
    String buttonText;
    VoidCallback onPressed;

    if (_isPhoneAuth) {
      buttonText = 'Send OTP';
      onPressed = _sendOtp;
    } else {
      buttonText = isLogin ? 'Login with Email' : 'Signup with Email';
      onPressed = isLogin ? _handleEmailLogin : _handleEmailSignup;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), // Rounded corners
          // ✅ Gradient for Vibrancy
          gradient: const LinearGradient(
            colors: [kAccentColor, Color(0xFFC0E862)], // Lime to Bright Lime
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          // ✅ Glow Shadow
          boxShadow: [
            BoxShadow(
              color: kAccentColor.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, // Transparent to show gradient
            shadowColor: Colors.transparent, // No default shadow
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading
              ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 3)
          )
              : Text(
            buttonText,
            style: const TextStyle(
              fontFamily: 'RedHatDisplay',
              fontWeight: FontWeight.bold,
              color: kPrimaryColor, // Dark text on bright background
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton({required bool isLogin}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 20),
      child: SizedBox(
        height: 60,
        child: ElevatedButton(
          onPressed: () async {
            final userCredential = await firebaseServices.signInWithGoogle();
            if (userCredential != null && userCredential.user != null) {
              await createUserProfile(userCredential.user!);
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.grey[200],
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/google_logo.png', height: 45),
              const SizedBox(width: 12),
              Text(
                // ✅ Uses the parameter 'isLogin'
                isLogin ? 'Continue with Google' : 'Sign up with Google',
                style: const TextStyle(
                  fontFamily: 'RedHatDisplay',
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleEmailLogin() async {
    if (_loginFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userCredential = await firebaseServices.loginWithEmail(
          _loginEmailController.text.trim(),
          _loginPasswordController.text.trim(),
        );
        if (userCredential != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } catch (e) {
        showErrorToUser(context, e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleEmailSignup() async {
    if (_signupFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final error = await firebaseServices.signUpWithEmail(
          _signupEmailController.text.trim(),
          _signupPasswordController.text.trim(),
        );
        if (!mounted) return;
        if (error == null) {
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null) await createUserProfile(user);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (ctx) => EmailVerificationPage()),
          );
        } else {
          showErrorToUser(context, error);
        }
      } catch (e) {
        showErrorToUser(context, "Signup failed: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}