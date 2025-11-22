import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../model/user_model.dart';
import '../service/user_service.dart';

final userViewModelProvider =
    ChangeNotifierProvider<UserViewModel>((ref) => UserViewModel());

class UserViewModel extends ChangeNotifier {
  final UserService _userService = UserService();

  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;
  File? _selectedImage;
  bool _isUpdating = false;

  // Getters
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  File? get selectedImage => _selectedImage;

  // Load user profile
  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userProfile = await _userService.getProfile();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load profile: ${e.toString()}';
      _userProfile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? fullName,
    int? age,
    String? gender,
    String? nationality,
    String? language,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedProfile = await _userService.updateProfile(
        fullName: fullName,
        age: age,
        gender: gender,
        nationality: nationality,
        language: language,
        profileImagePath: _selectedImage?.path,
      );

      _userProfile = updatedProfile;
      _selectedImage = null; // Clear selected image after upload
      _errorMessage = null;
      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile: ${e.toString()}';
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  // Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to pick image: ${e.toString()}';
      notifyListeners();
    }
  }

  // Capture image from camera
  Future<void> captureImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to capture image: ${e.toString()}';
      notifyListeners();
    }
  }

  // Remove selected image
  void removeSelectedImage() {
    _selectedImage = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

