import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nilewing/core/utils/app_constants.dart';
import 'package:nilewing/core/utils/token_storage.dart';
import '../model/user_model.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final TokenStorage _tokenStorage = TokenStorage();

  Future<String?> _getAuthToken() async {
    return await _tokenStorage.getAccessToken();
  }

  Future<UserProfile> getProfile() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse(AppConstants.profileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] != null) {
          return UserProfile.fromJson(responseData['data']);
        }
        throw Exception('Failed to load profile');
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading profile: $e');
    }
  }

  Future<UserProfile> updateProfile({
    String? fullName,
    int? age,
    String? gender,
    String? nationality,
    String? language,
    String? profileImagePath,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Create multipart request for file upload
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse(AppConstants.profileEndpoint),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      if (fullName != null) {
        request.fields['fullName'] = fullName;
      }
      if (age != null) {
        request.fields['age'] = age.toString();
      }
      if (gender != null) {
        request.fields['gender'] = gender;
      }
      if (nationality != null) {
        request.fields['nationality'] = nationality;
      }
      if (language != null) {
        request.fields['language'] = language;
      }

      // Add profile image if provided
      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        try {
          final file = await http.MultipartFile.fromPath(
            'profileImage',
            profileImagePath,
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

      if (response.statusCode == 200 && responseData['success'] == true) {
        if (responseData['data'] != null) {
          return UserProfile.fromJson(responseData['data']);
        }
        throw Exception('Profile updated but no data returned');
      } else {
        final errorMessage = responseData['message'] ?? 
            responseData['errors']?.toString() ?? 
            'Failed to update profile';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }
}

