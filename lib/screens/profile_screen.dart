import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _userStats;
  bool _isLoading = true;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final isLoggedIn = await _apiService.isLoggedIn();
      
      if (!isLoggedIn) {
        setState(() {
          _isGuest = true;
          _isLoading = false;
        });
        return;
      }

      // Try to use dashboard API for richer statistics
      try {
        final result = await _apiService.getDashboardStats().timeout(
          const Duration(seconds: 10),
        );
        
        if (result['success']) {
          final dashboardData = result['data'];
          setState(() {
            _userProfile = {
              ...dashboardData['user'],
              'email': dashboardData['user']['email'] ?? '',
            };
            _userStats = dashboardData['statistics'];
            _isGuest = false;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('❌ Dashboard stats error: $e');
        // Try profile API as fallback
        try {
          final profileResult = await _apiService.getProfile().timeout(
            const Duration(seconds: 10),
          );
          if (profileResult['success']) {
            setState(() {
              _userProfile = profileResult['data'];
              _userStats = profileResult['data']['statistics'] ?? {};
              _isGuest = false;
              _isLoading = false;
            });
            return;
          }
        } catch (e) {
          print('❌ Profile API error: $e');
        }
      }
      
      // If all API calls fail, use cached data
      print('ℹ️ Using cached user data (offline mode)');
      final cachedData = await _apiService.getCachedUserData();
      
      if (cachedData['userId']?.isNotEmpty ?? false) {
        setState(() {
          _userProfile = {
            '_id': cachedData['userId'],
            'username': cachedData['username'],
            'email': cachedData['email'],
            'fullName': cachedData['fullName'],
          };
          _userStats = {
            'totalWins': 0,
            'totalGames': 0,
            'totalQuizzesAnswered': 0,
            'totalQuizzesCorrect': 0,
            'highestLevel': 0,
            'totalScore': 0,
            'highestScore': 0,
            'totalPlayTime': 0,
          };
          _isGuest = false;
          _isLoading = false;
        });
        
        // Show offline indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.cloud_off, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Mode Offline - Data statistik tidak tersedia'),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // No cached data, force logout
        await _apiService.clearToken();
        setState(() {
          _isGuest = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      // Last resort: check cached data
      final cachedData = await _apiService.getCachedUserData();
      if (cachedData['userId']?.isNotEmpty ?? false) {
        setState(() {
          _userProfile = {
            'username': cachedData['username'],
            'email': cachedData['email'],
            'fullName': cachedData['fullName'],
          };
          _userStats = {};
          _isGuest = false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isGuest = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red.shade700),
            const SizedBox(width: 10),
            const Text('Logout'),
          ],
        ),
        content: const Text('Apakah kamu yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _apiService.logout();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
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
              Colors.indigo.shade600,
              Colors.indigo.shade400,
              Colors.blue.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _isGuest
                  ? _buildGuestView()
                  : _buildProfileView(),
        ),
      ),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Mode Guest',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Login untuk menyimpan progress dan melihat statistik kamu',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigo.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login),
                    SizedBox(width: 10),
                    Text(
                      'Login / Register',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
  }

  Widget _buildProfileView() {
    final stats = _userStats ?? {};
    final winRate = (stats['totalGames'] ?? 0) > 0
        ? ((stats['totalWins'] ?? 0) / (stats['totalGames'] ?? 1) * 100).toStringAsFixed(1)
        : '0.0';
    final quizAccuracy = (stats['totalQuizzesAnswered'] ?? 0) > 0
        ? ((stats['totalQuizzesCorrect'] ?? 0) / (stats['totalQuizzesAnswered'] ?? 1) * 100).toStringAsFixed(1)
        : '0.0';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade400, Colors.blue.shade400],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (_userProfile?['fullName']?[0]?.toUpperCase() ?? '?'),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _userProfile?['fullName'] ?? 'Player',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '@${_userProfile?['username'] ?? 'player'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _userProfile?['email'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Statistics Grid
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistik Permainan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildStatRow(
                  icon: Icons.emoji_events,
                  label: 'Total Menang',
                  value: '${stats['totalWins'] ?? 0}',
                  color: Colors.amber,
                ),
                const Divider(height: 25),
                _buildStatRow(
                  icon: Icons.gamepad,
                  label: 'Total Games',
                  value: '${stats['totalGames'] ?? 0}',
                  color: Colors.green,
                ),
                const Divider(height: 25),
                _buildStatRow(
                  icon: Icons.percent,
                  label: 'Win Rate',
                  value: '$winRate%',
                  color: Colors.blue,
                ),
                const Divider(height: 25),
                _buildStatRow(
                  icon: Icons.quiz,
                  label: 'Kuis Dijawab',
                  value: '${stats['totalQuizzesAnswered'] ?? 0}',
                  color: Colors.purple,
                ),
                const Divider(height: 25),
                _buildStatRow(
                  icon: Icons.check_circle,
                  label: 'Kuis Benar',
                  value: '${stats['totalQuizzesCorrect'] ?? 0}',
                  color: Colors.green,
                ),
                const Divider(height: 25),
                _buildStatRow(
                  icon: Icons.analytics,
                  label: 'Akurasi Kuis',
                  value: '$quizAccuracy%',
                  color: Colors.teal,
                ),
                const Divider(height: 25),
                _buildStatRow(
                  icon: Icons.trending_up,
                  label: 'Level Tertinggi',
                  value: '${stats['highestLevel'] ?? 0}',
                  color: Colors.orange,
                ),
                const Divider(height: 25),
                _buildStatRow(
                  icon: Icons.stars,
                  label: 'Total Skor',
                  value: '${stats['totalScore'] ?? 0}',
                  color: Colors.yellow.shade700,
                ),
                const Divider(height: 25),
                _buildStatRow(
                  icon: Icons.emoji_events_outlined,
                  label: 'Skor Tertinggi',
                  value: '${stats['highestScore'] ?? 0}',
                  color: Colors.amber.shade700,
                ),
                const Divider(height: 25),
                _buildStatRow(
                  icon: Icons.access_time,
                  label: 'Total Waktu Bermain',
                  value: _formatPlayTime(stats['totalPlayTime'] ?? 0),
                  color: Colors.indigo,
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 10),
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatPlayTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }
}
