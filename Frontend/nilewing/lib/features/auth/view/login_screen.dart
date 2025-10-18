import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nilewing/core/theme/app_colors.dart';
import '../viewmodel/login_view_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSwitchToRegister;
  final VoidCallback? onSwitchToPostFlight;
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    Key? key,
    this.onSwitchToRegister,
    this.onSwitchToPostFlight,
    this.onLoginSuccess,
  }) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(loginViewModelProvider);

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Nile Wing Branding Header
              _buildHeader(),
              const SizedBox(height: 24),

              // Login Form Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Card Header with Gradient
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primary],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Access your Nile Wing account',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Form Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildLoginForm(viewModel),
                    ),
                  ],
                ),
              ),

              // Footer
              const SizedBox(height: 24),
              Text(
                '© 2025 Nile Wing Airlines. All rights reserved.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo and Title
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.airplanemode_active,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NILE WING',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  'AVIATION EXCELLENCE',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Welcome Text
        Column(
          children: [
            Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Login to continue your journey',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginForm(LoginViewModel viewModel) {
    return Form(
      child: Column(
        children: [
          // Email Field
          _buildEmailField(viewModel),
          const SizedBox(height: 20),

          // Password Field
          _buildPasswordField(viewModel),
          const SizedBox(height: 16),

          // Remember Me & Forgot Password
          _buildRememberMeAndForgotPassword(viewModel),
          const SizedBox(height: 24),

          // Login Button
          _buildLoginButton(viewModel),
          const SizedBox(height: 20),

          // Divider
          // _buildDivider(),
          // const SizedBox(height: 20),

          // Google Login
          // _buildGoogleLoginButton(viewModel),
          // const SizedBox(height: 16),

          // // Demo Link
          // _buildDemoLink(),
          // const SizedBox(height: 20),

          // Register Redirect
          _buildRegisterRedirect(),
        ],
      ),
    );
  }

  Widget _buildEmailField(LoginViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(
                  Icons.mail_outline,
                  size: 20,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'you@example.com',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                  onChanged: viewModel.setEmail,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(LoginViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  obscureText: !viewModel.showPassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                  onChanged: viewModel.setPassword,
                ),
              ),
              IconButton(
                icon: Icon(
                  viewModel.showPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey[600],
                  size: 20,
                ),
                onPressed: viewModel.togglePasswordVisibility,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRememberMeAndForgotPassword(LoginViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember Me
        Row(
          children: [
            GestureDetector(
              onTap: () =>
                  viewModel.setRememberMe(!viewModel.loginData.rememberMe),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: viewModel.loginData.rememberMe
                        ? AppColors.primary
                        : Colors.grey[400]!,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: viewModel.loginData.rememberMe
                      ? AppColors.primary
                      : Colors.transparent,
                ),
                child: viewModel.loginData.rememberMe
                    ? Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () =>
                  viewModel.setRememberMe(!viewModel.loginData.rememberMe),
              child: Text(
                'Remember me',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
          ],
        ),

        // Forgot Password
        GestureDetector(
          onTap: _showForgotPasswordDialog,
          child: Text(
            'Forgot password?',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(LoginViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: viewModel.isLoading
            ? null
            : () async {
                final success = await viewModel.login();
                if (success && widget.onLoginSuccess != null) {
                  widget.onLoginSuccess!();
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: GestureDetector(
          onTap: () {
            context.go('/home');
          },
          child: viewModel.isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  Widget _buildRegisterRedirect() {
    return Container(
      padding: EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          GestureDetector(
            onTap: () => context.go('/registration'),
            child: Text(
              'Register',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final viewModel = ref.read(loginViewModelProvider);
        String email = '';

        return AlertDialog(
          title: Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter your email address to reset your password.'),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => email = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await viewModel.resetPassword(email);
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password reset email sent!')),
                  );
                }
              },
              child: Text('Reset Password'),
            ),
          ],
        );
      },
    );
  }
}
