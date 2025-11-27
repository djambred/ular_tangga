import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  
  List<dynamic> _leaderboardByScore = [];
  List<dynamic> _leaderboardByWins = [];
  List<dynamic> _leaderboardByGames = [];
  List<dynamic> _leaderboardByQuizzes = [];
  
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        _apiService.getLeaderboard(sortBy: 'score', limit: 50),
        _apiService.getLeaderboard(sortBy: 'wins', limit: 50),
        _apiService.getLeaderboard(sortBy: 'games', limit: 50),
        _apiService.getLeaderboard(sortBy: 'quizzes', limit: 50),
      ]);

      setState(() {
        _leaderboardByScore = results[0];
        _leaderboardByWins = results[1];
        _leaderboardByGames = results[2];
        _leaderboardByQuizzes = results[3];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat leaderboard: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber.shade600,
              Colors.amber.shade400,
              Colors.yellow.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber.shade900, size: 40),
                        const SizedBox(width: 10),
                        Text(
                          'Leaderboard',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Pemain Terbaik',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.amber.shade600,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.stars, size: 20),
                      text: 'Skor',
                    ),
                    Tab(
                      icon: Icon(Icons.emoji_events, size: 20),
                      text: 'Menang',
                    ),
                    Tab(
                      icon: Icon(Icons.gamepad, size: 20),
                      text: 'Games',
                    ),
                    Tab(
                      icon: Icon(Icons.quiz, size: 20),
                      text: 'Kuis',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : _errorMessage.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage,
                                  style: const TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadLeaderboard,
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          )
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildLeaderboardList(_leaderboardByScore, 'score'),
                              _buildLeaderboardList(_leaderboardByWins, 'wins'),
                              _buildLeaderboardList(_leaderboardByGames, 'games'),
                              _buildLeaderboardList(_leaderboardByQuizzes, 'quizzes'),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(List<dynamic> data, String sortBy) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada data',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final player = data[index];
          final rank = index + 1;
          
          return _buildLeaderboardCard(
            rank: rank,
            username: player['username'] ?? 'Player',
            fullName: player['fullName'] ?? '',
            stats: player['statistics'] ?? {},
            sortBy: sortBy,
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardCard({
    required int rank,
    required String username,
    required String fullName,
    required Map<String, dynamic> stats,
    required String sortBy,
  }) {
    Color rankColor;
    IconData? medalIcon;
    
    if (rank == 1) {
      rankColor = Colors.amber.shade700;
      medalIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.grey.shade600;
      medalIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = Colors.brown.shade600;
      medalIcon = Icons.emoji_events;
    } else {
      rankColor = Colors.grey.shade700;
    }

    String getValue() {
      switch (sortBy) {
        case 'score':
          return '${stats['totalScore'] ?? 0} poin';
        case 'wins':
          return '${stats['totalWins'] ?? 0} menang';
        case 'games':
          return '${stats['totalGames'] ?? 0} games';
        case 'quizzes':
          return '${stats['totalQuizzesCorrect'] ?? 0} benar';
        default:
          return '0';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: rank <= 3
            ? Border.all(color: rankColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: medalIcon != null
                  ? Icon(medalIcon, color: rankColor, size: 28)
                  : Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: rankColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 15),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (fullName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    fullName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              getValue(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: rankColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
