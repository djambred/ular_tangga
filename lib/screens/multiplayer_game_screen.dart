import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../models/player.dart';
import '../services/content_service.dart';
import '../services/socket_service.dart';

class MultiplayerGameScreen extends StatefulWidget {
  final int requiredQuizzes;
  final int level;
  final dynamic roomData; // Socket.io room data
  final bool isSocketBased; // true for real-time multiplayer, false for static 4-player
  
  const MultiplayerGameScreen({
    Key? key, 
    this.requiredQuizzes = 5, 
    this.level = 1,
    this.roomData,
    this.isSocketBased = false,
  }) : super(key: key);

  @override
  State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> with TickerProviderStateMixin {
  final int boardSize = 100;
  late List<Player> players;
  int currentPlayerIndex = 0;
  bool isRolling = false;
  int? diceValue;
  Player? winner;
  int moveCount = 0; // total moves
  Set<int> completedQuizzes = {}; // shared educational progress
  late int requiredQuizCount;

  // Board dynamic items
  late Map<int, int> snakesPositions;
  late Map<int, int> laddersPositions;
  late Set<int> quizPositions;

  // Timer (optional shorter for multiplayer for pacing)
  late int gameDurationSeconds;
  late int remainingSeconds;
  Timer? gameTimer;
  bool isTimeUp = false;

  // Content service for messages/facts
  final ContentService _contentService = ContentService();
  List<String> get snakeMessages => _contentService.snakeMessages;
  List<String> get ladderMessages => _contentService.ladderMessages;
  List<String> get tbFacts => _contentService.facts;

  // Socket service for real-time multiplayer
  final SocketService _socketService = SocketService();
  String? _myPlayerId;
  bool get _isMyTurn => widget.isSocketBased 
      ? (_myPlayerId != null && players.isNotEmpty && players[currentPlayerIndex].id.toString() == _myPlayerId)
      : true; // In static mode, always allow actions

  // Animations
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;

  String infoMessage = '';
  bool showInfo = false;
  bool _isLoadingBoard = true;

  // Kumpulan pertanyaan kuis (reused dari single player)
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

  @override
  void initState() {
    super.initState();
    requiredQuizCount = widget.requiredQuizzes;
    final random = Random();
    gameDurationSeconds = 240 + random.nextInt(121); // 4-6 menit for multiplayer
    remainingSeconds = gameDurationSeconds;
    
    if (widget.isSocketBased && widget.roomData != null) {
      _initSocketPlayers();
      _setupSocketListeners();
    } else {
      _initPlayers();
    }
    
    _loadContent();
    _generateRandomBoard();
    _startTimer();

    _bounceController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut));
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _bounceController.dispose();
    _pulseController.dispose();
    if (widget.isSocketBased) {
      _socketService.removeAllListeners();
      _socketService.leaveRoom();
    }
    super.dispose();
  }

  void _initPlayers() {
    // Static 4-player mode for local/educational use
    players = [
      Player(id: 1, name: 'Pemain 1', color: Colors.blue),
      Player(id: 2, name: 'Pemain 2', color: Colors.red),
      Player(id: 3, name: 'Pemain 3', color: Colors.green),
      Player(id: 4, name: 'Pemain 4', color: Colors.orange),
    ];
    currentPlayerIndex = 0;
    showInfo = true;
    infoMessage = 'Giliran ${players[currentPlayerIndex].name}';
  }

  void _initSocketPlayers() {
    // Initialize players from socket room data
    final room = widget.roomData as Map<String, dynamic>;
    final roomPlayers = room['players'] as List<dynamic>;
    final mySocketId = _socketService.isConnected ? 'socket_id' : null; // Get from socket
    
    final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange];
    players = [];
    for (int i = 0; i < roomPlayers.length; i++) {
      final p = roomPlayers[i] as Map<String, dynamic>;
      players.add(Player(
        id: i + 1,
        name: p['name'] ?? 'Pemain ${i + 1}',
        color: colors[i % colors.length],
      ));
      if (p['socketId'] == mySocketId) {
        _myPlayerId = (i + 1).toString();
      }
    }
    
    currentPlayerIndex = room['currentPlayerIndex'] ?? 0;
    showInfo = true;
    infoMessage = _isMyTurn ? 'Giliran Anda!' : 'Giliran ${players[currentPlayerIndex].name}';
  }

  void _setupSocketListeners() {
    _socketService.onDiceRolled((data) {
      if (!mounted) return;
      final diceResult = data['dice'] as int;
      setState(() {
        diceValue = diceResult;
        isRolling = false;
      });
      _showDiceResultDialog(diceResult);
    });

    _socketService.onPlayerMoved((data) {
      if (!mounted) return;
      final playerIndex = data['playerIndex'] as int;
      final newPosition = data['position'] as int;
      setState(() {
        if (playerIndex < players.length) {
          players[playerIndex].position = newPosition;
        }
      });
    });

    _socketService.onTurnChanged((data) {
      if (!mounted) return;
      setState(() {
        currentPlayerIndex = data['currentPlayerIndex'] as int;
        showInfo = true;
        infoMessage = _isMyTurn ? 'Giliran Anda!' : 'Giliran ${players[currentPlayerIndex].name}';
      });
    });

    _socketService.onQuizUpdate((data) {
      if (!mounted) return;
      final quizPos = data['quizPosition'] as int;
      setState(() {
        completedQuizzes.add(quizPos);
      });
    });

    _socketService.onGameEnded((data) {
      if (!mounted) return;
      final winnerIndex = data['winnerIndex'] as int?;
      if (winnerIndex != null && winnerIndex < players.length) {
        setState(() {
          winner = players[winnerIndex];
          isRolling = false;
        });
        _showWinDialog();
      }
    });

    _socketService.onPlayerLeft((data) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${data['playerName'] ?? 'Pemain'} keluar dari permainan'),
          backgroundColor: Colors.orange,
        ),
      );
    });

    _socketService.onError((data) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Terjadi kesalahan'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  Future<void> _loadContent() async {
    try {
      await _contentService.loadContent();
      print('Multiplayer content loaded: snakes=${snakeMessages.length}, ladders=${ladderMessages.length}, facts=${tbFacts.length}');
    } catch (e) {
      print('Content load failed (fallback defaults): $e');
    }
  }

  void _startTimer() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          isTimeUp = true;
          gameTimer?.cancel();
          _showTimeUpDialog();
        }
      });
    });
  }

  String _formatTime(int secs) {
    final m = secs ~/ 60; final s = secs % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  void _generateRandomBoard() {
    final random = Random();
    const int minDistance = 2;
    const int maxLadderHeight = 25;
    bool isForbidden(int pos) => pos <= 1 || pos >= boardSize || pos % 5 == 0;
    final Map<int,int> sMap = {}; final Map<int,int> lMap = {}; final Set<int> qSet = {};

    bool tooClose(int start, Iterable<int> existing) => existing.any((e) => (e - start).abs() < minDistance);

    while (sMap.length < 8) {
      int start;
      do { start = random.nextInt(boardSize - 40) + 30; } while (sMap.containsKey(start) || lMap.containsKey(start) || qSet.contains(start) || isForbidden(start) || tooClose(start, sMap.keys));
      int end; do { end = random.nextInt(start - 10) + 2; } while (isForbidden(end));
      sMap[start] = end;
    }
    while (lMap.length < 8) {
      int start; do { start = random.nextInt(boardSize - 40) + 5; } while (lMap.containsKey(start) || sMap.containsKey(start) || qSet.contains(start) || isForbidden(start) || tooClose(start, lMap.keys));
      int end; do {
        end = start + random.nextInt(max(5, boardSize - start - 10)) + 10;
        if (end - start > maxLadderHeight) end = start + maxLadderHeight;
        if (end >= boardSize) end = boardSize - 1;
      } while (isForbidden(end));
      lMap[start] = end;
    }
    while (qSet.length < 10) {
      int pos; do { pos = random.nextInt(boardSize - 20) + 10; } while (lMap.containsKey(pos) || sMap.containsKey(pos) || qSet.contains(pos) || isForbidden(pos) || tooClose(pos, qSet));
      qSet.add(pos);
    }
    setState(() {
      snakesPositions = sMap;
      laddersPositions = lMap;
      quizPositions = qSet;
      _isLoadingBoard = false;
    });
  }

  void _rollDice() {
    if (isRolling || winner != null || isTimeUp) return;
    
    // In socket mode, only allow rolling on your turn
    if (widget.isSocketBased && !_isMyTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bukan giliran Anda!'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() { isRolling = true; });
    
    if (widget.isSocketBased) {
      // Send roll request to server
      _socketService.rollDice();
      // Server will emit dice_rolled event with result
    } else {
      // Local mode: generate dice result immediately
      final value = Random().nextInt(3) + 4; // 4..6 range
      diceValue = value;
      _showDiceDialog(value);
    }
  }

  void _showDiceDialog(int result) {
    _showDiceResultDialog(result);
  }

  void _showDiceResultDialog(int result) {
    bool moved = false; bool scheduled = false;
    void trigger(BuildContext ctx) {
      if (moved) return; moved = true;
      Navigator.of(ctx).pop();
      _movePlayer(result);
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) {
        if (!scheduled) { scheduled = true; Future.delayed(const Duration(milliseconds: 1100), () => trigger(dCtx)); }
        return GestureDetector(
          onTap: () => trigger(dCtx),
          child: Dialog(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.indigo.shade50, Colors.indigo.shade100]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.indigo.shade300, width: 3),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Colors.indigo.shade400, Colors.indigo.shade600]),
                  ),
                  child: const Icon(Icons.casino_rounded, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 18),
                Text('HASIL DADU', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo.shade800)),
                const SizedBox(height: 14),
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.red.shade400]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(child: Text('$result', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: Colors.white))),
                ),
                const SizedBox(height: 22),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:3,valueColor:AlwaysStoppedAnimation(Colors.green.shade600))),
                  const SizedBox(width: 12),
                  Text('Pion bergerak otomatis...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                ]),
                const SizedBox(height: 6),
                Text('Sentuh untuk percepat', style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
              ]),
            ),
          ),
        );
      }
    );
  }

  void _movePlayer(int steps) async {
    final player = players[currentPlayerIndex];
    final start = player.position;
    int target = start + steps; if (target > boardSize) target = boardSize;
    for (int i=1;i<= (target - start);i++) {
      await Future.delayed(const Duration(milliseconds: 260));
      setState(() { player.position = start + i; });
    }
    await Future.delayed(const Duration(milliseconds: 120));
    final pos = player.position;

    if (pos == boardSize) {
      if (completedQuizzes.length >= requiredQuizCount) {
        setState(() { winner = player; isRolling = false; });
        _showWinDialog();
        return;
      } else {
        await Future.delayed(const Duration(milliseconds: 400));
        setState(() { player.position = start; isRolling = false; });
        _showIncompleteQuizDialog();
        return;
      }
    }

    if (laddersPositions.containsKey(pos)) {
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() { player.position = laddersPositions[pos]!; });
      if (player.position == boardSize && completedQuizzes.length >= requiredQuizCount) {
        setState(() { winner = player; isRolling = false; });
        _showWinDialog();
        return;
      } else if (player.position == boardSize) {
        await Future.delayed(const Duration(milliseconds: 400));
        setState(() { player.position = pos; isRolling = false; });
        _showIncompleteQuizDialog();
        return;
      }
      _showEducationDialog(title: 'PERILAKU BAIK TBC', message: ladderMessages[Random().nextInt(ladderMessages.length)], subtitle: 'Naik ke ${player.position}', isPositive: true);
    } else if (snakesPositions.containsKey(pos)) {
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() { player.position = snakesPositions[pos]!; });
      _showEducationDialog(title: 'PERILAKU BURUK TBC', message: snakeMessages[Random().nextInt(snakeMessages.length)], subtitle: 'Turun ke ${player.position}', isPositive: false);
    } else if (quizPositions.contains(pos)) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (!completedQuizzes.contains(pos)) {
        final question = _randomQuestion();
        _showQuizDialog(question, pos);
      } else {
        _showEducationDialog(title: 'SUDAH DIJAWAB', message: 'Pertanyaan di kotak ini sudah kamu jawab. ${tbFacts[Random().nextInt(tbFacts.length)]}', subtitle: '', isPositive: true, isFact: true);
      }
    } else {
      _showEducationDialog(title: 'FAKTA TBC', message: tbFacts[Random().nextInt(tbFacts.length)], subtitle: '', isPositive: true, isFact: true);
    }

    await Future.delayed(const Duration(milliseconds: 420));
    setState(() {
      isRolling = false;
      if (winner == null) {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
        infoMessage = 'Giliran ${players[currentPlayerIndex].name}';
        showInfo = true;
      }
    });
  }

  Map<String,dynamic> _randomQuestion() => tbQuestions[Random().nextInt(tbQuestions.length)];

  void _showEducationDialog({required String title, required String message, required String subtitle, required bool isPositive, bool isFact=false}) {
    final icon = isFact
        ? Icons.wb_incandescent_rounded
        : isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: isFact
                  ? [Colors.blue.shade50, Colors.blue.shade100]
                  : isPositive ? [Colors.green.shade50, Colors.green.shade100] : [Colors.orange.shade50, Colors.orange.shade100]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isFact ? Colors.blue.shade300 : isPositive ? Colors.green.shade300 : Colors.orange.shade300, width: 3),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: isFact
                    ? [Colors.blue.shade400, Colors.blue.shade600]
                    : isPositive ? [Colors.green.shade400, Colors.green.shade600] : [Colors.orange.shade400, Colors.orange.shade600])),
                child: Icon(icon, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: isFact ? Colors.blue.shade800 : isPositive ? Colors.green.shade800 : Colors.orange.shade800), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.75), borderRadius: BorderRadius.circular(12), border: Border.all(color: isFact ? Colors.blue.shade200 : isPositive ? Colors.green.shade200 : Colors.orange.shade200, width: 2)),
                child: Text(message, style: TextStyle(fontSize: 15,fontWeight: FontWeight.w600,color: Colors.grey.shade800,height:1.5), textAlign: TextAlign.center),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(subtitle, style: TextStyle(fontSize: 13,fontStyle: FontStyle.italic,color: Colors.grey.shade700), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFact ? Colors.blue.shade600 : isPositive ? Colors.green.shade600 : Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 6,
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_rounded), SizedBox(width: 6), Text('LANJUTKAN', style: TextStyle(fontWeight: FontWeight.bold))]),
                ),
              ),
            ]),
          ),
        );
      }
    );
  }

  void _showQuizDialog(Map<String,dynamic> question, int position) {
    int? selected; bool answered = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: answered
                    ? (selected == question['correct'] ? [Colors.green.shade50, Colors.green.shade100] : [Colors.red.shade50, Colors.red.shade100])
                    : [Colors.purple.shade50, Colors.purple.shade100]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: answered ? (selected == question['correct'] ? Colors.green.shade300 : Colors.red.shade300) : Colors.purple.shade300, width: 3),
              ),
              child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: answered
                      ? (selected == question['correct'] ? [Colors.green.shade400, Colors.green.shade600] : [Colors.red.shade400, Colors.red.shade600])
                      : [Colors.purple.shade400, Colors.purple.shade600])),
                  child: Icon(answered ? (selected == question['correct'] ? Icons.check_circle_rounded : Icons.cancel_rounded) : Icons.quiz_rounded, color: Colors.white, size: 46),
                ),
                const SizedBox(height: 18),
                Text(answered ? (selected == question['correct'] ? '✓ BENAR!' : '✗ SALAH!') : 'PERTANYAAN KUIS TBC', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: answered ? (selected == question['correct'] ? Colors.green.shade800 : Colors.red.shade800) : Colors.purple.shade800)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.75), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purple.shade200, width: 2)),
                  child: Text(question['question'], style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade800, height:1.5), textAlign: TextAlign.center),
                ),
                const SizedBox(height: 14),
                ...List.generate(question['options'].length, (i) {
                  final isCorrect = i == question['correct'];
                  final isSelected = selected == i;
                  Color bg;
                  if (answered) {
                    if (isCorrect) {
                      bg = Colors.green.shade400;
                    } else if (isSelected) {
                      bg = Colors.red.shade400;
                    } else { bg = Colors.grey.shade300; }
                  } else {
                    bg = isSelected ? Colors.purple.shade300 : Colors.grey.shade200;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: answered ? null : () => setStateDialog(() { selected = i; }),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? (answered ? (isCorrect ? Colors.green.shade600 : Colors.red.shade600) : Colors.purple.shade600) : Colors.grey.shade400, width: 2)),
                        child: Row(children: [
                          Container(
                            width: 24, height: 24,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                            child: Center(child: Text(String.fromCharCode(65 + i), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(question['options'][i], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800))),
                          if (answered && isCorrect) Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                          if (answered && isSelected && !isCorrect) Icon(Icons.cancel, color: Colors.red.shade700, size: 20),
                        ]),
                      ),
                    ),
                  );
                }),
                if (answered) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200, width: 2)),
                    child: Row(children: [Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20), const SizedBox(width: 8), Expanded(child: Text(question['explanation'], style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height:1.4)))])
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: selected == null ? null : () {
                      if (!answered) {
                        setStateDialog(() { answered = true; });
                      } else {
                        setState(() { completedQuizzes.add(position); });
                        Navigator.of(ctx).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: answered ? (selected == question['correct'] ? Colors.green.shade600 : Colors.red.shade600) : Colors.purple.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 7,
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(answered ? Icons.check_rounded : Icons.send_rounded), const SizedBox(width: 8),
                      Text(answered ? 'LANJUTKAN' : 'JAWAB', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ]),
                  ),
                ),
              ])),
            ),
          );
        });
      }
    );
  }

  void _showIncompleteQuizDialog() {
    final remaining = requiredQuizCount - completedQuizzes.length;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.orange.shade50, Colors.orange.shade100]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade300, width: 3),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade600])),
                child: const Icon(Icons.warning_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 18),
              Text('BELUM BISA MENANG!', style: TextStyle(fontSize: 22,fontWeight: FontWeight.bold,color: Colors.orange.shade800)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.75), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200, width: 2)),
                child: Column(children: [
                  Text('Selesaikan minimal $requiredQuizCount kuis edukasi!', style: TextStyle(fontSize:16,fontWeight:FontWeight.w600,color:Colors.grey.shade800,height:1.4), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal:16, vertical:8),
                    decoration: BoxDecoration(color: Colors.purple.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.purple.shade300, width:2)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.quiz_rounded, color: Colors.purple.shade700, size:20), const SizedBox(width:8), Text('Tersisa: $remaining', style: TextStyle(fontSize:14,fontWeight:FontWeight.bold,color:Colors.purple.shade800))]),
                  ),
                  const SizedBox(height: 6),
                  Text('Cari kotak ungu dengan ikon kuis.', style: TextStyle(fontSize:12,fontStyle:FontStyle.italic,color:Colors.grey.shade600)),
                ]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cancel_rounded), SizedBox(width:8), Text('KEMBALI', style: TextStyle(fontWeight: FontWeight.bold))]),
                ),
              ),
            ]),
          ),
        );
      }
    );
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.amber.shade50, Colors.green.shade100]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade400, width: 3),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Colors.amber.shade400, Colors.amber.shade600])),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 62),
              ),
              const SizedBox(height: 24),
              Text('🎉 ${winner!.name} MENANG! 🎉', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green.shade800, letterSpacing: 1.2), textAlign: TextAlign.center),
              const SizedBox(height: 14),
              Text('Edukasi TBC berhasil dipahami bersama!', style: TextStyle(fontSize:15,fontWeight:FontWeight.w600,color:Colors.grey.shade800,height:1.5), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(10)),
                child: Text('Total Langkah: $moveCount', style: TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:Colors.blue.shade800), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () { Navigator.of(ctx).pop(); Navigator.of(ctx).pop(); },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.home_rounded), SizedBox(width:10), Text('KEMBALI KE HOME', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1))]),
                ),
              ),
            ]),
          ),
        );
      }
    );
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.red.shade50, Colors.red.shade100]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.shade300, width: 3),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Colors.red.shade400, Colors.red.shade600])),
                child: const Icon(Icons.timer_off_rounded, color: Colors.white, size: 54),
              ),
              const SizedBox(height: 20),
              Text('WAKTU HABIS!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.75), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200, width: 2)),
                child: Column(children: [
                  Text('Game edukasi selesai.', style: TextStyle(fontSize:16,fontWeight:FontWeight.w600,color:Colors.grey.shade800,height:1.4), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text('Kuis diselesaikan: ${completedQuizzes.length}/10 (wajib: $requiredQuizCount)', style: TextStyle(fontSize:14,fontWeight:FontWeight.bold,color:Colors.grey.shade700)),
                ]),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () { Navigator.of(ctx).pop(); Navigator.of(ctx).pop(); },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.home_rounded), SizedBox(width: 10), Text('KEMBALI KE HOME', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing:1))]),
                ),
              ),
            ]),
          ),
        );
      }
    );
  }

  Future<void> _handleExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.orange.shade50, Colors.red.shade50]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade300, width: 3),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.red.shade400])),
                child: const Icon(Icons.exit_to_app_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 20),
              Text('KELUAR DARI GAME?', style: TextStyle(fontSize:22,fontWeight:FontWeight.bold,color:Colors.orange.shade800)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.75), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200, width: 2)),
                child: Text('Game multiplayer edukasi tidak menyimpan skor.', style: TextStyle(fontSize:15,fontWeight:FontWeight.w600,color:Colors.grey.shade800,height:1.4), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.grey.shade700, side: BorderSide(color: Colors.grey.shade400, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical:14)),
                    child: const Text('LANJUTKAN', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical:14)),
                    child: const Text('KELUAR', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ]),
          ),
        );
      }
    );
    if (shouldExit == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildBoard() {
    return LayoutBuilder(builder: (ctx, constraints) {
      final cellSize = (constraints.maxWidth - 20) / 10;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10, crossAxisSpacing: 1.5, mainAxisSpacing: 1.5, childAspectRatio: 1),
        itemCount: boardSize,
        itemBuilder: (ctx, index) {
          final actualIndex = boardSize - index;
          final row = index ~/ 10; final reversed = row % 2 != 0;
          int position = reversed ? boardSize - (row * 10) - (9 - (index % 10)) : actualIndex;
          final isSnake = snakesPositions.containsKey(position);
          final isLadder = laddersPositions.containsKey(position);
          final isQuiz = quizPositions.contains(position);
          final isFinish = position == boardSize; final isStart = position == 1;
          final playersHere = players.where((p) => p.position == position).toList();
          final anyPlayerHere = playersHere.isNotEmpty;

          Color bg = Colors.white; Color border = Colors.grey.shade300;
          if (isSnake) { bg = Colors.red.shade50; border = Colors.red.shade200; }
          if (isLadder) { bg = Colors.green.shade50; border = Colors.green.shade200; }
          if (isQuiz) { bg = Colors.purple.shade50; border = Colors.purple.shade200; }
          if (isFinish) { bg = Colors.amber.shade100; border = Colors.amber.shade400; }
          if (isStart) { bg = Colors.blue.shade50; border = Colors.blue.shade300; }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: anyPlayerHere
                  ? LinearGradient(colors: [Colors.blue.shade200.withOpacity(0.6), Colors.blue.shade400.withOpacity(0.6)])
                  : LinearGradient(colors: [bg, bg]),
              border: Border.all(color: anyPlayerHere ? Colors.blue.shade700 : border, width: anyPlayerHere ? 2 : 1),
              borderRadius: BorderRadius.circular(6),
              boxShadow: anyPlayerHere
                  ? [BoxShadow(color: Colors.blue.withOpacity(0.55), blurRadius: 8, spreadRadius: 2)]
                  : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)],
            ),
            child: Stack(children: [
              if (position != 1 && position != boardSize)
                Positioned(
                  top: 2, left: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal:3, vertical:1),
                    decoration: BoxDecoration(color: anyPlayerHere ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                    child: Text('$position', style: TextStyle(fontSize: cellSize*0.22, color: anyPlayerHere ? Colors.blue.shade900 : Colors.grey.shade700, fontWeight: FontWeight.bold)),
                  ),
                ),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    if (isSnake)
                      Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.red.shade100, shape: BoxShape.circle), child: Icon(Icons.trending_down_rounded, color: Colors.red.shade700, size: cellSize*0.45)),
                    if (isLadder)
                      Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle), child: Icon(Icons.trending_up_rounded, color: Colors.green.shade700, size: cellSize*0.45)),
                    if (isQuiz)
                      Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.purple.shade100, shape: BoxShape.circle), child: Icon(Icons.quiz_rounded, color: Colors.purple.shade700, size: cellSize*0.45)),
                    if (isFinish)
                      Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.amber.shade200, shape: BoxShape.circle), child: Icon(Icons.emoji_events_rounded, color: Colors.amber.shade800, size: cellSize*0.5)),
                    if (isStart)
                      Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle), child: Icon(Icons.play_arrow_rounded, color: Colors.blue.shade700, size: cellSize*0.45)),
                  ]),
                ),
              ),
              if (anyPlayerHere)
                Center(
                  child: ScaleTransition(
                    scale: _bounceAnimation,
                    child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(playersHere.length, (i) {
                      final p = playersHere[i]; final size = playersHere.length == 1 ? cellSize*0.63 : cellSize*0.5;
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: playersHere.length == 1 ? 0 : 3),
                        child: Container(
                          width: size, height: size,
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: p.color, width: 3), boxShadow: [BoxShadow(color: p.color.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)]),
                          child: Icon(Icons.person_rounded, color: p.color, size: size*0.58),
                        ),
                      );
                    })),
                  ),
                ),
            ]),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingBoard) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade400))),
      );
    }
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.indigo.shade600, Colors.indigo.shade400, Colors.cyan.shade200]),
        ),
        child: SafeArea(
          child: Column(children: [
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal:16, vertical:12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              ),
              child: Column(children: [
                Row(children: [
                  IconButton(
                    onPressed: _handleExit,
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.red.shade700,
                    style: IconButton.styleFrom(backgroundColor: Colors.red.shade50, padding: const EdgeInsets.all(8)),
                  ),
                  Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.indigo.shade400, Colors.indigo.shade600]), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.group, color: Colors.white, size:24)),
                    const SizedBox(width:12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Multiplayer Edu TBC', style: TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:Colors.indigo.shade900,letterSpacing:0.5)),
                      Text('Mode Edukasi Bersama', style: TextStyle(fontSize:11,color:Colors.indigo.shade600)),
                    ])
                  ])),
                  const SizedBox(width:48),
                ]),
                const SizedBox(height: 12),
                Wrap(spacing:8, runSpacing:6, alignment: WrapAlignment.center, children: [
                  _chip(icon: Icons.timer_rounded, label: _formatTime(remainingSeconds), color: remainingSeconds < 60 ? Colors.red : Colors.purple),
                  ...players.map((p) => _chip(icon: Icons.person_pin_circle_rounded, label: '${p.name.split(' ').last} ${p.position}', color: p.color as MaterialColor)).toList(),
                  _chip(icon: Icons.quiz_rounded, label: '${completedQuizzes.length}/10', color: Colors.orange),
                ])
              ]),
            ),
            if (showInfo)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal:12, vertical:4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: winner != null ? [Colors.green.shade100, Colors.green.shade200] : [Colors.white, Colors.indigo.shade50]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: winner != null ? Colors.green.shade400 : Colors.indigo.shade300, width: 2),
                ),
                child: Text(infoMessage, textAlign: TextAlign.center, style: TextStyle(color: winner != null ? Colors.green.shade900 : Colors.indigo.shade900, fontWeight: FontWeight.w600, fontSize:13, height:1.4)),
              ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal:8, vertical:4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.5), width:2),
                ),
                child: _buildBoard(),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.9)]),
              ),
              child: winner == null ? Center(
                child: GestureDetector(
                  onTap: isRolling ? null : _rollDice,
                  child: ScaleTransition(
                    scale: isRolling ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: isRolling
                          ? [Colors.grey.shade400, Colors.grey.shade600]
                          : [players[currentPlayerIndex].color.withOpacity(0.6), players[currentPlayerIndex].color]),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: (isRolling ? Colors.grey : players[currentPlayerIndex].color).withOpacity(0.5), blurRadius: 20, offset: const Offset(0,8))],
                        border: Border.all(color: Colors.white, width:4),
                      ),
                      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.casino_rounded, size:60, color: Colors.white), const SizedBox(height:8),
                        Text(isRolling ? 'TUNGGU...' : 'LEMPAR ${players[currentPlayerIndex].name.split(' ').last}', style: const TextStyle(fontSize:14,fontWeight:FontWeight.bold,color:Colors.white,letterSpacing:1)),
                      ])),
                    ),
                  ),
                ),
              ) : Column(mainAxisSize: MainAxisSize.min, children: [
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.amber.shade200, Colors.amber.shade400]), shape: BoxShape.circle), child: const Icon(Icons.emoji_events_rounded, size:64, color: Colors.white)),
                const SizedBox(height: 16),
                Text('SELESAI 🎉', style: TextStyle(fontSize:32,fontWeight:FontWeight.bold, foreground: Paint()..shader = LinearGradient(colors: [Colors.green.shade600, Colors.green.shade800]).createShader(const Rect.fromLTWH(0,0,200,70))),),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.home_rounded, size:32), SizedBox(width:12), Text('KEMBALI', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold,letterSpacing:1.5))]),
                  ),
                ),
              ]),
            )
          ]),
        ),
      ),
    );
  }

  Widget _chip({required IconData icon, required String label, required MaterialColor color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal:12, vertical:6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.shade100, color.shade200]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.shade300, width:1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size:18, color: color.shade700), const SizedBox(width:6), Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color.shade800, fontSize:12))]),
    );
  }
}
