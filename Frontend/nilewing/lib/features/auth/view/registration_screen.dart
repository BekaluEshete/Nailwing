// registration_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/registration_view_model.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSwitchToLogin;
  final VoidCallback? onRegistrationSuccess;

  const RegistrationScreen({
    Key? key,
    this.onSwitchToLogin,
    this.onRegistrationSuccess,
  }) : super(key: key);

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 24),

              // Error Message
              if (viewModel.errorMessage != null)
                _buildErrorBanner(viewModel.errorMessage!),

              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildCardHeader(),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildRegistrationForm(viewModel),
                    ),
                  ],
                ),
              ),
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

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red[800], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Replace with your actual logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(0xFF1E40AF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.flight, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NILE WING',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E40AF),
                ),
              ),
              Text(
                'Aviation Excellence',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 16),
      Column(
        children: [
          Text(
            'Create Your Account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Join our premium flight experience',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    ],
  );

  Widget _buildCardHeader() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
    ),
    child: const Column(
      children: [
        Text(
          'Registration Form',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Please provide your details below',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    ),
  );

  Widget _buildRegistrationForm(RegistrationViewModel viewModel) {
    return Form(
      child: Column(
        children: [
          // Profile Picture
          _buildProfilePicture(viewModel),
          const SizedBox(height: 24),

          // Full Name
          _buildTextField(
            label: 'Full Name *',
            hintText: 'Enter your full name',
            onChanged: viewModel.setFullName,
          ),
          const SizedBox(height: 16),

          // Age
          _buildTextField(
            label: 'Age *',
            hintText: 'Enter your age',
            keyboardType: TextInputType.number,
            onChanged: viewModel.setAge,
          ),
          const SizedBox(height: 16),

          // Gender
          _buildGenderSelector(viewModel),
          const SizedBox(height: 16),

          // Email
          _buildTextField(
            label: 'Email Address *',
            hintText: 'your.email@example.com',
            keyboardType: TextInputType.emailAddress,
            onChanged: viewModel.setEmail,
          ),
          const SizedBox(height: 16),

          // Password
          _buildPasswordField(viewModel),
          const SizedBox(height: 16),

          // Nationality
          _buildNationalityDropdown(viewModel),
          const SizedBox(height: 16),

          // Language - Now shows ALL languages
          _buildLanguageDropdown(viewModel),
          const SizedBox(height: 24),

          // Terms and Privacy
          _buildTermsNotice(),
          const SizedBox(height: 24),

          // Register Button
          _buildRegisterButton(viewModel),
          const SizedBox(height: 16),

          // Login Redirect
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
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  color: Colors.grey[100],
                ),
                child: viewModel.profileImage != null
                    ? ClipOval(
                        child: Image.file(
                          viewModel.profileImage!,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        ),
                      )
                    : Icon(Icons.person, size: 40, color: Colors.grey[400]),
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
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 18),
                    padding: const EdgeInsets.all(2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to upload photo',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                ref.read(registrationViewModelProvider).pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(registrationViewModelProvider)
                    .captureImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    TextInputType? keyboardType,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1E40AF)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildGenderSelector(RegistrationViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender *',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Male'),
                value: 'male',
                groupValue: viewModel.registrationData.gender,
                onChanged: (value) => viewModel.setGender(value!),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Female'),
                value: 'female',
                groupValue: viewModel.registrationData.gender,
                onChanged: (value) => viewModel.setGender(value!),
                contentPadding: EdgeInsets.zero,
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
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          obscureText: !viewModel.showPassword,
          decoration: InputDecoration(
            hintText: 'Create a strong password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1E40AF)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                viewModel.showPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: viewModel.togglePasswordVisibility,
            ),
          ),
          onChanged: viewModel.setPassword,
        ),
        const SizedBox(height: 4),
        Text(
          'Password must be at least 6 characters',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: viewModel.registrationData.nationality.isNotEmpty
                  ? viewModel.registrationData.nationality
                  : null,
              hint: viewModel.isLoadingCountries
                  ? const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Loading countries...'),
                      ],
                    )
                  : const Text('Select your nationality'),
              isExpanded: true,
              items: viewModel.countries.map((country) {
                return DropdownMenuItem<String>(
                  value: country.code,
                  child: Text(country.name),
                );
              }).toList(),
              onChanged: viewModel.isLoadingCountries
                  ? null
                  : (value) => viewModel.setNationality(value!),
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
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: viewModel.registrationData.language.isNotEmpty
                  ? viewModel.registrationData.language
                  : null,
              hint: viewModel.isLoadingCountries
                  ? const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Loading languages...'),
                      ],
                    )
                  : const Text('Select any language'),
              isExpanded: true,
              items: viewModel.languages.map((language) {
                return DropdownMenuItem<String>(
                  value: language.code,
                  child: Text(language.name),
                );
              }).toList(),
              onChanged: viewModel.isLoadingCountries
                  ? null
                  : (value) => viewModel.setLanguage(value!),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose any language you prefer to use',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildTermsNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By creating an account, you agree to Nile Wing\'s Terms of Service and Privacy Policy.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Your data will be processed in accordance with GDPR regulations.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(RegistrationViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: viewModel.isLoading
            ? null
            : () => _handleRegistration(viewModel),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E40AF),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: viewModel.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Create Nile Wing Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Future<void> _handleRegistration(RegistrationViewModel viewModel) async {
    final success = await viewModel.submitRegistration();
    if (success && widget.onRegistrationSuccess != null) {
      widget.onRegistrationSuccess!();
    } else if (!success) {
      // Error is already handled in the viewModel
    }
  }

  Widget _buildLoginRedirect() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have a Nile Wing account? ',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          GestureDetector(
            onTap: widget.onSwitchToLogin,
            child: const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF1E40AF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
