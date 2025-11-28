import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'auth_screen.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _userStats;
  bool _isLoading = true;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _loadUserData();
  }
  
  // Public method for external refresh trigger
  void loadUserData() {
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final isLoggedIn = await _apiService.isLoggedIn();
      
      if (isLoggedIn) {
        // Try dashboard API for richer data
        try {
          final dashboardResult = await _apiService.getDashboardStats().timeout(
            const Duration(seconds: 10),
          );
          
          if (dashboardResult['success']) {
            final dashboardData = dashboardResult['data'];
            setState(() {
              _userProfile = dashboardData['user'];
              _userStats = dashboardData['statistics'];
              _isGuest = false;
            });
            return;
          }
        } catch (e) {
          print('❌ Dashboard error: $e');
          // Try profile API as fallback
          try {
            final profileResult = await _apiService.getProfile().timeout(
              const Duration(seconds: 10),
            );
            if (profileResult['success']) {
              final userData = profileResult['data'];
              setState(() {
                _userProfile = userData;
                _userStats = userData['statistics'] ?? {};
                _isGuest = false;
              });
              return;
            }
          } catch (e) {
            print('❌ Profile API error: $e');
          }
        }
        
        // If both APIs fail, use cached data
        print('ℹ️ Using cached user data');
        final cachedData = await _apiService.getCachedUserData();
        
        if (cachedData['userId']?.isNotEmpty ?? false) {
          setState(() {
            _userProfile = {
              'username': cachedData['username'],
              'fullName': cachedData['fullName'],
            };
            _userStats = {
              'highestLevel': 0,
              'totalGames': 0,
            };
            _isGuest = false;
          });
        } else {
          setState(() {
            _isGuest = true;
          });
        }
      } else {
        setState(() {
          _isGuest = true;
        });
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() {
        _isGuest = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Logout'),
          ],
        ),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              Colors.blue.shade600,
              Colors.blue.shade400,
              Colors.cyan.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      _buildWelcomeSection(),
                      
                      const SizedBox(height: 30),
                      
                      // Dashboard Cards
                      if (!_isGuest) ...[
                        _buildStatsGrid(),
                        const SizedBox(height: 20),
                      ],
                      
                      // Quick Actions
                      _buildQuickActions(),
                      
                      const SizedBox(height: 20),
                      
                      // Educational Banner
                      _buildEducationalBanner(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _isGuest ? '👤' : (_userProfile?['fullName']?[0]?.toUpperCase() ?? '?'),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang! 👋',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isGuest ? 'Guest Player' : (_userProfile?['fullName'] ?? 'Player'),
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Logout Button
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded),
            color: Colors.white,
            tooltip: 'Logout',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.15),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = _userStats ?? {};
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.emoji_events,
          title: 'Total Menang',
          value: '${stats['totalWins'] ?? 0}',
          color: Colors.amber,
        ),
        _buildStatCard(
          icon: Icons.stars,
          title: 'Total Skor',
          value: '${stats['totalScore'] ?? 0}',
          color: Colors.yellow.shade700,
        ),
        _buildStatCard(
          icon: Icons.emoji_events_outlined,
          title: 'Skor Tertinggi',
          value: '${stats['highestScore'] ?? 0}',
          color: Colors.orange,
        ),
        _buildStatCard(
          icon: Icons.trending_up,
          title: 'Level Tertinggi',
          value: '${stats['highestLevel'] ?? 0}',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.play_circle_filled,
                title: 'Main Sekarang',
                color: Colors.green,
                onTap: () {
                  // Quick action - just visual indicator
                  // User can tap Play tab in bottom navigation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gunakan tab "Play" di bawah untuk mulai bermain'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildActionButton(
                icon: Icons.info,
                title: 'Pelajari TBC',
                color: Colors.orange,
                onTap: () {
                  // Quick action - just visual indicator
                  // User can tap Info tab in bottom navigation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gunakan tab "Info" di bawah untuk belajar tentang TBC'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
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
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEducationalBanner() {
    final tips = [
      'TBC bisa disembuhkan dengan minum obat teratur! 💊',
      'Buka jendela rumah setiap hari untuk sirkulasi udara! 🪟',
      'Batuk lebih dari 2 minggu? Segera periksa ke dokter! 🏥',
      'Masker membantu mencegah penularan TBC! 😷',
      'TBC tidak menular lewat pelukan atau jabat tangan! 🤝',
    ];
    
    final randomTip = tips[Random().nextInt(tips.length)];
    
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.red.shade400],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.lightbulb, color: Colors.white, size: 32),
            const SizedBox(height: 10),
            const Text(
              'Tahukah Kamu?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              randomTip,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
