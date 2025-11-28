import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'info_screen.dart';
import 'level_selection_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  // Keys for screens that need refresh
  final GlobalKey<State<HomeScreen>> _homeKey = GlobalKey();
  final GlobalKey<State<ProfileScreen>> _profileKey = GlobalKey();
  final GlobalKey<State<LevelSelectionScreen>> _levelKey = GlobalKey();
  
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(key: _homeKey),
      const InfoScreen(),
      LevelSelectionScreen(key: _levelKey),
      const LeaderboardScreen(),
      ProfileScreen(key: _profileKey),
    ];
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      // If not on home screen, go back to home
      setState(() {
        _currentIndex = 0;
      });
      return false;
    }
    
    // If on home screen, show exit dialog
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.orange.shade700),
            const SizedBox(width: 10),
            const Text('Keluar Aplikasi?'),
          ],
        ),
        content: const Text('Apakah kamu yakin ingin keluar dari aplikasi?'),
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
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
              
              // Refresh data when switching to Home or Profile tab
              if (index == 0) {
                // Home screen - trigger refresh
                final homeState = _homeKey.currentState;
                if (homeState != null && homeState is State<HomeScreen>) {
                  (homeState as dynamic).loadUserData();
                }
              } else if (index == 4) {
                // Profile screen - trigger refresh
                final profileState = _profileKey.currentState;
                if (profileState != null && profileState is State<ProfileScreen>) {
                  (profileState as dynamic).loadProfile();
                }
              }
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blue.shade700,
            unselectedItemColor: Colors.grey.shade500,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            elevation: 8,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.info_outline_rounded),
                activeIcon: Icon(Icons.info),
                label: 'Info',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.play_circle_outline_rounded),
                activeIcon: Icon(Icons.play_circle),
                label: 'Play',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events_outlined),
                activeIcon: Icon(Icons.emoji_events),
                label: 'Leaderboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
