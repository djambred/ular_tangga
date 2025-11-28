import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../models/player.dart';
import '../services/api_service.dart';
import '../services/content_service.dart';

class GameScreen extends StatefulWidget {
  final int requiredQuizzes;
  final bool isSinglePlayer;
  final Map<String, dynamic>? roomData;
  final int level;
  final String mode;
  
  const GameScreen({
    Key? key, 
    this.requiredQuizzes = 5,
    this.isSinglePlayer = true,
    this.roomData,
    this.level = 1,
    this.mode = 'single',
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final int boardSize = 100;
  late List<Player> players;
  int? diceValue;
  bool isRolling = false;
  String infoMessage = '';
  bool showInfo = false;
  Player? winner;
  int moveCount = 0;
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;

  // Dynamic snakes positions (di-generate random setiap permainan)
  late Map<int, int> snakesPositions;
  
  // Dynamic ladders positions (di-generate random setiap permainan)
  late Map<int, int> laddersPositions;

  // Dynamic quiz positions (di-generate random setiap permainan)
  late Set<int> quizPositions;

  // Track quiz yang sudah diselesaikan
  Set<int> completedQuizzes = {};
  
  // Jumlah kuis yang diperlukan sesuai level
  late int requiredQuizCount;
  
  // Timer untuk game
  late int gameDurationSeconds;
  late int remainingSeconds;
  Timer? gameTimer;
  bool isTimeUp = false;

  // Content service for dynamic messages
  final ContentService _contentService = ContentService();
  
  // Content will be loaded from backend/cache
  List<String> get snakeMessages => _contentService.snakeMessages;
  List<String> get ladderMessages => _contentService.ladderMessages;
  List<String> get tbFacts => _contentService.facts;

  // Icon untuk notifikasi positif (tangga)
  final List<IconData> positiveIcons = [
    Icons.check_circle_rounded,
    Icons.verified_rounded,
    Icons.thumb_up_rounded,
    Icons.favorite_rounded,
    Icons.star_rounded,
    Icons.lightbulb_rounded,
  ];

  // Icon untuk notifikasi negatif (ular)
  final List<IconData> negativeIcons = [
    Icons.warning_rounded,
    Icons.dangerous_rounded,
    Icons.close_rounded,
    Icons.error_rounded,
    Icons.report_rounded,
    Icons.highlight_off_rounded,
  ];

  // Icon untuk notifikasi fakta
  final List<IconData> factIcons = [
    Icons.info_rounded,
    Icons.lightbulb_rounded,
    Icons.school_rounded,
    Icons.psychology_rounded,
    Icons.auto_awesome_rounded,
    Icons.wb_incandescent_rounded,
  ];

  // Daftar pertanyaan kuis TBC dengan jawaban
  final List<Map<String, dynamic>> tbQuestions = [
    {
      'question': 'Apa kepanjangan dari TBC?',
      'options': ['Tuberkulosis', 'Tifus Bakteri Cepat', 'Tipus Berbahaya', 'Tumor Berat Cepat'],
      'correct': 0,
      'explanation': 'TBC adalah singkatan dari Tuberkulosis, penyakit menular yang disebabkan oleh bakteri Mycobacterium tuberculosis.'
    },
    {
      'question': 'Bagaimana TBC menular?',
      'options': ['Lewat makanan', 'Lewat udara', 'Lewat air', 'Lewat gigitan nyamuk'],
      'correct': 1,
      'explanation': 'TBC menular melalui udara ketika penderita batuk atau bersin dan mengeluarkan droplet yang mengandung bakteri.'
    },
    {
      'question': 'Berapa lama pengobatan TBC minimal?',
      'options': ['1 bulan', '3 bulan', '6 bulan', '1 tahun'],
      'correct': 2,
      'explanation': 'Pengobatan TBC minimal 6 bulan dan harus dilakukan secara teratur tanpa putus agar bakteri mati sempurna.'
    },
    {
      'question': 'Apa gejala utama TBC?',
      'options': ['Demam tinggi', 'Batuk lebih dari 2 minggu', 'Sakit kepala', 'Mual muntah'],
      'correct': 1,
      'explanation': 'Batuk yang berlangsung lebih dari 2 minggu adalah gejala utama TBC yang harus diwaspadai.'
    },
    {
      'question': 'Apakah obat TBC gratis di Indonesia?',
      'options': ['Ya, gratis di Puskesmas', 'Tidak, harus beli sendiri', 'Hanya gratis untuk anak', 'Gratis tapi harus bayar administrasi'],
      'correct': 0,
      'explanation': 'Obat TBC diberikan gratis di Puskesmas dan rumah sakit pemerintah di seluruh Indonesia.'
    },
    {
      'question': 'Apa yang terjadi jika berhenti minum obat TBC sebelum waktunya?',
      'options': ['Langsung sembuh', 'Tidak apa-apa', 'Kuman jadi kebal', 'Batuknya berkurang'],
      'correct': 2,
      'explanation': 'Jika berhenti minum obat sebelum waktunya, kuman TBC bisa menjadi kebal terhadap obat (resisten).'
    },
    {
      'question': 'Organ tubuh apa yang paling sering diserang TBC?',
      'options': ['Hati', 'Paru-paru', 'Ginjal', 'Jantung'],
      'correct': 1,
      'explanation': 'Paru-paru adalah organ yang paling sering diserang oleh bakteri TBC, meski TBC bisa menyerang organ lain.'
    },
    {
      'question': 'Apa yang bisa mencegah TBC pada bayi?',
      'options': ['Imunisasi Polio', 'Imunisasi BCG', 'Imunisasi Campak', 'Imunisasi DPT'],
      'correct': 1,
      'explanation': 'Imunisasi BCG diberikan pada bayi untuk melindungi dari penyakit TBC berat.'
    },
    {
      'question': 'Apakah TBC bisa menular lewat pelukan?',
      'options': ['Ya, sangat menular', 'Tidak bisa menular', 'Hanya pada anak', 'Tergantung cuaca'],
      'correct': 1,
      'explanation': 'TBC tidak menular melalui pelukan, jabat tangan, atau berbagi alat makan. TBC hanya menular lewat udara.'
    },
    {
      'question': 'Apa yang harus dilakukan jika batuk lebih dari 2 minggu?',
      'options': ['Beli obat warung', 'Minum air hangat saja', 'Periksa ke dokter', 'Diamkan saja'],
      'correct': 2,
      'explanation': 'Jika batuk lebih dari 2 minggu, segera periksa ke dokter atau Puskesmas untuk pemeriksaan TBC.'
    },
  ];

  final ApiService _apiService = ApiService();
  bool _isLoadingBoard = true;

  @override
  void initState() {
    super.initState();
    requiredQuizCount = widget.requiredQuizzes;
    
    // Set random duration 5-7 menit
    final random = Random();
    gameDurationSeconds = 300 + random.nextInt(121); // 300-420 detik (5-7 menit)
    remainingSeconds = gameDurationSeconds;
    
    _initPlayers();
    _loadContent();
    _loadBoardConfig();
    _startTimer();
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _bounceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  void _startTimer() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (remainingSeconds > 0) {
            remainingSeconds--;
          } else {
            isTimeUp = true;
            timer.cancel();
            _showTimeUpDialog();
          }
        });
      }
    });
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _initPlayers() {
    players = [
      Player(id: 1, name: 'Pemain', color: Colors.blue),
    ];
  }

  Future<void> _loadContent() async {
    try {
      print('📚 Loading educational content...');
      await _contentService.loadContent();
      print('✅ Content loaded: ${snakeMessages.length} snakes, ${ladderMessages.length} ladders, ${tbFacts.length} facts');
    } catch (e) {
      print('⚠️ Failed to load content: $e');
      // Content service will use defaults
    }
  }

  Future<void> _loadBoardConfig() async {
    // Check if user is logged in
    final isLoggedIn = await _apiService.isLoggedIn();
    
    // Guest users: use random generation
    if (!isLoggedIn) {
      print('Guest user detected, using random board generation');
      _generateRandomSnakesAndLadders();
      return;
    }
    
    // Logged-in users: try to load from backend
    try {
      final config = await _apiService.getBoardConfig(widget.requiredQuizzes);
      
      if (config['success'] && config['data'] != null) {
        final boardData = config['data'];
        
        // Load snakes from backend
        snakesPositions = {};
        for (var snake in boardData['snakes']) {
          snakesPositions[snake['start']] = snake['end'];
        }
        
        // Load ladders from backend
        laddersPositions = {};
        for (var ladder in boardData['ladders']) {
          laddersPositions[ladder['start']] = ladder['end'];
        }
        
        // Load quiz positions from backend
        quizPositions = {};
        for (var quizPos in boardData['quizPositions']) {
          quizPositions.add(quizPos['position']);
        }
        
        setState(() {
          _isLoadingBoard = false;
        });
      } else {
        // Fallback to random generation if API fails
        print('API returned unsuccessful, using random generation');
        _generateRandomSnakesAndLadders();
      }
    } catch (e) {
      print('Error loading board config: $e');
      // Fallback to random generation
      _generateRandomSnakesAndLadders();
    }
  }

  Future<void> _saveGameHistory({required bool isWinner}) async {
    try {
      final playTime = gameDurationSeconds - remainingSeconds;
      
      // Get current player position
      final playerPosition = players.isNotEmpty ? players[0].position : 0;
      
      // Calculate score based on performance
      int score = 0;
      if (isWinner) {
        // Base score for winning
        score = 1000;
        // Bonus for completing quizzes
        score += completedQuizzes.length * 100;
        // Bonus for time remaining (up to 500 points)
        score += (remainingSeconds * 500 / gameDurationSeconds).round();
        // Bonus for fewer moves (efficiency)
        if (moveCount > 0) {
          score += (1000 / moveCount).round();
        }
      } else {
        // Partial score for not winning
        // Base on progress and quizzes completed
        score = (playerPosition * 10) + (completedQuizzes.length * 50);
      }
      
      print('💾 Game Stats:');
      print('   Winner: $isWinner');
      print('   Level: ${widget.level}');
      print('   Position: $playerPosition/$boardSize');
      print('   Quizzes: ${completedQuizzes.length}');
      print('   Time: $playTime seconds');
      print('   Moves: $moveCount');
      print('   Score: $score');
      
      // Validation
      if (!isWinner) {
        print('⚠️ Player did not win, will not unlock level');
      } else {
        print('✅ Player won! Should unlock level: ${widget.level + 1}');
      }
      
      // Check if user is logged in
      final isLoggedIn = await _apiService.isLoggedIn();
      if (!isLoggedIn) {
        print('❌ User not logged in, game history not saved');
        return;
      }
      
      // Get user profile
      final profile = await _apiService.getProfile();
      if (profile['success'] != true || profile['data'] == null) {
        print('❌ Failed to get user profile');
        return;
      }
      
      final userData = profile['data'] as Map<String, dynamic>;
      final userId = userData['_id'] ?? userData['id'];
      
      if (userId == null) {
        print('❌ No userId found in profile');
        return;
      }
      
      // Prepare game history data
      final Map<String, dynamic> gameData = {
        'gameMode': widget.mode, // Use actual mode: 'single' or 'multiplayer'
        'level': widget.level,  // Use actual level number
        'players': [
          {
            'userId': userId,
            'username': userData['username'],
            'finalPosition': playerPosition,
            'quizzesAnswered': completedQuizzes.length,
            'quizzesCorrect': completedQuizzes.length,
            'isWinner': isWinner,
            'playTime': playTime,
            'score': score,
          }
        ],
        'quizzes': completedQuizzes.toList(),
        'duration': playTime,
      };
      
      print('📤 Saving game history: $gameData');
      print('📤 Will trigger level unlock to ${widget.level + 1} if win');
      
      // Save to backend
      final result = await _apiService.saveGameHistory(gameData);
      if (result['success'] == true) {
        print('✅ Game history saved successfully');
        print('   Mode: ${gameData['gameMode']}, Level: ${gameData['level']}, Score: $score');
        if (isWinner) {
          print('   ✅ Level ${widget.level + 1} should now be unlocked!');
        }
      } else {
        print('❌ Failed to save game history: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error saving game history: $e');
      rethrow; // Let caller handle the error
    }
  }

  void _generateRandomSnakesAndLadders() {
  setState(() {
    snakesPositions = {};
    laddersPositions = {};
    quizPositions = {};
  });
  
  final random = Random();

  const int minDistance = 2;           // Jarak minimal antar ular/tangga/kuis (dikurangi untuk gameplay lebih cepat)
  const int maxLadderHeight = 25;      // Tinggi maksimal tangga (ditingkatkan untuk mempercepat)

  bool isForbidden(int pos) {
    if (pos == 1 || pos == boardSize) return true; // 1 dan 100 terlarang
    if (pos % 5 == 0) return true;                 // Kelipatan 5 terlarang
    return false;
  }

  bool isSnakeTooClose(int start) {
    for (var s in snakesPositions.keys) {
      if ((s - start).abs() < minDistance) return true;
    }
    return false;
  }

  bool isLadderTooClose(int start) {
    for (var l in laddersPositions.keys) {
      if ((l - start).abs() < minDistance) return true;
    }
    return false;
  }

  bool isQuizTooClose(int start) {
    for (var q in quizPositions) {
      if ((q - start).abs() < minDistance) return true;
    }
    return false;
  }

  // ==============================
  // Generate 10 Ular
  // ==============================
  for (int i = 0; i < 10; i++) {
    int startPos;

    do {
      startPos = random.nextInt(boardSize - 20) + 21; // 21–80
    } while (
      snakesPositions.containsKey(startPos) ||
      laddersPositions.containsKey(startPos) ||
      quizPositions.contains(startPos) ||
      isForbidden(startPos) ||
      isSnakeTooClose(startPos)
    );

    int endPos;
    do {
      endPos = random.nextInt(startPos - 10) + 1; // Minimal beda 10
    } while (isForbidden(endPos));

    snakesPositions[startPos] = endPos;
  }

  // ==============================
  // Generate 10 Tangga
  // ==============================
  for (int i = 0; i < 10; i++) {
    int startPos;

    do {
      startPos = random.nextInt(boardSize - 20) + 1; // 1–80
    } while (
      laddersPositions.containsKey(startPos) ||
      snakesPositions.containsKey(startPos) ||
      quizPositions.contains(startPos) ||
      isForbidden(startPos) ||
      isLadderTooClose(startPos)
    );

    int endPos;

    do {
      endPos = startPos +
          random.nextInt(boardSize - startPos - 10) + 10; // Minimal +10

      // Batasi tinggi tangga
      if (endPos - startPos > maxLadderHeight) {
        endPos = startPos + maxLadderHeight;
      }

      if (endPos > boardSize - 1) endPos = boardSize - 1;

    } while (isForbidden(endPos));

    laddersPositions[startPos] = endPos;
  }

  // ==============================
  // Generate Quiz Positions (selalu 10 quiz di board)
  // ==============================
  for (int i = 0; i < 10; i++) {
    int quizPos;

    do {
      quizPos = random.nextInt(boardSize - 20) + 10; // 10–80
    } while (
      laddersPositions.containsKey(quizPos) ||
      snakesPositions.containsKey(quizPos) ||
      quizPositions.contains(quizPos) ||
      isForbidden(quizPos) ||
      isQuizTooClose(quizPos)
    );

    quizPositions.add(quizPos);
  }
  
  // Set loading selesai
  setState(() {
    _isLoadingBoard = false;
  });
}


  void _rollDice() async {
    if (isRolling || winner != null || isTimeUp) return;

    setState(() {
      isRolling = true;
      showInfo = false;
      moveCount++;
    });

    // Hasil dadu langsung
    final finalValue = Random().nextInt(3) + 4;
    
    setState(() {
      diceValue = finalValue;
    });

    // Tampilkan popup hasil dadu
    _showDiceResultDialog(finalValue);
  }

  void _showDiceResultDialog(int diceResult) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 24,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade50, Colors.purple.shade50],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blue.shade300,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.purple.shade400],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.casino_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'HASIL DADU',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.orange.shade400, Colors.red.shade400],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$diceResult',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _bounceController.forward(from: 0);
                      _movePlayer(diceResult);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 8,
                      shadowColor: Colors.green.withOpacity(0.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'JALANKAN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _movePlayer(int steps) async {
    final player = players[0];
    final startPosition = player.position;
    int targetPosition = startPosition + steps;

    if (targetPosition > boardSize) {
      targetPosition = boardSize;
    }

    // Animasi jalan kotak per kotak
    for (int i = 1; i <= (targetPosition - startPosition); i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        player.position = startPosition + i;
      });
    }

    await Future.delayed(const Duration(milliseconds: 100));

    // Gunakan targetPosition untuk pengecekan
    final finalPosition = player.position;

    // Cek apakah menang
    if (finalPosition == boardSize) {
      // Cek apakah kuis sesuai level sudah diselesaikan
      if (completedQuizzes.length >= requiredQuizCount) {
        setState(() {
          winner = player;
          isRolling = false;
        });
        _showWinDialog();
        return;
      } else {
        // Belum menyelesaikan semua kuis - kembali ke posisi sebelumnya
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          player.position = startPosition; // Kembali ke posisi awal
          isRolling = false;
        });
        _showIncompleteQuizDialog();
        return;
      }
    }

    // Cek tangga
    if (laddersPositions.containsKey(finalPosition)) {
      await Future.delayed(const Duration(milliseconds: 500));
      final newPosition = laddersPositions[finalPosition]!;
      setState(() {
        player.position = newPosition;
      });

      if (player.position == boardSize) {
        // Cek apakah kuis sesuai level sudah diselesaikan
        if (completedQuizzes.length >= requiredQuizCount) {
          setState(() {
            winner = player;
            isRolling = false;
          });
          _showLadderWinDialog();
          return;
        } else {
          // Belum menyelesaikan kuis sesuai level - kembali ke bawah tangga
          await Future.delayed(const Duration(milliseconds: 500));
          setState(() {
            player.position = finalPosition; // Kembali ke posisi sebelum naik tangga
            isRolling = false;
          });
          _showIncompleteQuizDialog();
          return;
        }
      }

      // Tampilkan popup untuk tangga dengan message random
      _showEducationDialog(
        title: 'PERILAKU BAIK TERKAIT TBC!',
        message: ladderMessages[Random().nextInt(ladderMessages.length)],
        subtitle: 'Naik ke kotak ${player.position}!',
        isPositive: true,
      );
    }
    // Cek ular
    else if (snakesPositions.containsKey(finalPosition)) {
      await Future.delayed(const Duration(milliseconds: 500));
      final newPosition = snakesPositions[finalPosition]!;
      setState(() {
        player.position = newPosition;
      });

      // Tampilkan popup untuk ular dengan message random
      _showEducationDialog(
        title: 'PERILAKU BURUK TERKAIT TBC!',
        message: snakeMessages[Random().nextInt(snakeMessages.length)],
        subtitle: 'Turun ke kotak ${player.position}',
        isPositive: false,
      );
    }
    // Cek kuis
    else if (quizPositions.contains(finalPosition)) {
      await Future.delayed(const Duration(milliseconds: 500));
      // Cek apakah kuis di posisi ini sudah diselesaikan
      if (!completedQuizzes.contains(finalPosition)) {
        // Tampilkan kuis
        final question = tbQuestions[Random().nextInt(tbQuestions.length)];
        _showQuizDialog(question, finalPosition);
      } else {
        // Kuis sudah diselesaikan, tampilkan fakta
        _showEducationDialog(
          title: 'KUIS SUDAH DISELESAIKAN!',
          message: 'Kamu sudah menjawab pertanyaan di kotak ini. ${tbFacts[Random().nextInt(tbFacts.length)]}',
          subtitle: '',
          isPositive: true,
          isFact: true,
        );
      }
    }
    // Tampilkan fakta edukatif
    else {
      _showEducationDialog(
        title: 'FAKTA PENTING TERKAIT TBC!',
        message: tbFacts[Random().nextInt(tbFacts.length)],
        subtitle: '',
        isPositive: true,
        isFact: true,
      );
    }

    // Set isRolling = false setelah dialog ditutup
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      isRolling = false;
    });
  }

  void _showEducationDialog({
    required String title,
    required String message,
    required String subtitle,
    required bool isPositive,
    bool isFact = false,
  }) {
    // Pilih icon random berdasarkan tipe notifikasi
    final randomIcon = isFact
        ? factIcons[Random().nextInt(factIcons.length)]
        : isPositive
            ? positiveIcons[Random().nextInt(positiveIcons.length)]
            : negativeIcons[Random().nextInt(negativeIcons.length)];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 24,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isFact
                    ? [Colors.blue.shade50, Colors.blue.shade100]
                    : isPositive
                        ? [Colors.green.shade50, Colors.green.shade100]
                        : [Colors.orange.shade50, Colors.orange.shade100],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isFact
                    ? Colors.blue.shade300
                    : isPositive
                        ? Colors.green.shade300
                        : Colors.orange.shade300,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isFact
                          ? Colors.blue
                          : isPositive
                              ? Colors.green
                              : Colors.orange)
                      .withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon di atas dengan animasi bounce
                ScaleTransition(
                  scale: _bounceAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isFact
                            ? [Colors.blue.shade400, Colors.blue.shade600]
                            : isPositive
                                ? [Colors.green.shade400, Colors.green.shade600]
                                : [Colors.orange.shade400, Colors.orange.shade600],
                      ),
                    ),
                    child: Icon(
                      randomIcon,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Judul
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isFact
                        ? Colors.blue.shade800
                        : isPositive
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Pesan utama
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFact
                          ? Colors.blue.shade200
                          : isPositive
                              ? Colors.green.shade200
                              : Colors.orange.shade200,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),

                // Tombol lanjut
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFact
                          ? Colors.blue.shade600
                          : isPositive
                              ? Colors.green.shade600
                              : Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 8,
                      shadowColor: (isFact
                              ? Colors.blue
                              : isPositive
                                  ? Colors.green
                                  : Colors.orange)
                          .withOpacity(0.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'LANJUTKAN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQuizDialog(Map<String, dynamic> question, int position) {
    int? selectedAnswer;
    bool answered = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 24,
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: answered
                        ? (selectedAnswer == question['correct']
                            ? [Colors.green.shade50, Colors.green.shade100]
                            : [Colors.red.shade50, Colors.red.shade100])
                        : [Colors.purple.shade50, Colors.purple.shade100],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: answered
                        ? (selectedAnswer == question['correct']
                            ? Colors.green.shade300
                            : Colors.red.shade300)
                        : Colors.purple.shade300,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (answered
                              ? (selectedAnswer == question['correct']
                                  ? Colors.green
                                  : Colors.red)
                              : Colors.purple)
                          .withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: answered
                              ? (selectedAnswer == question['correct']
                                  ? [Colors.green.shade400, Colors.green.shade600]
                                  : [Colors.red.shade400, Colors.red.shade600])
                              : [Colors.purple.shade400, Colors.purple.shade600],
                        ),
                      ),
                      child: Icon(
                        answered
                            ? (selectedAnswer == question['correct']
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded)
                            : Icons.quiz_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Judul
                    Text(
                      answered
                          ? (selectedAnswer == question['correct']
                              ? '✓ BENAR!'
                              : '✗ SALAH!')
                          : 'PERTANYAAN KUIS TBC',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: answered
                            ? (selectedAnswer == question['correct']
                                ? Colors.green.shade800
                                : Colors.red.shade800)
                            : Colors.purple.shade800,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Pertanyaan
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.purple.shade200,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        question['question'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pilihan jawaban
                    ...List.generate(
                      question['options'].length,
                      (index) {
                        final isCorrect = index == question['correct'];
                        final isSelected = selectedAnswer == index;
                        
                        Color buttonColor;
                        if (answered) {
                          if (isCorrect) {
                            buttonColor = Colors.green.shade400;
                          } else if (isSelected) {
                            buttonColor = Colors.red.shade400;
                          } else {
                            buttonColor = Colors.grey.shade300;
                          }
                        } else {
                          buttonColor = isSelected
                              ? Colors.purple.shade300
                              : Colors.grey.shade200;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: answered
                                ? null
                                : () {
                                    setDialogState(() {
                                      selectedAnswer = index;
                                    });
                                  },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: buttonColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? (answered
                                          ? (isCorrect
                                              ? Colors.green.shade600
                                              : Colors.red.shade600)
                                          : Colors.purple.shade600)
                                      : Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + index),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      question['options'][index],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                  if (answered && isCorrect)
                                    Icon(Icons.check_circle,
                                        color: Colors.green.shade700, size: 20),
                                  if (answered && isSelected && !isCorrect)
                                    Icon(Icons.cancel,
                                        color: Colors.red.shade700, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Penjelasan (tampil setelah dijawab)
                    if (answered) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                question['explanation'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade800,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Tombol
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: selectedAnswer == null
                            ? null
                            : () {
                                if (!answered) {
                                  setDialogState(() {
                                    answered = true;
                                  });
                                } else {
                                  // Tandai kuis sebagai selesai
                                  setState(() {
                                    completedQuizzes.add(position);
                                  });
                                  Navigator.of(context).pop();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: answered
                              ? (selectedAnswer == question['correct']
                                  ? Colors.green.shade600
                                  : Colors.red.shade600)
                              : Colors.purple.shade600,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              answered ? Icons.check_rounded : Icons.send_rounded,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              answered ? 'LANJUTKAN' : 'JAWAB',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTimeUpDialog() {
    gameTimer?.cancel();
    
    // Save game history (not a winner)
    _saveGameHistory(isWinner: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 24,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.red.shade50, Colors.red.shade100],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.red.shade300,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                    ),
                  ),
                  child: const Icon(
                    Icons.timer_off_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'WAKTU HABIS!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.shade200,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Permainan selesai!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Kuis diselesaikan: ${completedQuizzes.length}/10 (wajib: $requiredQuizCount)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'Posisi: ${players[0].position}/$boardSize',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(true); // Return with refresh signal
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 8,
                      shadowColor: Colors.red.withOpacity(0.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_rounded, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'KEMBALI KE MENU',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _showIncompleteQuizDialog() {
    final remaining = requiredQuizCount - completedQuizzes.length;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 24,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.orange.shade50, Colors.orange.shade100],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.orange.shade300,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'BELUM BISA MENANG!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Kamu harus menyelesaikan minimal $requiredQuizCount dari 10 kuis!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.purple.shade300,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.quiz_rounded, color: Colors.purple.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Kuis tersisa: $remaining',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cari kotak ungu dengan icon kuis!',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 8,
                      shadowColor: Colors.orange.withOpacity(0.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cancel_rounded, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'KEMBALI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWinDialog() {
    gameTimer?.cancel();
    
    // Save game history and wait for completion
    _saveGameHistory(isWinner: true).then((_) {
      // Notify that data should be refreshed
      print('💾 Game saved, level should be unlocked now');
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 24,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.amber.shade50, Colors.green.shade100],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.green.shade400,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.amber.shade600],
                    ),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '🎉 SELAMAT! 🎉',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Kamu sudah paham cara\nmencegah dan mengobati TBC!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '🏆 Total Langkah: $moveCount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                // Lanjut ke level berikutnya
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Lanjut ke level berikutnya jika belum maksimal
                      if (widget.level < 10) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => GameScreen(
                              level: widget.level + 1,
                              mode: widget.mode,
                            ),
                          ),
                        );
                      } else {
                        // Sudah level maksimal, kembali ke home
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_forward_rounded, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          widget.level < 10 ? 'LANJUT LEVEL ${widget.level + 1}' : 'SELESAI',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Keluar ke home
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(true); // Return with refresh signal
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade400, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_rounded, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'KEMBALI KE HOME',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLadderWinDialog() {
    gameTimer?.cancel();
    
    // Save game history (won by ladder) and wait for completion
    _saveGameHistory(isWinner: true).then((_) {
      print('💾 Game saved via ladder win, level should be unlocked now');
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 24,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade50, Colors.green.shade100],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.green.shade400,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '✨ SEMPURNA! ✨',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Menang melalui tangga!\n\nKamu sudah mempelajari\nperilaku kesehatan yang baik!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '🏆 Total Langkah: $moveCount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                // Lanjut ke level berikutnya
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Lanjut ke level berikutnya jika belum maksimal
                      if (widget.level < 10) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => GameScreen(
                              level: widget.level + 1,
                              mode: widget.mode,
                            ),
                          ),
                        );
                      } else {
                        // Sudah level maksimal, kembali ke home
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_forward_rounded, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          widget.level < 10 ? 'LANJUT LEVEL ${widget.level + 1}' : 'SELESAI',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Keluar ke home
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(true); // Return with refresh signal
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade400, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_rounded, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'KEMBALI KE HOME',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _resetGame() {
    gameTimer?.cancel();
    
    setState(() {
      _initPlayers();
      _generateRandomSnakesAndLadders();
      diceValue = null;
      showInfo = false;
      winner = null;
      infoMessage = '';
      isRolling = false;
      moveCount = 0;
      completedQuizzes.clear();
      isTimeUp = false;
      
      // Reset timer dengan durasi random baru
      final random = Random();
      gameDurationSeconds = 300 + random.nextInt(121);
      remainingSeconds = gameDurationSeconds;
    });
    
    _startTimer();
  }

  Future<void> _handleExit() async {
    // Pause the game timer during dialog
    final wasPaused = isTimeUp;
    gameTimer?.cancel();
    
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 24,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.orange.shade50, Colors.red.shade50],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.orange.shade300,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.red.shade400],
                    ),
                  ),
                  child: const Icon(
                    Icons.exit_to_app_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'KELUAR DARI GAME?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Keluar sekarang akan dihitung sebagai kekalahan dan mempengaruhi statistik kamu.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Icon(Icons.my_location, color: Colors.blue.shade700, size: 20),
                              const SizedBox(height: 4),
                              Text(
                                'Posisi: ${players[0].position}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(Icons.quiz, color: Colors.purple.shade700, size: 20),
                              const SizedBox(height: 4),
                              Text(
                                'Kuis: ${completedQuizzes.length}/10',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade400, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'LANJUTKAN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 8,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'KELUAR',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldExit == true) {
      // Save game as loss before exiting
      await _saveGameHistory(isWinner: false);
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return with refresh signal
      }
    } else {
      // Resume timer if not exiting and game not over
      if (!wasPaused && !isTimeUp && winner == null) {
        _startTimer();
      }
    }
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = (constraints.maxWidth - 20) / 10;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 10,
            crossAxisSpacing: 1.5,
            mainAxisSpacing: 1.5,
            childAspectRatio: 1,
          ),
          itemCount: boardSize,
          itemBuilder: (context, index) {
            final actualIndex = boardSize - index;
            final row = index ~/ 10;
            final isReversed = row % 2 != 0;
            
            int position;
            if (isReversed) {
              position = boardSize - (row * 10) - (9 - (index % 10));
            } else {
              position = actualIndex;
            }

            final isSnake = snakesPositions.containsKey(position);
            final isLadder = laddersPositions.containsKey(position);
            final isQuiz = quizPositions.contains(position);
            final isFinish = position == boardSize;
            final isStart = position == 1;
            final playerHere = players[0].position == position;

            Color bgColor = Colors.white;
            Color borderColor = Colors.grey.shade300;
            
            if (isSnake) {
              bgColor = Colors.red.shade50;
              borderColor = Colors.red.shade200;
            }
            if (isLadder) {
              bgColor = Colors.green.shade50;
              borderColor = Colors.green.shade200;
            }
            if (isQuiz) {
              bgColor = Colors.purple.shade50;
              borderColor = Colors.purple.shade200;
            }
            if (isFinish) {
              bgColor = Colors.amber.shade100;
              borderColor = Colors.amber.shade400;
            }
            if (isStart) {
              bgColor = Colors.blue.shade50;
              borderColor = Colors.blue.shade300;
            }

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: playerHere
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade200,
                          Colors.blue.shade400,
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [bgColor, bgColor],
                      ),
                border: Border.all(
                  color: playerHere ? Colors.blue.shade700 : borderColor,
                  width: playerHere ? 2.5 : 1,
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: playerHere
                    ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.6),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                        )
                      ],
              ),
              child: Stack(
                children: [
                  // Nomor kotak (tidak tampilkan untuk posisi 1 dan 100)
                  if (position != 1 && position != boardSize)
                    Positioned(
                      top: 2,
                      left: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          color: playerHere 
                              ? Colors.white.withOpacity(0.9) 
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$position',
                          style: TextStyle(
                            fontSize: cellSize * 0.22,
                            color: playerHere ? Colors.blue.shade900 : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  // Icon center
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSnake)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.trending_down_rounded,
                              color: Colors.red.shade700,
                              size: cellSize * 0.45,
                            ),
                          ),
                        if (isLadder)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.trending_up_rounded,
                              color: Colors.green.shade700,
                              size: cellSize * 0.45,
                            ),
                          ),
                        if (isQuiz)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.quiz_rounded,
                              color: Colors.purple.shade700,
                              size: cellSize * 0.45,
                            ),
                          ),
                        if (isFinish)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.amber.shade800,
                              size: cellSize * 0.5,
                            ),
                          ),
                        if (isStart)
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.blue.shade700,
                              size: cellSize * 0.45,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Player position
                  if (playerHere)
                    Center(
                      child: ScaleTransition(
                        scale: _bounceAnimation,
                        child: Container(
                          width: cellSize * 0.65,
                          height: cellSize * 0.65,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Colors.blue.shade100,
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.blue.shade700,
                            size: cellSize * 0.4,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while fetching board configuration
    if (_isLoadingBoard) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade600,
                Colors.blue.shade400,
                Colors.cyan.shade200,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 4,
                ),
                const SizedBox(height: 24),
                Text(
                  'Memuat konfigurasi papan...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade600,
              Colors.blue.shade400,
              Colors.cyan.shade200,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header dengan glassmorphism effect
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Exit Button
                        IconButton(
                          onPressed: _handleExit,
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.red.shade700,
                          tooltip: 'Keluar',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.videogame_asset, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ular Tangga TBC',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'Game Edukasi Kesehatan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the exit button
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatChip(
                          icon: Icons.timer_rounded,
                          label: _formatTime(remainingSeconds),
                          color: remainingSeconds < 60 ? Colors.red : Colors.purple,
                        ),
                        _buildStatChip(
                          icon: Icons.my_location_rounded,
                          label: '${players[0].position}/$boardSize',
                          color: Colors.blue,
                        ),
                        _buildStatChip(
                          icon: Icons.quiz_rounded,
                          label: '${completedQuizzes.length}/10',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Info Box dengan animasi
              if (showInfo)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: winner != null
                          ? [Colors.green.shade100, Colors.green.shade200]
                          : [Colors.white, Colors.blue.shade50],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: winner != null ? Colors.green.shade400 : Colors.blue.shade300,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (winner != null ? Colors.green : Colors.blue)
                            .withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    infoMessage,
                    style: TextStyle(
                      color: winner != null ? Colors.green.shade900 : Colors.blue.shade900,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Game Board
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _buildBoard(),
                ),
              ),

              // Bottom Controls
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.9),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: winner == null
                    ? Center(
                        child: GestureDetector(
                          onTap: isRolling ? null : _rollDice,
                          child: ScaleTransition(
                            scale: isRolling ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isRolling
                                      ? [Colors.grey.shade400, Colors.grey.shade600]
                                      : [Colors.blue.shade400, Colors.blue.shade700],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isRolling ? Colors.grey : Colors.blue)
                                        .withOpacity(0.5),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.casino_rounded,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isRolling ? 'TUNGGU...' : 'LEMPAR DADU',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.amber.shade200, Colors.amber.shade400],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'SELAMAT! 🎉',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              foreground: Paint()
                                ..shader = LinearGradient(
                                  colors: [Colors.green.shade600, Colors.green.shade800],
                                ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _resetGame,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 8,
                                shadowColor: Colors.green.withOpacity(0.5),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh_rounded, size: 32),
                                  SizedBox(width: 12),
                                  Text(
                                    'MAIN LAGI',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.shade100, color.shade200],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color.shade800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
