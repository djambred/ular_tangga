import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();

    // Initialize app: load configs and content
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final apiService = ApiService();
      final prefs = await SharedPreferences.getInstance();
      
      // Load app configs from backend
      print('⚙️ Loading app configurations...');
      await apiService.applyConfigs();
      
      // Check if this is first time launch
      final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
      
      // Check if user is logged in (has token)
      final isLoggedIn = await apiService.isLoggedIn();
      
      bool isValidSession = false;
      
      if (isLoggedIn) {
        // Validate token by fetching profile
        print('🔐 Token found, validating session...');
        try {
          final profileResponse = await apiService.getProfile().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout validating session');
            },
          );
          
          if (profileResponse['success'] == true && profileResponse['data'] != null) {
            // Cache user profile for offline use
            final userData = profileResponse['data'];
            await prefs.setString('cached_user_id', userData['_id'] ?? '');
            await prefs.setString('cached_username', userData['username'] ?? '');
            await prefs.setString('cached_email', userData['email'] ?? '');
            await prefs.setString('cached_full_name', userData['fullName'] ?? '');
            
            print('✅ Session valid, user: ${userData['username']}');
            isValidSession = true;
          }
        } catch (e) {
          print('❌ Session validation failed: $e');
          // Token expired or invalid, clear it
          await apiService.clearToken();
          await prefs.remove('cached_user_id');
          await prefs.remove('cached_username');
          await prefs.remove('cached_email');
          await prefs.remove('cached_full_name');
          isValidSession = false;
        }
      }
      
      // Wait for minimum splash duration
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        if (isFirstLaunch) {
          // First time user -> Show instructions
          await prefs.setBool('is_first_launch', false);
          Navigator.of(context).pushReplacementNamed('/instructions');
        } else if (isValidSession) {
          // Valid session -> Auto login to main navigation
          print('🚀 Auto-login successful');
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => 
                const MainNavigationScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        } else {
          // No valid session -> Go to auth screen
          print('🔓 No valid session, showing auth screen');
          Navigator.of(context).pushReplacementNamed('/auth');
        }
      }
    } catch (e) {
      print('⚠️ Initialization error: $e');
      // Continue anyway with defaults
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        // On error, go to auth screen
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
              Colors.blue.shade700,
              Colors.blue.shade500,
              Colors.cyan.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Logo Icon dengan animasi scale
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 300,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Title
                Text(
                  'ULAR TANGGA',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Subtitle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Text(
                    'EDUKASI TBC',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Description
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Belajar tentang pencegahan dan\npengobatan TBC sambil bermain',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Loading indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  'Memuat...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
