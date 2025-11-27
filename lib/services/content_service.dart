import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class ContentService {
  static final ContentService _instance = ContentService._internal();
  factory ContentService() => _instance;
  ContentService._internal();

  final ApiService _apiService = ApiService();
  
  // Cache keys
  static const String _cacheKeySnakeMessages = 'cached_snake_messages';
  static const String _cacheKeyLadderMessages = 'cached_ladder_messages';
  static const String _cacheKeyFacts = 'cached_facts';
  static const String _cacheKeyTimestamp = 'content_cache_timestamp';
  
  // Cache duration: 24 hours
  static const Duration _cacheDuration = Duration(hours: 24);
  
  List<String> _snakeMessages = [];
  List<String> _ladderMessages = [];
  List<String> _facts = [];
  bool _isLoaded = false;

  // Default fallback content (from original game_screen.dart)
  final List<String> _defaultSnakeMessages = [
    'Lupa minum obat TBC, bisa bikin kuman makin kuat!',
    'Meludah sembarangan, nanti kumannya terbang ke orang lain!',
    'Batuk tanpa menutup mulut, teman bisa ikut sakit.',
    'Berhenti minum obat sebelum waktunya, itu berbahaya!',
    'Percaya mitos aneh kalau TBC tidak bisa sembuh.',
    'Pinjam-pinjam alat makan dengan pasien TBC aktif.',
    'Tidak memakai masker di ruangan ramai.',
    'Membiarkan kamar gelap dan pengap setiap hari.',
    'Mengabaikan batuk lama dan tidak cerita ke orang tua.',
    'Tidak mau ikut periksa padahal tinggal serumah dengan pasien TBC.',
  ];

  final List<String> _defaultLadderMessages = [
    'Segera periksa kalau batuknya tidak sembuh-sembuh!',
    'Minum obat TBC tiap hari sampai selesai, biar cepat sembuh!',
    'Buka jendela rumah supaya udara segar masuk.',
    'Menutup mulut saat batuk dengan tisu atau siku.',
    'Ajak keluarga untuk periksa bila ada yang sakit TBC.',
    'Rajin menjemur kasur biar kuman kabur.',
    'Membersihkan rumah dari debu setiap hari.',
    'Pakai masker saat ada yang sedang sakit.',
    'Mendukung teman atau keluarga yang sedang berobat.',
    'Suka belajar hal baru tentang kesehatan!',
  ];

  final List<String> _defaultFacts = [
    'TBC adalah penyakit yang bisa disembuhkan, asal minum obat teratur.',
    'Kuman TBC menyebar lewat udara saat orang batuk atau bersin.',
    'Kalau batuk lebih dari 2 minggu, segera bilang ke orang tua.',
    'Obat TBC diberikan gratis di Puskesmas.',
    'Kalau obatnya berhenti diminum, kumannya bisa jadi lebih kuat.',
    'Sinar matahari bisa membantu membunuh kuman TBC.',
    'Anak juga bisa kena TBC, apalagi kalau sering dekat pasien TBC.',
    'Masker membantu mencegah penularan TBC.',
    'Rumah yang sering dibuka jendelanya lebih sehat.',
    'TBC bukan penyakit kutukan atau turunan.',
    'TBC tidak menular lewat pelukan atau jabat tangan.',
    'Makan makanan bergizi membantu tubuh melawan penyakit.',
    'Imunisasi BCG melindungi bayi dari TBC berat.',
    'Kalau ada keluarga sakit TBC, sebaiknya ikut periksa juga.',
    'Debu dan rumah pengap bisa membuat kuman lebih betah.',
    'Pasien TBC harus kontrol rutin ke fasilitas kesehatan.',
    'TBC bisa menyerang paru-paru dan bagian tubuh lain.',
    'Jangan malu kalau harus periksa kesehatan, itu tanda peduli diri!',
    'Etika batuk yang benar membantu melindungi orang lain.',
    'Dengan pengobatan yang tepat, TBC pasti bisa sembuh!',
  ];

  // Get snake messages
  List<String> get snakeMessages => _snakeMessages.isNotEmpty ? _snakeMessages : _defaultSnakeMessages;
  
  // Get ladder messages
  List<String> get ladderMessages => _ladderMessages.isNotEmpty ? _ladderMessages : _defaultLadderMessages;
  
  // Get facts
  List<String> get facts => _facts.isNotEmpty ? _facts : _defaultFacts;

  // Load content from API or cache
  Future<void> loadContent({bool forceRefresh = false}) async {
    if (_isLoaded && !forceRefresh) {
      print('📚 Content already loaded');
      return;
    }

    // Check if cache is still valid
    if (!forceRefresh && await _isCacheValid()) {
      print('📦 Loading content from cache');
      await _loadFromCache();
      _isLoaded = true;
      return;
    }

    // Try to load from API
    try {
      print('🌐 Loading content from API');
      final result = await _apiService.getAllContent();
      
      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        
        _snakeMessages = List<String>.from(data['snakeMessages'] ?? []);
        _ladderMessages = List<String>.from(data['ladderMessages'] ?? []);
        _facts = List<String>.from(data['facts'] ?? []);
        
        // Save to cache
        await _saveToCache();
        _isLoaded = true;
        
        print('✅ Content loaded from API: ${_snakeMessages.length} snakes, ${_ladderMessages.length} ladders, ${_facts.length} facts');
      } else {
        // Fallback to cache or defaults
        print('⚠️ API returned no data, using cache/defaults');
        await _loadFromCache();
        _isLoaded = true;
      }
    } catch (e) {
      print('❌ Error loading content from API: $e');
      // Fallback to cache
      await _loadFromCache();
      _isLoaded = true;
    }
  }

  // Check if cache is still valid
  Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(_cacheKeyTimestamp);
      
      if (timestampStr == null) return false;
      
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();
      
      return now.difference(timestamp) < _cacheDuration;
    } catch (e) {
      print('⚠️ Error checking cache validity: $e');
      return false;
    }
  }

  // Load content from cache
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final snakesJson = prefs.getString(_cacheKeySnakeMessages);
      final laddersJson = prefs.getString(_cacheKeyLadderMessages);
      final factsJson = prefs.getString(_cacheKeyFacts);
      
      if (snakesJson != null) {
        _snakeMessages = List<String>.from(jsonDecode(snakesJson));
      }
      
      if (laddersJson != null) {
        _ladderMessages = List<String>.from(jsonDecode(laddersJson));
      }
      
      if (factsJson != null) {
        _facts = List<String>.from(jsonDecode(factsJson));
      }
      
      print('📦 Loaded from cache: ${_snakeMessages.length} snakes, ${_ladderMessages.length} ladders, ${_facts.length} facts');
    } catch (e) {
      print('⚠️ Error loading from cache: $e');
      // Use defaults if cache fails
      _snakeMessages = List.from(_defaultSnakeMessages);
      _ladderMessages = List.from(_defaultLadderMessages);
      _facts = List.from(_defaultFacts);
    }
  }

  // Save content to cache
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(_cacheKeySnakeMessages, jsonEncode(_snakeMessages));
      await prefs.setString(_cacheKeyLadderMessages, jsonEncode(_ladderMessages));
      await prefs.setString(_cacheKeyFacts, jsonEncode(_facts));
      await prefs.setString(_cacheKeyTimestamp, DateTime.now().toIso8601String());
      
      print('💾 Content saved to cache');
    } catch (e) {
      print('⚠️ Error saving to cache: $e');
    }
  }

  // Clear cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_cacheKeySnakeMessages);
      await prefs.remove(_cacheKeyLadderMessages);
      await prefs.remove(_cacheKeyFacts);
      await prefs.remove(_cacheKeyTimestamp);
      
      _snakeMessages = [];
      _ladderMessages = [];
      _facts = [];
      _isLoaded = false;
      
      print('🗑️ Content cache cleared');
    } catch (e) {
      print('⚠️ Error clearing cache: $e');
    }
  }

  // Refresh content from API
  Future<void> refreshContent() async {
    await loadContent(forceRefresh: true);
  }
}
