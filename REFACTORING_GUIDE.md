# 📁 Refactoring Guide - Code Organization

## Current Problem
File `lib/main.dart` terlalu panjang (~5000 baris) yang membuat:
- ❌ Sulit di-maintain
- ❌ Sulit mencari code
- ❌ Merge conflicts sering terjadi
- ❌ Load time editor lambat

## Proposed Structure

```
lib/
├── main.dart                       # Entry point (minimal)
├── models/
│   └── player.dart                 # Player model
├── services/
│   ├── api_service.dart           # ✅ Already separated
│   └── socket_service.dart        # ✅ Already separated
├── screens/
│   ├── splash_screen.dart         # Splash/Loading screen
│   ├── auth_screen.dart           # Login/Register
│   ├── instructions_screen.dart   # Tutorial/Instructions
│   ├── level_selection_screen.dart # Select level 1-10
│   ├── mode_selection_screen.dart  # Single/Multiplayer choice
│   ├── game_screen.dart           # Main game screen
│   ├── multiplayer/
│   │   ├── lobby_screen.dart      # Create/Join room
│   │   ├── waiting_room_screen.dart # Wait for players
│   │   └── multiplayer_game_screen.dart # Multiplayer game
│   └── result_screen.dart         # Game over/results
└── widgets/
    ├── board_widget.dart          # Game board UI
    ├── dice_widget.dart           # Dice animation
    ├── quiz_dialog.dart           # Quiz popup
    └── player_indicator.dart      # Player position indicator
```

## Migration Steps

### Phase 1: Extract Models (✅ DONE)
- [x] Create `lib/models/player.dart`

### Phase 2: Extract Screens (IN PROGRESS)
- [x] Create `lib/screens/splash_screen.dart`
- [ ] Create `lib/screens/auth_screen.dart`
- [ ] Create `lib/screens/instructions_screen.dart`
- [ ] Create `lib/screens/level_selection_screen.dart`
- [ ] Create `lib/screens/mode_selection_screen.dart`
- [ ] Create `lib/screens/game_screen.dart`
- [ ] Create `lib/screens/multiplayer/lobby_screen.dart`
- [ ] Create `lib/screens/multiplayer/waiting_room_screen.dart`
- [ ] Create `lib/screens/multiplayer/multiplayer_game_screen.dart`

### Phase 3: Extract Widgets (TODO)
- [ ] Extract reusable widgets from screens
- [ ] Create widget files in `lib/widgets/`

### Phase 4: Update main.dart (TODO)
- [ ] Keep only `main()` and `TBEducationGameApp`
- [ ] Import all screens
- [ ] Clean and minimal

## How to Refactor

### Step 1: Backup Current Code
```bash
cp lib/main.dart lib/main.dart.backup
```

### Step 2: Create New Files
For each screen in `main.dart`:
1. Create new file in `lib/screens/`
2. Copy screen class + state class
3. Add necessary imports
4. Test compilation

### Step 3: Update Imports
In each new file, add imports:
```dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/player.dart';
import 'other_screen.dart'; // Import screens that this screen navigates to
```

### Step 4: Replace main.dart
Create new minimal `main.dart`:
```dart
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const TBEducationGameApp());
}

class TBEducationGameApp extends StatelessWidget {
  const TBEducationGameApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Ular Tangga Edukasi TBC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}
```

### Step 5: Test Everything
```bash
flutter clean
flutter pub get
flutter run
```

## Benefits After Refactoring

### ✅ Better Organization
- Setiap screen punya file sendiri
- Mudah menemukan code
- Clear separation of concerns

### ✅ Easier Maintenance
- Update satu screen tidak affect yang lain
- Easier to read and understand
- Less scrolling

### ✅ Team Collaboration
- Kurangi merge conflicts
- Multiple developers dapat work on different screens
- Clear ownership per file

### ✅ Performance
- Editor load faster
- Hot reload lebih responsive
- Easier debugging

### ✅ Reusability
- Widgets dapat di-reuse
- Models shareable
- Services independent

## File Size After Refactoring

**Before:**
```
lib/main.dart: 5003 lines
```

**After:**
```
lib/main.dart: ~30 lines
lib/screens/*: 10-15 files @ 200-500 lines each
lib/models/*: 1-3 files @ 20-50 lines each
lib/widgets/*: 5-10 files @ 50-200 lines each
```

## Quick Commands

### Create all directories
```bash
mkdir -p lib/screens/multiplayer
mkdir -p lib/models
mkdir -p lib/widgets
```

### Check file sizes
```bash
wc -l lib/main.dart
wc -l lib/screens/*.dart
```

### Find class definitions (for extraction)
```bash
grep -n "^class.*Screen" lib/main.dart
```

## Common Patterns

### Screen Template
```dart
import 'package:flutter/material.dart';
// Add other imports

class MyScreen extends StatefulWidget {
  const MyScreen({Key? key}) : super(key: key);

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  // State variables
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // UI
    );
  }
}
```

### Widget Template
```dart
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  
  const MyWidget({
    Key? key,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // UI
    );
  }
}
```

## Navigation Updates

When refactoring, update all `Navigator.push` calls:

**Before:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => GameScreen()),
);
```

**After:**
```dart
import '../screens/game_screen.dart';

Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const GameScreen()),
);
```

## Testing Checklist

After refactoring, test all:
- [ ] Splash screen animation
- [ ] Login/Register flow
- [ ] Guest mode (skip login)
- [ ] Level selection
- [ ] Mode selection (guest restriction)
- [ ] Single player game
- [ ] Multiplayer lobby
- [ ] Multiplayer game
- [ ] Quiz dialogs
- [ ] Game over screens
- [ ] Navigation between all screens
- [ ] Hot reload works
- [ ] No compilation errors

## Gradual Migration Strategy

Don't do everything at once! Migrate gradually:

### Week 1: Foundation
- [x] Extract models
- [x] Extract splash screen
- [ ] Extract auth screen

### Week 2: Game Screens
- [ ] Extract instructions screen
- [ ] Extract level selection
- [ ] Extract mode selection
- [ ] Extract game screen

### Week 3: Multiplayer
- [ ] Extract multiplayer screens
- [ ] Extract game logic into separate classes

### Week 4: Polish
- [ ] Extract reusable widgets
- [ ] Optimize imports
- [ ] Add documentation
- [ ] Update README

## Auto-refactoring Tools

### VS Code Extensions
- **Flutter Tree** - Visualize widget tree
- **Dart Data Class Generator** - Generate model classes
- **Better Comments** - Mark TODOs

### Commands
```bash
# Find all screen classes
grep -n "class.*Screen" lib/main.dart

# Count lines per class (approximate)
awk '/^class.*Screen/,/^class/' lib/main.dart | wc -l
```

## Resources

- [Flutter Style Guide](https://flutter.dev/docs/development/ui/widgets)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Project Structure Best Practices](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple)

---

**Status:** Phase 1 Complete ✅ | Phase 2 In Progress 🔄

**Next Action:** Continue extracting screens one by one, starting with AuthScreen
