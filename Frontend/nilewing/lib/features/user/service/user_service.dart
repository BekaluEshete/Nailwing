import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nilewing/core/utils/app_constants.dart';
import 'package:nilewing/core/utils/token_storage.dart';
import 'package:nilewing/core/utils/http_client.dart';
import '../model/user_model.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final TokenStorage _tokenStorage = TokenStorage();
  final HttpClient _httpClient = HttpClient();

  Future<String?> _getAuthToken() async {
    return await _tokenStorage.getAccessToken();
  }

  Future<UserProfile> getProfile() async {
    try {
      print('👤 [UserService] Getting user profile...');
      final token = await _getAuthToken();
      if (token == null) {
        print('❌ [UserService] No auth token found');
        throw Exception('Not authenticated');
      }

      print('📡 [UserService] Calling: ${AppConstants.profileEndpoint}');
      final response = await _httpClient.get(
        Uri.parse(AppConstants.profileEndpoint),
      );

      print('📥 [UserService] Response status: ${response.statusCode}');
      print('📥 [UserService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] != null) {
          print('✅ [UserService] Profile loaded successfully');
          return UserProfile.fromJson(responseData['data']);
        }
        print('❌ [UserService] Invalid response format');
        throw Exception('Failed to load profile');
      } else {
        print('❌ [UserService] Failed with status: ${response.statusCode}');
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [UserService] Error loading profile: $e');
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
      print('✏️ [UserService] Updating profile...');
      print('📤 [UserService] Data: fullName=$fullName, age=$age, gender=$gender, nationality=$nationality, language=$language');
      final token = await _getAuthToken();
      if (token == null) {
        print('❌ [UserService] No auth token found');
        throw Exception('Not authenticated');
      }

      // Create multipart request for file upload
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse(AppConstants.profileEndpoint),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields - always send fullName if provided
      if (fullName != null && fullName.isNotEmpty) {
        request.fields['fullName'] = fullName.trim();
      }
      if (age != null) {
        request.fields['age'] = age.toString();
      }
      if (gender != null && gender.isNotEmpty) {
        request.fields['gender'] = gender;
      }
      if (nationality != null) {
        request.fields['nationality'] = nationality.trim();
      } else {
        request.fields['nationality'] = ''; // Send empty string to clear
      }
      if (language != null) {
        request.fields['language'] = language.trim();
      } else {
        request.fields['language'] = ''; // Send empty string to clear
      }

      print('📤 [UserService] Fields: ${request.fields}');

      // Add profile image if provided
      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        try {
          print('📷 [UserService] Adding profile image: $profileImagePath');
          final file = await http.MultipartFile.fromPath(
            'profileImage',
            profileImagePath,
          );
          request.files.add(file);
        } catch (e) {
          print('❌ [UserService] Error adding profile image: $e');
          // Continue without image if there's an error
        }
      }

      print('📡 [UserService] PATCH to: ${AppConstants.profileEndpoint}');
      // Send request using HttpClient for automatic token refresh
      final streamedResponse = await _httpClient.sendMultipart(request);
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📥 [UserService] Response status: ${response.statusCode}');
      print('📥 [UserService] Response body: ${response.body}');
      
      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && responseData['success'] == true) {
        if (responseData['data'] != null) {
          print('✅ [UserService] Profile updated successfully');
          return UserProfile.fromJson(responseData['data']);
        }
        print('❌ [UserService] Profile updated but no data returned');
        throw Exception('Profile updated but no data returned');
      } else {
        final errorMessage = responseData['message'] ?? 
            responseData['errors']?.toString() ?? 
            'Failed to update profile';
        print('❌ [UserService] Error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ [UserService] Error updating profile: $e');
      throw Exception('Error updating profile: $e');
    }
  }
}

