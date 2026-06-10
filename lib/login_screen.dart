import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 💡 FIXED: Added missing import for Supabase types
import 'main.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _otpSent = false;

  // 1. Request a 6-Digit OTP from Supabase Cloud Auth
  Future<void> _sendOTP() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await supabase.auth.signInWithOtp(email: email);
      setState(() {
        _otpSent = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Secure token sent to your inbox.'),
          backgroundColor: Colors.deepPurpleAccent,
        ),
      );
    } catch (error) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // 2. Verify the typed OTP Token
  // 2. Verify the typed OTP Token
  Future<void> _verifyOTP() async {
    final email = _emailController.text.trim();
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length < 6) return;
    setState(() => _isLoading = true);

    try {
      // 💡 BULLETPROOF FIX: We access the Supabase auth API loop using a clean lower-camel-case enum parameter
      final response = await supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (response.session != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification Failed: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050507),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '7EVEN',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _otpSent
                    ? 'Enter verification matrix vector.'
                    : 'Initialize administrative link console.',
                style: const TextStyle(
                  color: Color(0xFF6C6C7A),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),

              if (!_otpSent) ...[
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF121216),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1C1C24)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Enter student email identity',
                      hintStyle: TextStyle(color: Color(0xFF4C4C5E)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _isLoading ? null : _sendOTP,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Request Access Token',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return Container(
                      width: 48,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF121216),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1C1C24)),
                      ),
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            FocusScope.of(
                              context,
                            ).requestFocus(_focusNodes[index + 1]);
                          } else if (value.isEmpty && index > 0) {
                            FocusScope.of(
                              context,
                            ).requestFocus(_focusNodes[index - 1]);
                          }
                          if (index == 5 && value.isNotEmpty) {
                            _verifyOTP();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _otpSent = false),
                    child: const Text(
                      'Change Email Identity',
                      style: TextStyle(
                        color: Color(0xFF6C6C7A),
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
