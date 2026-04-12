import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tunify/v2/core/errors/exceptions.dart';
import 'package:tunify/v2/core/network/api_config.dart';
import 'package:tunify/v2/core/network/tunify_auth_prefs.dart';

/// Thin JSON HTTP client for the Tunify Rust backend (`/v1/...`).
class TunifyApiClient {
  TunifyApiClient({
    required ApiConfig config,
    required SharedPreferences prefs,
    http.Client? httpClient,
  })  : _config = config,
        _prefs = prefs,
        _http = httpClient ?? http.Client();

  final ApiConfig _config;
  final SharedPreferences _prefs;
  final http.Client _http;

  void close() {
    _http.close();
  }

  Uri _uri(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${_config.baseUrl}$p');
  }

  Map<String, String> _headers({required bool withAuth}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (withAuth) {
      final token = _prefs.getString(TunifyAuthPrefsKeys.accessToken);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static String _messageFromBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final err = decoded['error'];
        if (err is Map<String, dynamic>) {
          final msg = err['message'];
          if (msg is String && msg.isNotEmpty) {
            return msg;
          }
        }
      }
    } catch (_) {
      // fall through
    }
    return 'Request failed';
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    bool withAuth = true,
    Map<String, String>? query,
  }) async {
    var uri = _uri(path);
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: {...uri.queryParameters, ...query});
    }
    final response =
        await _http.get(uri, headers: _headers(withAuth: withAuth));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ServerException(
        _messageFromBody(response.body),
        code: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ServerException('Invalid JSON object response');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = false,
  }) async {
    final response = await _http.post(
      _uri(path),
      headers: _headers(withAuth: withAuth),
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ServerException(
        _messageFromBody(response.body),
        code: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ServerException('Invalid JSON object response');
    }
    return decoded;
  }
}
