import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Change this to your server URL
  String _baseUrl = 'http://10.0.2.2:3000/api';
  String? _token;

  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
  }

  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Auth APIs
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'fullName': fullName,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Server tidak merespon.');
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201 && data['success']) {
        await saveToken(data['data']['token']);
        return data;
      } else {
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } on http.ClientException {
      throw Exception('Tidak dapat terhubung ke server. Pastikan server berjalan di $_baseUrl');
    } catch (e) {
      if (e.toString().contains('Connection timeout')) {
        rethrow;
      }
      throw Exception('Registration error: $e');
    }
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Server tidak merespon.');
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        await saveToken(data['data']['token']);
        return data;
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } on http.ClientException {
      throw Exception('Tidak dapat terhubung ke server. Pastikan server berjalan di $_baseUrl');
    } catch (e) {
      if (e.toString().contains('Connection timeout')) {
        rethrow;
      }
      throw Exception('Login error: $e');
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      await loadToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/profile'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to load profile');
      }
    } catch (e) {
      throw Exception('Profile error: $e');
    }
  }

  // Board Configuration APIs
  Future<Map<String, dynamic>> getBoardConfig(int level) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/board/$level'),
        headers: _getHeaders(includeAuth: false),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to load board config');
      }
    } catch (e) {
      throw Exception('Board config error: $e');
    }
  }

  Future<List<dynamic>> getAllQuizzes() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/quiz?isActive=true'),
        headers: _getHeaders(includeAuth: false),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to load quizzes');
      }
    } catch (e) {
      throw Exception('Quizzes error: $e');
    }
  }

  // Game History APIs
  Future<Map<String, dynamic>> saveGameHistory(Map<String, dynamic> gameData) async {
    try {
      await loadToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/game/history'),
        headers: _getHeaders(),
        body: jsonEncode(gameData),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201 && data['success']) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to save game history');
      }
    } catch (e) {
      throw Exception('Save game error: $e');
    }
  }

  Future<Map<String, dynamic>> getGameHistory({int page = 1, int limit = 10}) async {
    try {
      await loadToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/game/history?page=$page&limit=$limit'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to load game history');
      }
    } catch (e) {
      throw Exception('Game history error: $e');
    }
  }

  Future<List<dynamic>> getLeaderboard({String sortBy = 'wins', int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/game/leaderboard?sortBy=$sortBy&limit=$limit'),
        headers: _getHeaders(includeAuth: false),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to load leaderboard');
      }
    } catch (e) {
      throw Exception('Leaderboard error: $e');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    await loadToken();
    return _token != null;
  }

  Future<void> logout() async {
    await clearToken();
  }
}
