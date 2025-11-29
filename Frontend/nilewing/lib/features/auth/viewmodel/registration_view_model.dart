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

  // Validation properties
  String _fullNameError = '';
  String _ageError = '';
  String _genderError = '';
  String _emailError = '';
  String _passwordError = '';
  String _nationalityError = '';
  String _languageError = '';

  // Getters
  RegistrationData get registrationData => _registrationData;
  bool get showPassword => _showPassword;
  bool get isLoading => _isLoading;
  bool get isLoadingCountries => _isLoadingCountries;
  List<Country> get countries => _countries;
  List<Language> get languages => _allLanguages;
  File? get profileImage => _profileImage;
  String? get errorMessage => _errorMessage;

  // Validation error getters
  String get fullNameError => _fullNameError;
  String get ageError => _ageError;
  String get genderError => _genderError;
  String get emailError => _emailError;
  String get passwordError => _passwordError;
  String get nationalityError => _nationalityError;
  String get languageError => _languageError;

  // Check if form is valid
  bool get isFormValid {
    return _fullNameError.isEmpty &&
        _ageError.isEmpty &&
        _genderError.isEmpty &&
        _emailError.isEmpty &&
        _passwordError.isEmpty &&
        _nationalityError.isEmpty &&
        _languageError.isEmpty &&
        _registrationData.fullName.isNotEmpty &&
        _registrationData.age.isNotEmpty &&
        _registrationData.gender.isNotEmpty &&
        _registrationData.email.isNotEmpty &&
        _registrationData.password.isNotEmpty &&
        _registrationData.nationality.isNotEmpty &&
        _registrationData.language.isNotEmpty;
  }

  // Setters with validation
  void setFullName(String value) {
    _registrationData = _registrationData.copyWith(fullName: value);
    _validateFullName(value);
    _clearError();
    notifyListeners();
  }

  void setAge(String value) {
    _registrationData = _registrationData.copyWith(age: value);
    _validateAge(value);
    _clearError();
    notifyListeners();
  }

  void setGender(String value) {
    _registrationData = _registrationData.copyWith(gender: value);
    _validateGender(value);
    _clearError();
    notifyListeners();
  }

  void setEmail(String value) {
    _registrationData = _registrationData.copyWith(email: value);
    _validateEmail(value);
    _clearError();
    notifyListeners();
  }

  void setPassword(String value) {
    _registrationData = _registrationData.copyWith(password: value);
    _validatePassword(value);
    _clearError();
    notifyListeners();
  }

  void setNationality(String value) {
    _registrationData = _registrationData.copyWith(nationality: value);
    _validateNationality(value);
    _clearError();
    notifyListeners();
  }

  void setLanguage(String value) {
    _registrationData = _registrationData.copyWith(language: value);
    _validateLanguage(value);
    _clearError();
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _showPassword = !_showPassword;
    notifyListeners();
  }

  // Validation methods
  void _validateFullName(String fullName) {
    if (fullName.isEmpty) {
      _fullNameError = 'Full name is required';
    } else if (fullName.length < 2) {
      _fullNameError = 'Full name must be at least 2 characters';
    } else {
      _fullNameError = '';
    }
  }

  void _validateAge(String age) {
    if (age.isEmpty) {
      _ageError = 'Age is required';
    } else if (!_isValidAge(age)) {
      _ageError = 'Please enter a valid age (1-120)';
    } else {
      _ageError = '';
    }
  }

  void _validateGender(String gender) {
    if (gender.isEmpty) {
      _genderError = 'Gender is required';
    } else {
      _genderError = '';
    }
  }

  void _validateEmail(String email) {
    if (email.isEmpty) {
      _emailError = 'Email is required';
    } else if (!_isValidEmail(email)) {
      _emailError = 'Please enter a valid email address';
    } else {
      _emailError = '';
    }
  }

  void _validatePassword(String password) {
    if (password.isEmpty) {
      _passwordError = 'Password is required';
    } else if (password.length < 6) {
      _passwordError = 'Password must be at least 6 characters';
    } else {
      _passwordError = '';
    }
  }

  void _validateNationality(String nationality) {
    if (nationality.isEmpty) {
      _nationalityError = 'Nationality is required';
    } else {
      _nationalityError = '';
    }
  }

  void _validateLanguage(String language) {
    if (language.isEmpty) {
      _languageError = 'Language is required';
    } else {
      _languageError = '';
    }
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
    // Validate all fields before attempting registration
    _validateFullName(_registrationData.fullName);
    _validateAge(_registrationData.age);
    _validateGender(_registrationData.gender);
    _validateEmail(_registrationData.email);
    _validatePassword(_registrationData.password);
    _validateNationality(_registrationData.nationality);
    _validateLanguage(_registrationData.language);

    if (!isFormValid) {
      _errorMessage = 'Please fill all required fields correctly';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _registrationService.submitRegistration(_registrationData);
      _isLoading = false;
      
      if (response.success && response.data != null) {
        _errorMessage = null;
      notifyListeners();
      return true;
      } else {
        // Handle errors from backend
        if (response.errors != null && response.errors!.isNotEmpty) {
          // Get first error message
          final firstErrorKey = response.errors!.keys.first;
          final firstErrorValue = response.errors![firstErrorKey];
          
          if (firstErrorValue is List && firstErrorValue.isNotEmpty) {
            _errorMessage = firstErrorValue.first.toString();
          } else if (firstErrorValue is String) {
            _errorMessage = firstErrorValue;
          } else {
            _errorMessage = 'Registration failed: ${firstErrorKey}';
          }
        } else {
          _errorMessage = response.message.isNotEmpty 
              ? response.message 
              : 'Registration failed. Please try again.';
        }
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
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

    // Clear all validation errors
    _fullNameError = '';
    _ageError = '';
    _genderError = '';
    _emailError = '';
    _passwordError = '';
    _nationalityError = '';
    _languageError = '';

    notifyListeners();
  }
}
