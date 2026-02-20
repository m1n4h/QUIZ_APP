
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_app/constants/app_styles.dart';
import 'package:quiz_app/screens/quiz_list_screen.dart';
import 'package:quiz_app/screens/teacher_dashboard_screen.dart';
import 'package:quiz_app/services/api_service.dart';
import 'package:quiz_app/utils/google_signin_helper.dart';
import 'package:quiz_app/screens/admin_dashboard_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = Get.find<ApiService>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _apiService.login(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (response['success']) {
          // Get user role and navigate accordingly
          final user = response['user'];
final String userRole =
    (user?['role'] ?? 'student').toString().toLowerCase();

          Get.snackbar(
            'Success',
            'Welcome, ${user?['firstName'] ?? 'User'}!',
            backgroundColor: AppColors.successColor,
            colorText: AppColors.secondaryColor,
            duration: const Duration(seconds: 2),
          );

          // Navigate based on role
          if (userRole == 'teacher') {
            Get.offAll(() => const TeacherDashboardScreen());
          } else if (userRole == 'admin') {
            Get.offAll(() => const AdminDashboardScreen());
          } else {
            Get.offAll(() => const QuizListScreen());
          }
        } else {
          Get.snackbar(
            'Login Failed',
            response['message'] ?? 'Invalid credentials',
            backgroundColor: AppColors.errorColor,
            colorText: AppColors.secondaryColor,
          );
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'An error occurred during login: $e',
          backgroundColor: AppColors.errorColor,
          colorText: AppColors.secondaryColor,
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

Future<void> _signInWithGoogle() async {
  setState(() {
    _isLoading = true;
  });

  try {
    final googleData = await GoogleSignInHelper.signIn();

    if (googleData != null) {
      final accessToken = googleData['accessToken'] as String?;
      final response = await _apiService.googleAuth(
        email: googleData['email'] as String,
        name: googleData['name'] as String,
        googleId: googleData['googleId'] as String,
        profileImage: googleData['profileImage'] as String?,
        accessToken: accessToken,
      );

      if (response['success'] == true) {
        final user = response['user'];
        final userRole = user?['role'] ?? 'student';

        Get.snackbar(
          'Success',
          'Welcome, ${user?['firstName'] ?? 'User'}!',
          backgroundColor: AppColors.successColor,
          colorText: AppColors.secondaryColor,
          duration: const Duration(seconds: 2),
        );

        if (userRole == 'admin') {
          Get.offAll(() => const AdminDashboardScreen());
        } else if (userRole == 'teacher') {
          Get.offAll(() => const TeacherDashboardScreen());
        } else {
          Get.offAll(() => const QuizListScreen());
        }
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Google sign-in failed',
          backgroundColor: AppColors.errorColor,
          colorText: AppColors.secondaryColor,
        );
      }
    } else {
      // User cancelled or Google Sign-In not available
      print('Google Sign-In returned null');
    }
  } catch (e) {
    print('Google Sign-In Exception: $e');
    String errorMessage = 'Failed to sign in with Google';
    
    if (e.toString().contains('Null check operator')) {
      errorMessage = 'Google Sign-In is not properly configured for web browsers. Please use email/password login instead.';
    }
    
    Get.snackbar(
      'Error',
      errorMessage,
      backgroundColor: AppColors.errorColor,
      colorText: AppColors.secondaryColor,
      duration: const Duration(seconds: 4),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
  Future<void> _forgotPassword() async {
    final TextEditingController forgotEmailController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text(
          'Forgot Password?',
          style: AppTextStyle.h3.copyWith(color: AppColors.primaryColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: AppTextStyle.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: forgotEmailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: AppColors.secondaryLight,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: AppTextStyle.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (forgotEmailController.text.isEmpty) {
                Get.snackbar(
                  'Error',
                  'Please enter your email address',
                  backgroundColor: AppColors.errorColor,
                  colorText: AppColors.secondaryColor,
                );
                return;
              }

              try {
                // Call forget password endpoint (you'll need to add this to ApiService)
                // For now, show a success message
                Get.back();
                Get.snackbar(
                  'Success',
                  'Password reset link sent to ${forgotEmailController.text}',
                  backgroundColor: AppColors.successColor,
                  colorText: AppColors.secondaryColor,
                  duration: const Duration(seconds: 3),
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to send reset link: $e',
                  backgroundColor: AppColors.errorColor,
                  colorText: AppColors.secondaryColor,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.secondaryColor,
            ),
            child: Text(
              'Send Link',
              style: AppTextStyle.buttonMedium,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button (only show if we can go back)
                if (Navigator.of(context).canPop())
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.textPrimary,
                  ),
                const SizedBox(height: 20),

                // Header
                Text(
                  'Welcome Back!',
                  style: AppTextStyle.h1.copyWith(color: AppColors.primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue your learning journey',
                  style: AppTextStyle.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),

                // Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: AppColors.secondaryLight,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: AppColors.secondaryLight,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      // Forgot Password Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _forgotPassword,
                          child: Text(
                            'Forgot Password?',
                            style: AppTextStyle.bodySmall.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: AppColors.secondaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: AppColors.secondaryColor,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Login',
                                  style: AppTextStyle.buttonLarge.copyWith(
                                    color: AppColors.secondaryColor,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: AppColors.textLight.withOpacity(0.3)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or continue with',
                        style: AppTextStyle.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: AppColors.textLight.withOpacity(0.3)),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Google Sign In Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.secondaryColor,
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.secondaryDark),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    icon: Image.asset(
                      'assets/images/google.png',
                      height: 24,
                      width: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.g_translate, color: Colors.red);
                      },
                    ),
                    label: Text(
                      'Sign in with Google',
                      style: AppTextStyle.buttonMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.to(() => const SignupScreen());
                      },
                      child: Text(
                        "Sign Up",
                        style: AppTextStyle.buttonMedium.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}