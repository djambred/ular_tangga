import 'package:flutter/material.dart';
import '../../services/socket_service.dart';
import '../multiplayer_game_screen.dart';

class WaitingRoomScreen extends StatefulWidget {
  final String roomCode;
  final dynamic room;
  final bool isHost;
  final int selectedLevel;

  const WaitingRoomScreen({
    Key? key,
    required this.roomCode,
    required this.room,
    required this.isHost,
    required this.selectedLevel,
  }) : super(key: key);

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  final SocketService _socketService = SocketService();
  late Map<String, dynamic> _currentRoom;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _currentRoom = Map<String, dynamic>.from(widget.room);
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _socketService.removeAllListeners();
    super.dispose();
  }

  void _setupSocketListeners() {
    _socketService.onRoomUpdated((data) {
      if (mounted) {
        setState(() {
          _currentRoom = Map<String, dynamic>.from(data);
        });
      }
    });

    _socketService.onPlayerJoined((data) {
      if (mounted) {
        setState(() {
          _currentRoom = Map<String, dynamic>.from(data['room']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${data['player']['name']} bergabung!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });

    _socketService.onPlayerLeft((data) {
      if (mounted) {
        setState(() {
          _currentRoom = Map<String, dynamic>.from(data['room']);
        });
      }
    });

    _socketService.onGameStarted((data) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MultiplayerGameScreen(
              requiredQuizzes: widget.selectedLevel,
              level: widget.selectedLevel,
              roomData: data['room'],
              isSocketBased: true,
            ),
          ),
        );
      }
    });

    _socketService.onError((data) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Terjadi kesalahan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _toggleReady() {
    setState(() {
      _isReady = !_isReady;
    });
    _socketService.toggleReady();
  }

  void _startGame() {
    _socketService.startGame();
  }

  void _leaveRoom() {
    _socketService.leaveRoom();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  bool _canStartGame() {
    if (!widget.isHost) return false;
    
    final players = _currentRoom['players'] as List;
    if (players.length < 2) return false;
    
    // Check if all players except host are ready
    return players.every((player) => 
      player['id'] == _currentRoom['host'] || player['isReady'] == true
    );
  }

  @override
  Widget build(BuildContext context) {
    final players = _currentRoom['players'] as List? ?? [];
    
    return WillPopScope(
      onWillPop: () async {
        _leaveRoom();
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade400,
                Colors.blue.shade500,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _leaveRoom,
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ruang Tunggu',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Level ${widget.selectedLevel}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Room code
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Kode Ruangan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.roomCode,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade600,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bagikan kode ini ke temanmu',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Players list
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pemain (${players.length}/4)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: players.length,
                            itemBuilder: (context, index) {
                              final player = players[index];
                              final isHost = player['id'] == _currentRoom['host'];
                              final isReady = player['isReady'] ?? false;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isReady ? Colors.green : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: _getPlayerColor(player['color']),
                                      child: Text(
                                        player['name'][0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                player['name'],
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (isHost) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Text(
                                                    'HOST',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          Text(
                                            isHost ? 'Menunggu host memulai' : 
                                              (isReady ? 'Siap!' : 'Belum siap'),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isReady ? Colors.green : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isReady && !isHost)
                                      const Icon(Icons.check_circle, color: Colors.green),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (widget.isHost) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _canStartGame() ? _startGame : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow, size: 28),
                                SizedBox(width: 8),
                                Text(
                                  'MULAI PERMAINAN',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!_canStartGame())
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              players.length < 2 
                                  ? 'Minimal 2 pemain untuk memulai'
                                  : 'Tunggu semua pemain siap',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _toggleReady,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isReady 
                                  ? Colors.orange.shade600 
                                  : Colors.green.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_isReady ? Icons.close : Icons.check, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  _isReady ? 'BATAL SIAP' : 'SIAP',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _leaveRoom,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Keluar dari Ruangan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
      ),
    );
  }

  Color _getPlayerColor(String colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow.shade700;
      default:
        return Colors.grey;
    }
  }
}
