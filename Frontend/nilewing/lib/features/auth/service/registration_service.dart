// registration_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/registration_model.dart';
import 'package:nilewing/core/utils/token_storage.dart';
import 'package:nilewing/core/utils/app_constants.dart';

class RegistrationService {
  static final RegistrationService _instance = RegistrationService._internal();
  factory RegistrationService() => _instance;
  RegistrationService._internal();

  Future<List<Country>> fetchCountries() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://restcountries.com/v3.1/all?fields=name,cca2,languages',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Country> countries = [];

        for (final country in data) {
          final name = country['name']['common']?.toString() ?? '';
          final code = country['cca2']?.toString() ?? '';
          final languages = <String>[];

          if (country['languages'] != null) {
            final langMap = country['languages'] as Map<String, dynamic>;
            languages.addAll(langMap.values.map((e) => e.toString()));
          }

          if (name.isNotEmpty && code.isNotEmpty) {
            countries.add(
              Country(name: name, code: code, languages: languages),
            );
          }
        }

        countries.sort((a, b) => a.name.compareTo(b.name));
        return countries;
      } else {
        throw Exception('Failed to load countries: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching countries: $e');
      return getFallbackCountries();
    }
  }

  List<Country> getFallbackCountries() {
    return [
      Country(name: 'United States', code: 'US', languages: ['English']),
      Country(name: 'United Kingdom', code: 'GB', languages: ['English']),
      Country(name: 'Canada', code: 'CA', languages: ['English', 'French']),
      Country(name: 'Australia', code: 'AU', languages: ['English']),
      Country(name: 'Germany', code: 'DE', languages: ['German']),
      Country(name: 'France', code: 'FR', languages: ['French']),
      Country(name: 'Japan', code: 'JP', languages: ['Japanese']),
      Country(name: 'China', code: 'CN', languages: ['Chinese']),
      Country(name: 'India', code: 'IN', languages: ['Hindi', 'English']),
      Country(name: 'Brazil', code: 'BR', languages: ['Portuguese']),
      Country(name: 'Egypt', code: 'EG', languages: ['Arabic']),
      Country(name: 'Ethiopia', code: 'ET', languages: ['Amharic']),
      Country(
        name: 'South Africa',
        code: 'ZA',
        languages: ['Afrikaans', 'English'],
      ),
      Country(name: 'United Arab Emirates', code: 'AE', languages: ['Arabic']),
      Country(name: 'Saudi Arabia', code: 'SA', languages: ['Arabic']),
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  List<Language> getAllLanguages(List<Country> countries) {
    final allLanguages = <Language>{};
    for (final country in countries) {
      for (final langName in country.languages) {
        allLanguages.add(
          Language(name: langName, code: _generateLanguageCode(langName)),
        );
      }
    }

    return allLanguages.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  String _generateLanguageCode(String languageName) {
    return languageName.toLowerCase().replaceAll(RegExp(r'[^\w]'), '-');
  }

  Future<RegistrationResponse> submitRegistration(RegistrationData data) async {
    // Validate data
    if (!_validateRegistrationData(data)) {
      return RegistrationResponse(
        success: false,
        message: 'Invalid registration data',
      );
    }

    try {
      // Create multipart request for file upload
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(AppConstants.registerEndpoint),
      );

      // Add text fields
      request.fields['fullName'] = data.fullName;
      request.fields['age'] = data.age;
      request.fields['gender'] = data.gender;
      request.fields['email'] = data.email;
      request.fields['password'] = data.password;
      request.fields['password2'] = data.password; // Backend requires password2
      request.fields['nationality'] = data.nationality;
      request.fields['language'] = data.language;

      // Add profile image if available
      if (data.profileImage != null && data.profileImage!.isNotEmpty) {
        try {
          final file = await http.MultipartFile.fromPath(
            'profileImage',
            data.profileImage!,
          );
          request.files.add(file);
        } catch (e) {
          print('Error adding profile image: $e');
          // Continue without image if there's an error
        }
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = json.decode(response.body) as Map<String, dynamic>;

      final registrationResponse = RegistrationResponse.fromJson(responseData);

      // Save tokens if registration successful
      if (registrationResponse.success && registrationResponse.data != null) {
        final tokenStorage = TokenStorage();
        await tokenStorage.saveAccessToken(
          registrationResponse.data!.tokens.access,
        );
        await tokenStorage.saveRefreshToken(
          registrationResponse.data!.tokens.refresh,
        );
        await tokenStorage.saveUserData(
          registrationResponse.data!.user.toJson(),
        );
      }

      return registrationResponse;
    } catch (e) {
      return RegistrationResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  bool _validateRegistrationData(RegistrationData data) {
    return data.fullName.isNotEmpty &&
        data.age.isNotEmpty &&
        data.gender.isNotEmpty &&
        _isValidEmail(data.email) &&
        data.password.length >= 6 &&
        data.nationality.isNotEmpty &&
        data.language.isNotEmpty;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
