// =======================
// Team Members: Luna Da Silva
// Assignment: In-Class Activity #5 – Digital Pet App with State Management
// Notes:
// - Meets core app + stateful logic requirements.
// - Part (1) features implemented: Dynamic color, Mood indicator, Pet name customization,
//   Hunger increases over time (Timer), Win/Loss conditions.
// - Part (2) features implemented: Energy bar widget, Energy level logic,
//   Activity selection (dropdown), State updates based on activity.
// =======================

import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DigitalPetApp(),
  ));
}

class DigitalPetApp extends StatefulWidget {
  const DigitalPetApp({super.key});

  @override
  State<DigitalPetApp> createState() => _DigitalPetAppState();
}

enum Activity { walk, nap, train, groom }

class _DigitalPetAppState extends State<DigitalPetApp> {
  // ------------ Core Pet State ------------
  String petName = '';
  bool nameLocked = false;

  int happinessLevel = 50; // 0..100
  int hungerLevel = 50;    // 0..100 (higher = hungrier)
  int energyLevel = 60;    // 0..100

  Activity? selectedActivity;

  // ------------ Timers & Win/Loss Tracking ------------
  Timer? _hungerTimer;
  DateTime? _happyStreakStart;
  bool _gameOverShown = false;
  bool _winShown = false;

