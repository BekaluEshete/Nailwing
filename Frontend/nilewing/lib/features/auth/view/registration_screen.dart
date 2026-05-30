import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nilewing/core/theme/app_colors.dart';
import 'package:nilewing/core/providers/auth_provider.dart';
import '../viewmodel/registration_view_model.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSwitchToLogin;
  final VoidCallback? onRegistrationSuccess;

  const RegistrationScreen({
    super.key,
    this.onSwitchToLogin,
    this.onRegistrationSuccess,
  });

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registrationViewModelProvider).loadCountriesAndLanguages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(registrationViewModelProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Premium Background
          _buildBackground(),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),

                  if (viewModel.errorMessage != null)
                    _buildErrorBanner(viewModel.errorMessage!),

                  // Glassmorphic Form Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Column(
                          children: [
                            _buildCardHeader(),
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: _buildRegistrationForm(viewModel),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '© 2025 Nile Wing Airlines. All rights reserved.',
                    style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFECFEFF).withOpacity(0.8),
                    const Color(0xFFF0F9FF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlob(250, const Color(0xFFCFFAFE).withOpacity(0.5)),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: _buildBlob(300, const Color(0xFFE0F2FE).withOpacity(0.6)),
          ),
          Positioned(
            top: 400,
            left: -50,
            child: _buildBlob(200, const Color(0xFFECFEFF).withOpacity(0.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade800, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Image.asset(
              'assets/images/nilewing_logo.jpeg',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join our premium flight experience',
          style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w400),
        ),
      ],
    );
  }

  Widget _buildCardHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withBlue(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Please fill in your information below',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm(RegistrationViewModel viewModel) {
    return Form(
      child: Column(
        children: [
          _buildProfilePicture(viewModel),
          const SizedBox(height: 32),

          _buildTextField(
            label: 'Full Name *',
            hintText: 'Enter your full name',
            icon: Icons.person_outline_rounded,
            onChanged: viewModel.setFullName,
            errorText: viewModel.fullNameError,
          ),
          const SizedBox(height: 20),

          _buildTextField(
            label: 'Age *',
            hintText: 'Enter your age',
            icon: Icons.calendar_today_rounded,
            keyboardType: TextInputType.number,
            onChanged: viewModel.setAge,
            errorText: viewModel.ageError,
          ),
          const SizedBox(height: 20),

          _buildGenderSelector(viewModel),
          const SizedBox(height: 20),

          _buildTextField(
            label: 'Email Address *',
            hintText: 'your.email@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            onChanged: viewModel.setEmail,
            errorText: viewModel.emailError,
          ),
          const SizedBox(height: 20),

          _buildPasswordField(viewModel),
          const SizedBox(height: 20),

          _buildNationalityDropdown(viewModel),
          const SizedBox(height: 20),

          _buildLanguageDropdown(viewModel),
          const SizedBox(height: 32),

          _buildTermsNotice(),
          const SizedBox(height: 32),

          _buildRegisterButton(viewModel),
          const SizedBox(height: 24),

          _buildLoginRedirect(),
        ],
      ),
    );
  }

  Widget _buildProfilePicture(RegistrationViewModel viewModel) {
    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _showImagePickerOptions,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: viewModel.profileImage != null
                    ? ClipOval(
                        child: Image.file(
                          viewModel.profileImage!,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                        ),
                      )
                    : Icon(Icons.add_a_photo_rounded, size: 40, color: Colors.grey[400]),
              ),
            ),
            if (viewModel.profileImage != null)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: viewModel.removeProfileImage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Upload Profile Photo',
          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Wrap(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.photo_library_rounded, color: Colors.blue.shade700),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(registrationViewModelProvider).pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.photo_camera_rounded, color: Colors.green.shade700),
                ),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(registrationViewModelProvider).captureImageFromCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    required Function(String) onChanged,
    required String errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800], fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText.isNotEmpty ? Colors.red.shade300 : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          child: TextFormField(
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: errorText.isNotEmpty ? Colors.red.shade400 : Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: onChanged,
          ),
        ),
        if (errorText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(errorText, style: TextStyle(color: Colors.red.shade600, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildGenderSelector(RegistrationViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender *',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800], fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => viewModel.setGender('male'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: viewModel.registrationData.gender == 'male' ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: viewModel.registrationData.gender == 'male' ? AppColors.primary : Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Male',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: viewModel.registrationData.gender == 'male' ? AppColors.primary : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => viewModel.setGender('female'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: viewModel.registrationData.gender == 'female' ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: viewModel.registrationData.gender == 'female' ? AppColors.primary : Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Female',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: viewModel.registrationData.gender == 'female' ? AppColors.primary : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordField(RegistrationViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password *',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800], fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: TextFormField(
            obscureText: !viewModel.showPassword,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Create a strong password',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.grey[400]),
              suffixIcon: IconButton(
                icon: Icon(
                  viewModel.showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.grey[400],
                ),
                onPressed: viewModel.togglePasswordVisibility,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: viewModel.setPassword,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Must be at least 6 characters',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildNationalityDropdown(RegistrationViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nationality *',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800], fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: viewModel.registrationData.nationality.isNotEmpty
                  ? viewModel.registrationData.nationality
                  : null,
              hint: viewModel.isLoadingCountries
                  ? Row(
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                        const SizedBox(width: 12),
                        Text('Loading countries...', style: TextStyle(color: Colors.grey[500])),
                      ],
                    )
                  : Text('Select your nationality', style: TextStyle(color: Colors.grey[400])),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[600]),
              items: viewModel.countries.map((country) {
                return DropdownMenuItem<String>(
                  value: country.code,
                  child: Text(country.name),
                );
              }).toList(),
              onChanged: viewModel.isLoadingCountries ? null : (value) => viewModel.setNationality(value!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageDropdown(RegistrationViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferred Language *',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800], fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: viewModel.registrationData.language.isNotEmpty
                  ? viewModel.registrationData.language
                  : null,
              hint: viewModel.isLoadingCountries
                  ? Row(
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                        const SizedBox(width: 12),
                        Text('Loading languages...', style: TextStyle(color: Colors.grey[500])),
                      ],
                    )
                  : Text('Select your language', style: TextStyle(color: Colors.grey[400])),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[600]),
              items: viewModel.languages.map((language) {
                return DropdownMenuItem<String>(
                  value: language.code,
                  child: Text(language.name),
                );
              }).toList(),
              onChanged: viewModel.isLoadingCountries ? null : (value) => viewModel.setLanguage(value!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'By creating an account, you agree to our Terms of Service and Privacy Policy. Your data is protected.',
              style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(RegistrationViewModel viewModel) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withBlue(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (viewModel.isLoading || !viewModel.isFormValid)
            ? null
            : () => _handleRegistration(viewModel),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: viewModel.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Create Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
      ),
    );
  }

  Future<void> _handleRegistration(RegistrationViewModel viewModel) async {
    if (!viewModel.isFormValid) return;

    final success = await viewModel.submitRegistration();
    if (success) {
      ref.read(authStateProvider.notifier).login();
      if (mounted) context.go('/home');
      if (widget.onRegistrationSuccess != null) {
        widget.onRegistrationSuccess!();
      }
    }
  }

  Widget _buildLoginRedirect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
        GestureDetector(
          onTap: () {
            if (widget.onSwitchToLogin != null) {
              widget.onSwitchToLogin!();
            } else {
              context.go('/login');
            }
          },
          child: const Text(
            'Sign In',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
