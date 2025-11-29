import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nilewing/core/utils/token_storage.dart';
import 'package:nilewing/core/utils/token_refresh_service.dart';

/// HTTP client wrapper that automatically handles token refresh on 401 errors
class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  factory HttpClient() => _instance;
  HttpClient._internal();

  final TokenStorage _tokenStorage = TokenStorage();
  final TokenRefreshService _tokenRefreshService = TokenRefreshService();

  /// Make an authenticated GET request with automatic token refresh
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    bool retryOn401 = true,
  }) async {
    return await _makeRequest(
      () async {
        final token = await _tokenStorage.getAccessToken();
        final requestHeaders = Map<String, String>.from(headers ?? {});
        requestHeaders['Content-Type'] = 'application/json';
        if (token != null) {
          requestHeaders['Authorization'] = 'Bearer $token';
        }
        return await http.get(url, headers: requestHeaders);
      },
      retryOn401: retryOn401,
    );
  }

  /// Make an authenticated POST request with automatic token refresh
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool retryOn401 = true,
  }) async {
    return await _makeRequest(
      () async {
        final token = await _tokenStorage.getAccessToken();
        final requestHeaders = Map<String, String>.from(headers ?? {});
        requestHeaders['Content-Type'] = 'application/json';
        if (token != null) {
          requestHeaders['Authorization'] = 'Bearer $token';
        }
        return await http.post(
          url,
          headers: requestHeaders,
          body: body,
          encoding: encoding,
        );
      },
      retryOn401: retryOn401,
    );
  }

  /// Make an authenticated PUT request with automatic token refresh
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool retryOn401 = true,
  }) async {
    return await _makeRequest(
      () async {
        final token = await _tokenStorage.getAccessToken();
        final requestHeaders = Map<String, String>.from(headers ?? {});
        requestHeaders['Content-Type'] = 'application/json';
        if (token != null) {
          requestHeaders['Authorization'] = 'Bearer $token';
        }
        return await http.put(
          url,
          headers: requestHeaders,
          body: body,
          encoding: encoding,
        );
      },
      retryOn401: retryOn401,
    );
  }

  /// Make an authenticated PATCH request with automatic token refresh
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool retryOn401 = true,
  }) async {
    return await _makeRequest(
      () async {
        final token = await _tokenStorage.getAccessToken();
        final requestHeaders = Map<String, String>.from(headers ?? {});
        requestHeaders['Content-Type'] = 'application/json';
        if (token != null) {
          requestHeaders['Authorization'] = 'Bearer $token';
        }
        return await http.patch(
          url,
          headers: requestHeaders,
          body: body,
          encoding: encoding,
        );
      },
      retryOn401: retryOn401,
    );
  }

  /// Make an authenticated DELETE request with automatic token refresh
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool retryOn401 = true,
  }) async {
    return await _makeRequest(
      () async {
        final token = await _tokenStorage.getAccessToken();
        final requestHeaders = Map<String, String>.from(headers ?? {});
        requestHeaders['Content-Type'] = 'application/json';
        if (token != null) {
          requestHeaders['Authorization'] = 'Bearer $token';
        }
        return await http.delete(
          url,
          headers: requestHeaders,
          body: body,
          encoding: encoding,
        );
      },
      retryOn401: retryOn401,
    );
  }

  /// Generic request handler with automatic token refresh
  Future<http.Response> _makeRequest(
    Future<http.Response> Function() request, {
    bool retryOn401 = true,
  }) async {
    try {
      final response = await request();

      // If we get a 401 and retry is enabled, try to refresh token and retry
      if (response.statusCode == 401 && retryOn401) {
        print('🔄 [HttpClient] Got 401, attempting token refresh...');
        
        final newToken = await _tokenRefreshService.refreshAccessToken();
        
        if (newToken != null) {
          print('✅ [HttpClient] Token refreshed, retrying request...');
          // Retry the request with the new token
          return await request();
        } else {
          print('❌ [HttpClient] Token refresh failed, returning 401 response');
          return response;
        }
      }

      return response;
    } catch (e) {
      print('❌ [HttpClient] Request error: $e');
      rethrow;
    }
  }

  /// Send a multipart request (for file uploads) with automatic token refresh
  /// Note: If token refresh is needed, the token will be refreshed but the request
  /// won't be automatically retried (caller should retry manually if needed)
  Future<http.StreamedResponse> sendMultipart(
    http.MultipartRequest request, {
    bool retryOn401 = true,
  }) async {
    // Add auth token to headers
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final streamedResponse = await request.send();
    
    // Check status code by reading the response
    final response = await http.Response.fromStream(streamedResponse);

    // If we get a 401, refresh the token for future requests
    // Note: We can't retry multipart requests automatically because the stream is consumed
    // The caller should check the status code and retry if needed
    if (response.statusCode == 401 && retryOn401) {
      print('🔄 [HttpClient] Got 401 in multipart request, refreshing token...');
      await _tokenRefreshService.refreshAccessToken();
      print('⚠️ [HttpClient] Multipart request failed with 401. Token refreshed. Please retry the request.');
    }

    // Recreate streamed response from the response we read
    // This is necessary because we consumed the stream to check the status
    final responseBytes = response.bodyBytes;
    return http.StreamedResponse(
      http.ByteStream.fromBytes(responseBytes),
      response.statusCode,
      contentLength: responseBytes.length,
      request: request,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
    );
  }
}

