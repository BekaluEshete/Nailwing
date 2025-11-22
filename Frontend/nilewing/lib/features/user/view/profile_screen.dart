import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/core/theme/app_colors.dart';
import 'package:nilewing/features/user/viewmodel/user_view_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _ageController;
  late TextEditingController _nationalityController;
  late TextEditingController _languageController;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _ageController = TextEditingController();
    _nationalityController = TextEditingController();
    _languageController = TextEditingController();
    
    // Load profile when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userViewModelProvider).loadProfile();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _nationalityController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(userViewModelProvider);
    final profile = viewModel.userProfile;

    // Update controllers when profile loads
    if (profile != null && _fullNameController.text.isEmpty) {
      _fullNameController.text = profile.fullName;
      _ageController.text = profile.age?.toString() ?? '';
      _nationalityController.text = profile.nationality ?? '';
      _languageController.text = profile.language ?? '';
      _selectedGender = profile.gender;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Image Section
                    _buildProfileImageSection(viewModel, profile),
                    const SizedBox(height: 24),

                    // Error Message
                    if (viewModel.errorMessage != null)
                      _buildErrorBanner(viewModel.errorMessage!),

                    // Profile Form
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Personal Information'),
                            const SizedBox(height: 16),
                            
                            // Full Name
                            _buildTextField(
                              controller: _fullNameController,
                              label: 'Full Name',
                              icon: Icons.person,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Full name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Age
                            _buildTextField(
                              controller: _ageController,
                              label: 'Age',
                              icon: Icons.cake,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final age = int.tryParse(value);
                                  if (age == null || age < 1 || age > 120) {
                                    return 'Please enter a valid age';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Gender
                            _buildGenderDropdown(),
                            const SizedBox(height: 24),

                            _buildSectionTitle('Location & Language'),
                            const SizedBox(height: 16),

                            // Nationality
                            _buildTextField(
                              controller: _nationalityController,
                              label: 'Nationality',
                              icon: Icons.flag,
                            ),
                            const SizedBox(height: 16),

                            // Language
                            _buildTextField(
                              controller: _languageController,
                              label: 'Language',
                              icon: Icons.language,
                            ),
                            const SizedBox(height: 24),

                            // Save Button
                            _buildSaveButton(viewModel),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileImageSection(UserViewModel viewModel, profile) {
    final selectedImage = viewModel.selectedImage;
    final profileImageUrl = profile?.profileImageUrl;

    return Center(
      child: Stack(
        children: [
          // Profile Image
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: selectedImage != null
                  ? Image.file(
                      selectedImage,
                      fit: BoxFit.cover,
                    )
                  : profileImageUrl != null
                      ? Image.network(
                          profileImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        )
                      : _buildDefaultAvatar(),
            ),
          ),

          // Edit Button
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                onSelected: (value) async {
                  if (value == 'gallery') {
                    await viewModel.pickImageFromGallery();
                  } else if (value == 'camera') {
                    await viewModel.captureImageFromCamera();
                  } else if (value == 'remove' && selectedImage != null) {
                    viewModel.removeSelectedImage();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'gallery',
                    child: Row(
                      children: [
                        Icon(Icons.photo_library, size: 20),
                        SizedBox(width: 8),
                        Text('Choose from Gallery'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'camera',
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt, size: 20),
                        SizedBox(width: 8),
                        Text('Take Photo'),
                      ],
                    ),
                  ),
                  if (selectedImage != null)
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Remove', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Icon(
        Icons.person,
        size: 60,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'male', child: Text('Male')),
        DropdownMenuItem(value: 'female', child: Text('Female')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedGender = value;
        });
      },
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

  Widget _buildSaveButton(UserViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: viewModel.isUpdating
            ? null
            : () async {
                if (_formKey.currentState!.validate()) {
                  final success = await viewModel.updateProfile(
                    fullName: _fullNameController.text.trim(),
                    age: _ageController.text.isNotEmpty
                        ? int.tryParse(_ageController.text)
                        : null,
                    gender: _selectedGender,
                    nationality: _nationalityController.text.trim(),
                    language: _languageController.text.trim(),
                  );

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          viewModel.errorMessage ?? 'Failed to update profile',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: viewModel.isUpdating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

