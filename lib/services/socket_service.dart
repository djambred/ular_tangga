import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  
  // Get current socket ID
  String? get socketId => _socket?.id;

  // Connect to server
  void connect(String serverUrl) {
    if (_socket != null && _isConnected) {
      print('⚠️ Already connected or connecting');
      return;
    }

    print('🔌 Attempting to connect to: $serverUrl');

    // Determine if using HTTPS
    final isSecure = serverUrl.startsWith('https');
    // For production HTTPS, try WebSocket first since polling might be blocked
    // For localhost, polling is more reliable
    final transport = isSecure 
        ? ['websocket', 'polling']  // Production: WebSocket first
        : ['polling', 'websocket'];  // Localhost: Polling first
    
    print('🔧 Using transports: $transport (secure: $isSecure)');

    _socket = IO.io(serverUrl, IO.OptionBuilder()
      .setTransports(transport)
      .disableAutoConnect()
      .enableReconnection()
      .setReconnectionAttempts(10)
      .setReconnectionDelay(2000)
      .setReconnectionDelayMax(10000)
      .setTimeout(30000)
      .enableForceNew()
      .setPath('/socket.io/')
      .setExtraHeaders({'Accept': '*/*'})
      .build()
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('✅ Connected to server: $serverUrl');
      _isConnected = true;
    });

    _socket!.onDisconnect((reason) {
      print('❌ Disconnected from server. Reason: $reason');
      _isConnected = false;
    });

    _socket!.onConnectError((data) {
      print('❌ Connection error: $data');
      _isConnected = false;
    });

    _socket!.onError((data) {
      print('❌ Socket error: $data');
    });

    _socket!.onConnectTimeout((data) {
      print('❌ Connection timeout: $data');
      _isConnected = false;
    });
  }

  // Disconnect from server
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  // Create a new room
  void createRoom({
    required String playerName,
    required int level,
    int maxPlayers = 4,
  }) {
    print('🎮 Creating room: player=$playerName, level=$level, maxPlayers=$maxPlayers');
    if (_socket == null || !_isConnected) {
      print('❌ Cannot create room: socket not connected');
      return;
    }
    _socket?.emit('create_room', {
      'playerName': playerName,
      'level': level,
      'maxPlayers': maxPlayers,
    });
    print('✅ Create room event emitted');
  }

  // Join an existing room
  void joinRoom({
    required String roomCode,
    required String playerName,
  }) {
    print('🚪 Joining room: code=$roomCode, player=$playerName');
    if (_socket == null || !_isConnected) {
      print('❌ Cannot join room: socket not connected');
      return;
    }
    _socket?.emit('join_room', {
      'roomCode': roomCode,
      'playerName': playerName,
    });
    print('✅ Join room event emitted');
  }

  // Toggle player ready status
  void toggleReady() {
    _socket?.emit('player_ready');
  }

  // Start the game (host only)
  void startGame() {
    _socket?.emit('start_game');
  }

  // Roll dice
  void rollDice() {
    _socket?.emit('roll_dice');
  }

  // Move player
  void movePlayer(int position) {
    _socket?.emit('move_player', {'position': position});
  }

  // Quiz completed
  void quizCompleted(int quizPosition) {
    _socket?.emit('quiz_completed', {'quizPosition': quizPosition});
  }

  // Next turn
  void nextTurn() {
    _socket?.emit('next_turn');
  }

  // Player won
  void playerWon() {
    _socket?.emit('player_won');
  }

  // Leave room
  void leaveRoom() {
    _socket?.emit('leave_room');
  }

  // Event listeners
  void onRoomCreated(Function(dynamic) callback) {
    _socket?.on('room_created', callback);
  }

  void onPlayerJoined(Function(dynamic) callback) {
    _socket?.on('player_joined', callback);
  }

  void onRoomUpdated(Function(dynamic) callback) {
    _socket?.on('room_updated', callback);
  }

  void onGameStarted(Function(dynamic) callback) {
    _socket?.on('game_started', callback);
  }

  void onDiceRolled(Function(dynamic) callback) {
    _socket?.on('dice_rolled', callback);
  }

  void onPlayerMoved(Function(dynamic) callback) {
    _socket?.on('player_moved', callback);
  }

  void onQuizUpdate(Function(dynamic) callback) {
    _socket?.on('quiz_update', callback);
  }

  void onTurnChanged(Function(dynamic) callback) {
    _socket?.on('turn_changed', callback);
  }

  void onGameEnded(Function(dynamic) callback) {
    _socket?.on('game_ended', callback);
  }

  void onPlayerLeft(Function(dynamic) callback) {
    _socket?.on('player_left', callback);
  }

  void onError(Function(dynamic) callback) {
    _socket?.on('error', callback);
  }

  // Remove listeners
  void offRoomCreated() {
    _socket?.off('room_created');
  }

  void offPlayerJoined() {
    _socket?.off('player_joined');
  }

  void offRoomUpdated() {
    _socket?.off('room_updated');
  }

  void offGameStarted() {
    _socket?.off('game_started');
  }

  void offDiceRolled() {
    _socket?.off('dice_rolled');
  }

  void offPlayerMoved() {
    _socket?.off('player_moved');
  }

  void offQuizUpdate() {
    _socket?.off('quiz_update');
  }

  void offTurnChanged() {
    _socket?.off('turn_changed');
  }

  void offGameEnded() {
    _socket?.off('game_ended');
  }

  void offPlayerLeft() {
    _socket?.off('player_left');
  }

  void offError() {
    _socket?.off('error');
  }

  // Remove all listeners
  void removeAllListeners() {
    offRoomCreated();
    offPlayerJoined();
    offRoomUpdated();
    offGameStarted();
    offDiceRolled();
    offPlayerMoved();
    offQuizUpdate();
    offTurnChanged();
    offGameEnded();
    offPlayerLeft();
    offError();
  }
}