  // ------------ Controllers ------------
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Start the periodic hunger timer (every 30 seconds).
    // Increases hunger, may reduce happiness, and drains a bit of energy.
    _hungerTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _applyPeriodicNeedsTick();
    });
  }

  @override
  void dispose() {
    _hungerTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  // ------------ Helpers ------------
  int _clamp(int value) => value.clamp(0, 100);

  void _applyPeriodicNeedsTick() {
    setState(() {
      hungerLevel = _clamp(hungerLevel + 5);
      energyLevel = _clamp(energyLevel - 5);

      // If very hungry, happiness drops faster
      if (hungerLevel >= 80) {
        happinessLevel = _clamp(happinessLevel - 10);
      } else if (hungerLevel >= 60) {
        happinessLevel = _clamp(happinessLevel - 5);
      }

      _checkEndConditions();
      _updateHappyStreak();
    });
  }

  void _updateHappyStreak() {
    // Track time spent >80 happiness to detect win at 3 minutes.
    if (happinessLevel > 80) {
      _happyStreakStart ??= DateTime.now();
      final elapsed =
          DateTime.now().difference(_happyStreakStart!).inSeconds;
      if (!_winShown && elapsed >= 180) {
        _winShown = true;
        _showDialog(
          title: 'You Win! 🎉',
          message:
              '$petName stayed super happy (>80) for 3 minutes. You win!',
        );
      }
    } else {
      _happyStreakStart = null; // reset streak if not >80
    }
  }

  void _checkEndConditions() {
    // Loss condition: hunger == 100 && happiness <= 10
    if (!_gameOverShown && hungerLevel >= 100 && happinessLevel <= 10) {
      _gameOverShown = true;
      _showDialog(
        title: 'Game Over 💀',
        message:
            '$petName is starving (Hunger 100) and very sad (Happiness ≤ 10).',
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetGame(keepName: true);
            },
            child: const Text('Try Again'),
          ),
        ],
      );
    }
  }

  void _resetGame({bool keepName = false}) {
    setState(() {
      if (!keepName) {
        petName = '';
        _nameController.clear();
        nameLocked = false;
      }
      happinessLevel = 50;
      hungerLevel = 40;
      energyLevel = 60;
      selectedActivity = null;
      _happyStreakStart = null;
      _gameOverShown = false;
      _winShown = false;
    });
  }

  // ------------ Actions ------------
  void _lockName() {
    final name = _nameController.text.trim();
    setState(() {
      petName = name.isEmpty ? 'Your Pet' : name;
      nameLocked = true;
    });
  }

  void _playWithPet() {
    setState(() {
      if (energyLevel <= 5) {
        // Too tired — tiny penalty for pushing it
        happinessLevel = _clamp(happinessLevel - 5);
      } else {
        happinessLevel = _clamp(happinessLevel + 10);
        energyLevel = _clamp(energyLevel - 10);
      }
      // Playing makes a bit hungrier
      hungerLevel = _clamp(hungerLevel + 5);

      // If too hungry, happiness dips after play
      if (hungerLevel < 30) {
        happinessLevel = _clamp(happinessLevel - 5);
      }

      _checkEndConditions();
      _updateHappyStreak();
    });
  }

  void _feedPet() {
    setState(() {
      hungerLevel = _clamp(hungerLevel - 20);
      happinessLevel = _clamp(happinessLevel + 5);
      energyLevel = _clamp(energyLevel + 5);

      _checkEndConditions();
      _updateHappyStreak();
    });
  }

  void _doSelectedActivity() {
    if (selectedActivity == null) return;

    setState(() {
      switch (selectedActivity!) {
        case Activity.walk:
          // Nice walk boosts mood, costs energy, increases hunger
          happinessLevel = _clamp(happinessLevel + 10);
          energyLevel = _clamp(energyLevel - 15);
          hungerLevel = _clamp(hungerLevel + 5);
          break;
        case Activity.nap:
          // Nap restores energy, small mood boost, no hunger change
          energyLevel = _clamp(energyLevel + 25);
          happinessLevel = _clamp(happinessLevel + 5);
          break;
        case Activity.train:
          // Training is intensive: bigger mood gain, more energy drain, more hunger
          happinessLevel = _clamp(happinessLevel + 15);
          energyLevel = _clamp(energyLevel - 20);
          hungerLevel = _clamp(hungerLevel + 10);
          break;
        case Activity.groom:
          // Grooming: small energy use, small hunger, decent mood bump
          happinessLevel = _clamp(happinessLevel + 8);
          energyLevel = _clamp(energyLevel - 5);
          hungerLevel = _clamp(hungerLevel + 2);
          break;
      }

      _checkEndConditions();
      _updateHappyStreak();
    });
  }

  // ------------ UI helpers ------------
  Color _petColor() {
    if (happinessLevel > 70) return Colors.green;
    if (happinessLevel >= 30) return Colors.yellow.shade700;
    return Colors.red;
  }

  String _moodText() {
    if (happinessLevel > 70) return 'Happy 😀';
    if (happinessLevel >= 30) return 'Neutral 😐';
    return 'Unhappy 😢';
  }

  String _activityLabel(Activity a) {
    switch (a) {
      case Activity.walk:
        return 'Walk';
      case Activity.nap:
        return 'Nap';
      case Activity.train:
        return 'Train';
      case Activity.groom:
        return 'Groom';
    }
  }

  void _showDialog({
    required String title,
    required String message,
    List<Widget>? actions,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: actions == null,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: actions ??
            [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
      ),
    );
  }

  // ------------ Build ------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Pet'),
        actions: [
          IconButton(
            tooltip: 'Reset (keep name)',
            onPressed: () => _resetGame(keepName: true),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Full Reset',
            onPressed: () => _resetGame(keepName: false),
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: nameLocked ? _buildGameUI() : _buildNameSetup(),
        ),
      ),
    );
  }

  // First screen: name customization
  Widget _buildNameSetup() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Name your pet",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'e.g., Pixel, Coco, Byte',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.pets),
                ),
                onSubmitted: (_) => _lockName(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _lockName,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Confirm Name'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Tip: You can fully reset later with the restart button in the top bar.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Main gameplay UI
  Widget _buildGameUI() {
    final petCircle = Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _petColor().withOpacity(0.2),
        border: Border.all(color: _petColor(), width: 4),
      ),
      alignment: Alignment.center,
      child: ClipOval(
        child: SizedBox(
          width: 150,
          height: 150,
          child: _PetImage(colorFallback: _petColor()),
        ),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Meet $petName',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                _moodText(),
                style: TextStyle(
                  fontSize: 18,
                  color: _petColor().withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              petCircle,
              const SizedBox(height: 24),

              // Stats
              _StatTile(
                label: 'Happiness',
                value: happinessLevel,
                icon: Icons.emoji_emotions,
              ),
              const SizedBox(height: 10),
              _StatTile(
                label: 'Hunger',
                value: hungerLevel,
                icon: Icons.fastfood,
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Energy',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: energyLevel / 100.0,
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$energyLevel / 100',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Actions row
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _playWithPet,
                    icon: const Icon(Icons.sports_tennis),
                    label: const Text('Play with Pet'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _feedPet,
                    icon: const Icon(Icons.restaurant),
                    label: const Text('Feed Pet'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Activity selection
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Activity>(
                      value: selectedActivity,
                      decoration: InputDecoration(
                        labelText: 'Choose Activity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.event_note),
                      ),
                      items: Activity.values
                          .map((a) => DropdownMenuItem<Activity>(
                                value: a,
                                child: Text(_activityLabel(a)),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() {
                        selectedActivity = val;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _doSelectedActivity,
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      child: Text('Do Activity'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Hints
              _HintCard(
                lines: const [
                  '• Happiness > 80 for 3 minutes → You win 🎉',
                  '• Hunger 100 and Happiness ≤ 10 → Game Over 💀',
                  '• Hunger rises every 30 seconds, so remember to feed!',
                  '• Energy fuels activities — naps restore it.',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Pet image widget: tries to load assets/pet.png; falls back to icon if missing.
class _PetImage extends StatelessWidget {
  final Color colorFallback;
  const _PetImage({required this.colorFallback});

  @override
  Widget build(BuildContext context) {
    // Attempt to load a transparent PNG from assets.
    // To enable, add to pubspec.yaml:
    // flutter:
    //   assets:
    //     - assets/pet.png
    return Image.asset(
      'assets/pet.png',
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) {
        // Fallback: cute pet icon tinted to mood color
        return Icon(Icons.pets, size: 120, color: colorFallback);
      },
    );
  }
}

// Reusable stat tile
class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$label: $value',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// Simple hint card
class _HintCard extends StatelessWidget {
  final List<String> lines;
  const _HintCard({required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    t,
                    style: const TextStyle(fontSize: 14),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
