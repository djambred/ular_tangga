import 'package:flutter/material.dart';
import '../../services/socket_service.dart';
import 'waiting_room_screen.dart';

class MultiplayerLobbyScreen extends StatefulWidget {
  final int selectedLevel;

  const MultiplayerLobbyScreen({Key? key, required this.selectedLevel}) : super(key: key);

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();
  final TextEditingController _serverUrlController = TextEditingController();
  final SocketService _socketService = SocketService();
  bool _isConnecting = false;
  String _serverUrl = 'https://apiular.ueu-fasilkom.my.id'; // Production server URL

  @override
  void initState() {
    super.initState();
    _serverUrlController.text = _serverUrl;
    _connectToServer();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomCodeController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  void _connectToServer() {
    setState(() => _isConnecting = true);
    print('🔌 Connecting to server: $_serverUrl');
    _socketService.connect(_serverUrl);
    
    // Wait for connection with longer timeout (10 seconds for production)
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _isConnecting = false);
        if (!_socketService.isConnected) {
          print('❌ Connection failed after 10 seconds');
          _showErrorDialog(
            'Gagal terhubung ke server Socket.IO\n\n'
            'URL: $_serverUrl\n\n'
            'Kemungkinan penyebab:\n'
            '• Server backend tidak berjalan\n'
            '• Koneksi internet bermasalah\n'
            '• Firewall memblokir WebSocket\n'
            '• URL server salah\n\n'
            'Coba:\n'
            '1. Pastikan koneksi internet stabil\n'
            '2. Klik Settings untuk ubah URL server\n'
            '3. Hubungi admin jika masalah berlanjut'
          );
        } else {
          print('✅ Connected successfully!');
        }
      }
    });
  }

  void _setupSocketListeners() {
    _socketService.onRoomCreated((data) {
      print('✅ Room created: ${data['roomCode']}');
      if (mounted) {
        setState(() => _isConnecting = false);
        final roomCode = data['roomCode'];
        final room = data['room'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WaitingRoomScreen(
              roomCode: roomCode,
              room: room,
              isHost: true,
              selectedLevel: widget.selectedLevel,
            ),
          ),
        );
      }
    });

    _socketService.onPlayerJoined((data) {
      print('✅ Player joined room: ${data['room']['code']}');
      if (mounted) {
        setState(() => _isConnecting = false);
        final room = data['room'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WaitingRoomScreen(
              roomCode: room['code'],
              room: room,
              isHost: false,
              selectedLevel: widget.selectedLevel,
            ),
          ),
        );
      }
    });

    _socketService.onError((data) {
      print('❌ Socket error: ${data['message']}');
      if (mounted) {
        setState(() => _isConnecting = false);
        _showErrorDialog(data['message'] ?? 'Terjadi kesalahan dari server');
      }
    });
  }

  void _createRoom() {
    final playerName = _nameController.text.trim();
    
    if (playerName.isEmpty) {
      _showErrorDialog('Masukkan nama Anda terlebih dahulu');
      return;
    }

    if (!_socketService.isConnected) {
      _showErrorDialog('Tidak terhubung ke server. Silakan tunggu atau coba hubungkan ulang.');
      return;
    }

    print('🎮 Creating room for: $playerName');
    setState(() => _isConnecting = true);
    
    _socketService.createRoom(
      playerName: playerName,
      level: widget.selectedLevel,
      maxPlayers: 4,
    );
    
    // Timeout jika tidak ada response
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isConnecting) {
        setState(() => _isConnecting = false);
        _showErrorDialog('Timeout membuat ruangan. Coba lagi.');
      }
    });
  }

  void _joinRoom() {
    final playerName = _nameController.text.trim();
    final roomCode = _roomCodeController.text.trim().toUpperCase();
    
    if (playerName.isEmpty) {
      _showErrorDialog('Masukkan nama Anda terlebih dahulu');
      return;
    }

    if (roomCode.isEmpty) {
      _showErrorDialog('Masukkan kode ruangan');
      return;
    }

    if (!_socketService.isConnected) {
      _showErrorDialog('Tidak terhubung ke server. Silakan tunggu atau coba hubungkan ulang.');
      return;
    }
    
    print('🚪 Joining room: $roomCode as $playerName');
    setState(() => _isConnecting = true);

    _socketService.joinRoom(
      roomCode: roomCode,
      playerName: playerName,
    );
    
    // Timeout jika tidak ada response
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isConnecting) {
        setState(() => _isConnecting = false);
        _showErrorDialog('Timeout bergabung ke ruangan. Periksa kode ruangan atau coba lagi.');
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(String label, String url) {
    return InkWell(
      onTap: () {
        setState(() {
          _serverUrlController.text = url;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade900,
          ),
        ),
      ),
    );
  }

  void _showServerSettings() {
    _serverUrlController.text = _serverUrl;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pengaturan Server'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'URL Server Socket.IO',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _serverUrlController,
                decoration: const InputDecoration(
                  hintText: 'http://ip:port',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Preset URL:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPresetButton('Production', 'https://apiular.ueu-fasilkom.my.id'),
                  _buildPresetButton('Localhost', 'http://localhost:3000'),
                  _buildPresetButton('Android Emu', 'http://10.0.2.2:3000'),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Tips Koneksi:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Production: gunakan https://apiular.ueu-fasilkom.my.id',
                      style: TextStyle(fontSize: 11, height: 1.5),
                    ),
                    const Text(
                      '• Pastikan koneksi internet stabil',
                      style: TextStyle(fontSize: 11, height: 1.5),
                    ),
                    const Text(
                      '• Development: gunakan localhost atau 10.0.2.2',
                      style: TextStyle(fontSize: 11, height: 1.5),
                    ),
                    const Text(
                      '• WebSocket harus support di network Anda',
                      style: TextStyle(fontSize: 11, height: 1.5),
                    ),
                    const Text(
                      '• Cek firewall jika gagal terhubung',
                      style: TextStyle(fontSize: 11, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _serverUrl = _serverUrlController.text.trim();
              });
              Navigator.pop(context);
              _socketService.disconnect();
              _connectToServer();
            },
            child: const Text('Simpan & Hubungkan'),
          ),
        ],
      ),
    );
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
              Colors.orange.shade400,
              Colors.red.shade500,
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
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Multiplayer Lobby',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _showServerSettings,
                      icon: const Icon(Icons.settings, color: Colors.white, size: 24),
                      tooltip: 'Pengaturan Server',
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Connection status
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _socketService.isConnected 
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _socketService.isConnected 
                                ? Colors.green 
                                : Colors.red,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _socketService.isConnected 
                                  ? Icons.check_circle 
                                  : Icons.error,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _socketService.isConnected 
                                  ? 'Terhubung ke server' 
                                  : 'Tidak terhubung',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Name input
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nama Pemain',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: 'Masukkan nama Anda',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                              maxLength: 20,
                            ),
                          ],
                        ),
                      ),

                      // Reconnect button if not connected
                      if (!_socketService.isConnected && !_isConnecting)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: _connectToServer,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba Hubungkan Ulang'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 30),

                      // Create room button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isConnecting || !_socketService.isConnected 
                              ? null 
                              : _createRoom,
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
                              Icon(Icons.add_circle_outline, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'Buat Ruangan Baru',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.5), thickness: 2)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'ATAU',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.5), thickness: 2)),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Join room section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gabung ke Ruangan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _roomCodeController,
                              decoration: InputDecoration(
                                hintText: 'Masukkan kode ruangan',
                                prefixIcon: const Icon(Icons.vpn_key),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                              maxLength: 6,
                              textCapitalization: TextCapitalization.characters,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isConnecting || !_socketService.isConnected 
                                    ? null 
                                    : _joinRoom,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Gabung Ruangan',
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
            ],
          ),
        ),
      ),
    );
  }
}
