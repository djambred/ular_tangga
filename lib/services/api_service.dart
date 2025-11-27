import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Production URL - Change to your domain
  // Use localhost for development/testing
  String _baseUrl = 'http://localhost:3000/api';
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
      print('📡 Registering to: $_baseUrl/auth/register');
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
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Server tidak merespon setelah 15 detik.');
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201 && data['success']) {
        await saveToken(data['data']['token']);
        return data;
      } else {
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } on http.ClientException catch (e) {
      print('❌ ClientException: $e');
      throw Exception('Tidak dapat terhubung ke server. Pastikan koneksi internet aktif.\n\nServer: $_baseUrl');
    } on FormatException catch (e) {
      print('❌ FormatException: $e');
      throw Exception('Server response tidak valid');
    } catch (e) {
      print('❌ Error: $e');
      if (e.toString().contains('Connection timeout')) {
        rethrow;
      }
      if (e.toString().contains('SocketException')) {
        throw Exception('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
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

  // Content APIs
  Future<Map<String, dynamic>> getContent(String type) async {
    try {
      print('📚 Fetching content: $type from $_baseUrl/content/$type');
      final response = await http.get(
        Uri.parse('$_baseUrl/content/$type'),
        headers: _getHeaders(includeAuth: false),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout loading content');
        },
      );

      print('📥 Content response: ${response.statusCode}');
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to load content');
      }
    } catch (e) {
      print('❌ Error fetching content: $e');
      throw Exception('Content error: $e');
    }
  }

  Future<Map<String, dynamic>> getAllContent() async {
    try {
      print('📚 Fetching all content from $_baseUrl/content');
      
      final results = await Future.wait([
        getContent('snake_message'),
        getContent('ladder_message'),
        getContent('fact'),
      ]);
      
      return {
        'success': true,
        'data': {
          'snakeMessages': results[0]['data'] ?? [],
          'ladderMessages': results[1]['data'] ?? [],
          'facts': results[2]['data'] ?? [],
        }
      };
    } catch (e) {
      print('❌ Error fetching all content: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Config APIs
  Future<Map<String, dynamic>> getPublicConfigs() async {
    try {
      print('⚙️ Fetching public configs from $_baseUrl/config/public');
      final response = await http.get(
        Uri.parse('$_baseUrl/config/public'),
        headers: _getHeaders(includeAuth: false),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout loading config');
        },
      );

      print('📥 Config response: ${response.statusCode}');
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to load config');
      }
    } catch (e) {
      print('❌ Error fetching config: $e');
      throw Exception('Config error: $e');
    }
  }

  // Apply configurations from backend
  Future<void> applyConfigs() async {
    try {
      final result = await getPublicConfigs();
      if (result['success'] && result['data'] != null) {
        final configs = result['data'];
        
        // Get active environment and apply corresponding URLs
        final activeEnv = configs['active_environment'] ?? 'production';
        final envPrefix = 'env_${activeEnv}';
        
        // Check if environment is enabled
        final envEnabled = configs['${envPrefix}_enabled'] ?? false;
        
        if (envEnabled) {
          final apiUrl = configs['${envPrefix}_api_url'];
          if (apiUrl != null) {
            _baseUrl = '$apiUrl/api';
            print('✅ Environment: $activeEnv');
            print('✅ API URL: $_baseUrl');
          }
        } else {
          print('⚠️ Environment $activeEnv is disabled, using default URL');
        }
        
        // Store configs in shared preferences for offline use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('app_configs', jsonEncode(configs));
        await prefs.setString('active_environment', activeEnv);
        print('✅ Configs saved to local storage');
      }
    } catch (e) {
      print('⚠️ Could not apply remote configs: $e');
      // Use local cached configs if remote fails
      final prefs = await SharedPreferences.getInstance();
      final cachedConfigs = prefs.getString('app_configs');
      if (cachedConfigs != null) {
        print('📦 Using cached configs');
        final configs = jsonDecode(cachedConfigs);
        final activeEnv = configs['active_environment'] ?? 'production';
        final envPrefix = 'env_${activeEnv}';
        final apiUrl = configs['${envPrefix}_api_url'];
        if (apiUrl != null) {
          _baseUrl = '$apiUrl/api';
        }
      }
    }
  }

  // Get cached config value
  Future<dynamic> getConfigValue(String key, {dynamic defaultValue}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedConfigs = prefs.getString('app_configs');
      
      if (cachedConfigs != null) {
        final configs = jsonDecode(cachedConfigs);
        return configs[key] ?? defaultValue;
      }
    } catch (e) {
      print('⚠️ Error reading config: $e');
    }
    return defaultValue;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    await loadToken();
    return _token != null;
  }

  Future<void> logout() async {
    await clearToken();
  }

  // Dashboard APIs
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      await loadToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/game/dashboard'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Gagal mengambil dashboard stats');
      }
    } catch (e) {
      print('❌ Get dashboard stats error: $e');
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getGameAnalytics() async {
    try {
      await loadToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/game/analytics'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Gagal mengambil analytics');
      }
    } catch (e) {
      print('❌ Get analytics error: $e');
      throw Exception('Error: $e');
    }
  }
}
