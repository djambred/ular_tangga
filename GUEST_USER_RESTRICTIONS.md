# Guest User Restrictions

## Overview
Guest users (users who skip login via "Lewati" button) are now restricted to **Single Player mode only**. This ensures multiplayer features are available exclusively to registered and authenticated users.

## Implementation Details

### Changes Made

#### 1. GameModeSelectionScreen Conversion
- Changed from `StatelessWidget` to `StatefulWidget`
- Added authentication state management
- Added loading state while checking login status

#### 2. Authentication Check
```dart
final ApiService _apiService = ApiService();
bool _isLoggedIn = false;
bool _isLoading = true;

@override
void initState() {
  super.initState();
  _checkLoginStatus();
}

Future<void> _checkLoginStatus() async {
  final loggedIn = await _apiService.isLoggedIn();
  setState(() {
    _isLoggedIn = loggedIn;
    _isLoading = false;
  });
}
```

#### 3. Conditional UI Rendering
**For Logged-In Users:**
- See active Multiplayer button (orange/red gradient)
- Can navigate to MultiplayerLobbyScreen
- Full access to all features

**For Guest Users:**
- See locked Multiplayer button (grey)
- Button shows lock icon and "Login untuk bermain multiplayer"
- Tapping shows login required dialog
- Can still play Single Player without restrictions

### New UI Components

#### Locked Mode Button
```dart
Widget _buildLockedModeButton({
  required BuildContext context,
  required String title,
  required String subtitle,
  required IconData icon,
  required VoidCallback onTap,
})
```
- Grey background with border
- Lock icon instead of mode icon
- Dimmed text to indicate disabled state
- Login icon on the right
- Still clickable to show login prompt

#### Login Required Dialog
```dart
void _showLoginRequiredDialog(BuildContext context)
```
- Clear explanation: "Fitur multiplayer hanya tersedia untuk pengguna yang sudah login"
- Two action buttons:
  - **Batal**: Close dialog and stay on screen
  - **Login Sekarang**: Navigate to AuthScreen

## User Experience Flow

### Guest User Flow
1. Guest opens app → Skips login with "Lewati"
2. Guest selects level
3. Guest sees mode selection:
   - ✅ **Single Player**: Available (green button)
   - 🔒 **Multiplayer**: Locked (grey button)
4. Guest taps Multiplayer → Login prompt appears
5. Guest can:
   - Choose "Login Sekarang" → Redirected to AuthScreen
   - Choose "Batal" → Stay and play Single Player

### Logged-In User Flow
1. User logs in with credentials
2. User selects level
3. User sees mode selection:
   - ✅ **Single Player**: Available (green button)
   - ✅ **Multiplayer**: Available (orange/red button)
4. User can access both modes freely

## Benefits

### Security
- Multiplayer features require authentication
- Prevents anonymous abuse in multiplayer games
- Ensures accountability for multiplayer actions

### User Management
- Encourages user registration
- Builds user database for analytics
- Enables personalized features (leaderboards, history, etc.)

### Feature Gating
- Clear value proposition for registration
- Soft paywall approach (feature-based)
- Non-intrusive conversion funnel

## Testing Checklist

- [ ] Guest user sees locked multiplayer button
- [ ] Guest user can still play single player
- [ ] Guest taps multiplayer → Dialog appears
- [ ] "Login Sekarang" button navigates to AuthScreen
- [ ] "Batal" button closes dialog
- [ ] Logged-in user sees active multiplayer button
- [ ] Logged-in user can access multiplayer
- [ ] UI states transition smoothly
- [ ] Loading indicator shows during auth check
- [ ] No compilation errors

## Future Enhancements

### Possible Improvements
1. **Guest Single Player Features**
   - Save progress locally (SharedPreferences)
   - Local leaderboard for guest users
   - Option to convert guest progress to account

2. **Better Onboarding**
   - Tooltip explaining multiplayer benefits
   - "Try Single Player First" suggestion
   - Achievement system to encourage registration

3. **Social Features**
   - Friend system for multiplayer invites
   - Chat in multiplayer games
   - Clan/team features

4. **Analytics**
   - Track guest → registered user conversion rate
   - Monitor which features drive registration
   - A/B test different prompts

## Technical Notes

### API Service Integration
Uses existing `ApiService.isLoggedIn()` method:
```dart
Future<bool> isLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  return token != null && token.isNotEmpty;
}
```

### State Management
- Simple setState() approach
- No external state management needed
- Authentication state checked on screen init
- Future enhancement: Use Provider/Riverpod for global auth state

### Navigation Flow
```
AuthScreen (optional) 
  → LevelSelectionScreen 
    → GameModeSelectionScreen 
      → [If logged in] MultiplayerLobbyScreen
      → [If guest] Login prompt → AuthScreen
```

## Related Files
- `lib/main.dart` - GameModeSelectionScreen implementation
- `lib/services/api_service.dart` - Authentication service
- `TESTING.md` - Test scenarios
- `README.md` - User documentation

## Version History
- **v1.0.0** (2025-01-XX): Initial implementation
  - Guest users restricted to single player
  - Login prompt dialog added
  - Locked mode button design
