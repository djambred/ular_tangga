import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'mode_selection_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({Key? key}) : super(key: key);

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  final ApiService _apiService = ApiService();
  int selectedLevel = 1;
  int highestLevel = 1; // Highest unlocked level
  bool _isLoading = true;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
  }

  Future<void> _loadUserProgress() async {
    setState(() => _isLoading = true);
    
    try {
      final isLoggedIn = await _apiService.isLoggedIn();
      
      if (isLoggedIn) {
        // Load user profile to get highest level
        final result = await _apiService.getProfile();
        if (result['success'] && result['data'] != null) {
          final userData = result['data'];
          final stats = userData['statistics'] ?? {};
          setState(() {
            highestLevel = stats['highestLevel'] ?? 1;
            selectedLevel = highestLevel;
            _isGuest = false;
            _isLoading = false;
          });
          return;
        }
      }
      
      // Guest mode - all levels unlocked
      setState(() {
        _isGuest = true;
        highestLevel = 5; // Guest can access all levels
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user progress: $e');
      // On error, assume guest mode
      setState(() {
        _isGuest = true;
        highestLevel = 5;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade50,
              Colors.blue.shade50,
              Colors.cyan.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/auth');
                      },
                    ),
                    const Text(
                      'Kembali ke Login',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Header
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade600, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.casino_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'PILIH LEVEL',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isGuest
                          ? 'Mode Guest - Semua level tersedia (tanpa skor)'
                          : 'Level Tertinggi: $highestLevel - Selesaikan untuk unlock level berikutnya',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Level Grid
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.purple.shade200,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      final level = index + 1;
                      final isSelected = selectedLevel == level;
                      final isLocked = !_isGuest && level > highestLevel;
                      
                      return InkWell(
                        onTap: isLocked
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Level $level terkunci! Selesaikan level ${level - 1} terlebih dahulu.',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            : () {
                                setState(() {
                                  selectedLevel = level;
                                });
                              },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: isSelected && !isLocked
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.purple.shade400,
                                      Colors.blue.shade500,
                                    ],
                                  )
                                : null,
                            color: isLocked
                                ? Colors.grey.shade300
                                : (isSelected ? null : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.purple.shade600
                                  : Colors.grey.shade300,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Stack(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isLocked ? Icons.lock : Icons.casino_rounded,
                                    size: 24,
                                    color: isLocked
                                        ? Colors.grey.shade600
                                        : (isSelected
                                            ? Colors.white
                                            : Colors.purple.shade600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$level',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isLocked
                                          ? Colors.grey.shade600
                                          : (isSelected
                                              ? Colors.white
                                              : Colors.grey.shade800),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isLocked ? 'Terkunci' : '$level/10',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isLocked
                                          ? Colors.grey.shade600
                                          : (isSelected
                                              ? Colors.white.withOpacity(0.9)
                                              : Colors.grey.shade600),
                                    ),
                                  ),
                                ],
                              ),
                              if (level == highestLevel && !_isGuest)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Tombol Mulai
              Container(
                margin: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: (!_isGuest && selectedLevel > highestLevel)
                        ? null
                        : () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GameModeSelectionScreen(
                                  selectedLevel: selectedLevel,
                                ),
                              ),
                            );
                            // If returned with refresh signal, reload progress
                            if (result == true && mounted) {
                              await _loadUserProgress();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: Colors.green.withOpacity(0.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 32),
                        SizedBox(width: 8),
                        Text(
                          'MULAI BERMAIN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
