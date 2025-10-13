// registration_view_model.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../model/registration_model.dart';
import '../service/registration_service.dart';

final registrationViewModelProvider =
    ChangeNotifierProvider<RegistrationViewModel>(
      (ref) => RegistrationViewModel(),
    );

class RegistrationViewModel with ChangeNotifier {
  final RegistrationService _registrationService = RegistrationService();
  final ImagePicker _imagePicker = ImagePicker();

  RegistrationData _registrationData = RegistrationData(
    fullName: '',
    age: '',
    gender: '',
    email: '',
    password: '',
    nationality: '',
    language: '',
  );

  bool _showPassword = false;
  bool _isLoading = false;
  bool _isLoadingCountries = false;
  List<Country> _countries = [];
  List<Language> _allLanguages = [];
  File? _profileImage;
  String? _errorMessage;

  // Getters
  RegistrationData get registrationData => _registrationData;
  bool get showPassword => _showPassword;
  bool get isLoading => _isLoading;
  bool get isLoadingCountries => _isLoadingCountries;
  List<Country> get countries => _countries;
  List<Language> get languages => _allLanguages;
  File? get profileImage => _profileImage;
  String? get errorMessage => _errorMessage;

  // Setters
  void setFullName(String value) {
    _registrationData = _registrationData.copyWith(fullName: value);
    _clearError();
    notifyListeners();
  }

  void setAge(String value) {
    _registrationData = _registrationData.copyWith(age: value);
    _clearError();
    notifyListeners();
  }

  void setGender(String value) {
    _registrationData = _registrationData.copyWith(gender: value);
    _clearError();
    notifyListeners();
  }

  void setEmail(String value) {
    _registrationData = _registrationData.copyWith(email: value);
    _clearError();
    notifyListeners();
  }

  void setPassword(String value) {
    _registrationData = _registrationData.copyWith(password: value);
    _clearError();
    notifyListeners();
  }

  void setNationality(String value) {
    _registrationData = _registrationData.copyWith(nationality: value);
    _clearError();
    notifyListeners();
  }

  void setLanguage(String value) {
    _registrationData = _registrationData.copyWith(language: value);
    _clearError();
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _showPassword = !_showPassword;
    notifyListeners();
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        _profileImage = File(pickedFile.path);
        _registrationData = _registrationData.copyWith(
          profileImage: pickedFile.path,
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to pick image from gallery: $e';
      notifyListeners();
    }
  }

  Future<void> captureImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        _profileImage = File(pickedFile.path);
        _registrationData = _registrationData.copyWith(
          profileImage: pickedFile.path,
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to capture image: $e';
      notifyListeners();
    }
  }

  void removeProfileImage() {
    _profileImage = null;
    _registrationData = _registrationData.copyWith(profileImage: null);
    notifyListeners();
  }

  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> loadCountriesAndLanguages() async {
    _isLoadingCountries = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _countries = await _registrationService.fetchCountries();
      _allLanguages = _registrationService.getAllLanguages(_countries);
    } catch (e) {
      _errorMessage = 'Failed to load countries and languages: $e';
      debugPrint('Error loading data: $e');
    } finally {
      _isLoadingCountries = false;
      notifyListeners();
    }
  }

  Future<bool> submitRegistration() async {
    if (!_validateForm()) {
      _errorMessage = 'Please fill all required fields correctly';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _registrationService.submitRegistration(_registrationData);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  bool _validateForm() {
    return _registrationData.fullName.isNotEmpty &&
        _registrationData.age.isNotEmpty &&
        _isValidAge(_registrationData.age) &&
        _registrationData.gender.isNotEmpty &&
        _registrationData.email.isNotEmpty &&
        _isValidEmail(_registrationData.email) &&
        _registrationData.password.isNotEmpty &&
        _registrationData.password.length >= 6 &&
        _registrationData.nationality.isNotEmpty &&
        _registrationData.language.isNotEmpty;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  bool _isValidAge(String age) {
    final ageValue = int.tryParse(age);
    return ageValue != null && ageValue >= 1 && ageValue <= 120;
  }

  void resetForm() {
    _registrationData = RegistrationData(
      fullName: '',
      age: '',
      gender: '',
      email: '',
      password: '',
      nationality: '',
      language: '',
    );
    _profileImage = null;
    _showPassword = false;
    _errorMessage = null;
    notifyListeners();
  }
}
