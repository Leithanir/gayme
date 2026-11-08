import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_session.dart';

/// Single achievement model used across the UI.
class AchievementData {
  const AchievementData({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.progress,
    required this.completed,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final double progress;
  final bool completed;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'color': color,
      'progress': progress,
      'completed': completed,
    };
  }
}

/// Service managing achievement unlocks, persistence, and state notifications.
class AchievementService extends ChangeNotifier {
  static const String keyGamesPlayed = 'achievement_games_played';
  static const String keyTotalScore = 'achievement_total_score';
  static const String keyUnlockedIds = 'achievement_unlocked_ids';

  int _gamesPlayed = 0;
  int _totalScore = 0;
  Set<String> _unlockedIds = {};
  bool _initialized = false;

  int get gamesPlayed => _gamesPlayed;
  int get totalScore => _totalScore;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _gamesPlayed = prefs.getInt(keyGamesPlayed) ?? 0;
    _totalScore = prefs.getInt(keyTotalScore) ?? 0;
    _unlockedIds = (prefs.getStringList(keyUnlockedIds) ?? []).toSet();
    _initialized = true;
    notifyListeners();
  }

  /// Records a completed game session and updates achievement unlocks.
  Future<void> recordSession(GameSession session, {required bool isFilipino}) async {
    await init();

    _gamesPlayed += 1;
    _totalScore += session.score;

    final roundCorrect = session.correctCount;
    final roundAccuracy = session.accuracy;

    // Check conditions for all achievements
    if (_gamesPlayed >= 1) _unlockedIds.add('first_steps');
    if (_gamesPlayed >= 5) _unlockedIds.add('learner_of_stereotypes');
    if (_totalScore >= 1000) _unlockedIds.add('high_scorer');
    if (_gamesPlayed >= 10) _unlockedIds.add('dedicated_player');
    if (roundCorrect > 5) _unlockedIds.add('esteemed_guest');
    if (roundCorrect < 5) _unlockedIds.add('typecaster');
    if (roundAccuracy == 1.0) _unlockedIds.add('definitely_not_judgemental');
    if (isFilipino) _unlockedIds.add('uy_pilipins');

    // Check meta-achievement: Gaypletionist (if all other 8 achievements unlocked)
    final otherCount = _unlockedIds.where((id) => id != 'gaypletionist').length;
    if (otherCount >= 8) {
      _unlockedIds.add('gaypletionist');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyGamesPlayed, _gamesPlayed);
    await prefs.setInt(keyTotalScore, _totalScore);
    await prefs.setStringList(keyUnlockedIds, _unlockedIds.toList());

    notifyListeners();
  }

  bool isUnlocked(String id) => _unlockedIds.contains(id);

  List<AchievementData> getAchievements() {
    final otherUnlockedCount = _unlockedIds.where((id) => id != 'gaypletionist').length;

    return [
      AchievementData(
        id: 'first_steps',
        title: 'First Steps',
        description: 'Play your first game.',
        icon: Icons.play_arrow_rounded,
        color: const Color(0xFF39FF14),
        progress: (_gamesPlayed / 1).clamp(0.0, 1.0),
        completed: isUnlocked('first_steps'),
      ),
      AchievementData(
        id: 'learner_of_stereotypes',
        title: 'Learner of Stereotypes',
        description: 'Play 5 games.',
        icon: Icons.sports_esports_rounded,
        color: const Color(0xFFFF00E6),
        progress: (_gamesPlayed / 5).clamp(0.0, 1.0),
        completed: isUnlocked('learner_of_stereotypes'),
      ),
      AchievementData(
        id: 'high_scorer',
        title: 'High Scorer',
        description: 'Reach a score of 1,000.',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFFFF500),
        progress: (_totalScore / 1000).clamp(0.0, 1.0),
        completed: isUnlocked('high_scorer'),
      ),
      AchievementData(
        id: 'dedicated_player',
        title: 'Dedicated Player',
        description: 'Play 10 games.',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFF00E5FF),
        progress: (_gamesPlayed / 10).clamp(0.0, 1.0),
        completed: isUnlocked('dedicated_player'),
      ),
      AchievementData(
        id: 'esteemed_guest',
        title: 'Esteemed Guest',
        description: 'Play a game with more than 5 correct guesses.',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFF39FF14),
        progress: isUnlocked('esteemed_guest') ? 1.0 : 0.0,
        completed: isUnlocked('esteemed_guest'),
      ),
      AchievementData(
        id: 'typecaster',
        title: 'Typecaster',
        description: 'Play a game with less than 5 correct guesses.',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFFF00E6),
        progress: isUnlocked('typecaster') ? 1.0 : 0.0,
        completed: isUnlocked('typecaster'),
      ),
      AchievementData(
        id: 'definitely_not_judgemental',
        title: 'Definitely (not) Judgemental',
        description: 'Complete a game without mistakes.',
        icon: Icons.stars_rounded,
        color: const Color(0xFFFF00E6),
        progress: isUnlocked('definitely_not_judgemental') ? 1.0 : 0.0,
        completed: isUnlocked('definitely_not_judgemental'),
      ),
      AchievementData(
        id: 'uy_pilipins',
        title: 'Uy, Pilipins!',
        description: 'Play the game on Filipino Language for the first time.',
        icon: Icons.language_rounded,
        color: const Color(0xFFFFF500),
        progress: isUnlocked('uy_pilipins') ? 1.0 : 0.0,
        completed: isUnlocked('uy_pilipins'),
      ),
      AchievementData(
        id: 'gaypletionist',
        title: 'Gaypletionist',
        description: 'Unlock all achievements.',
        icon: Icons.military_tech_rounded,
        color: const Color(0xFFFFF500),
        progress: (otherUnlockedCount / 8).clamp(0.0, 1.0),
        completed: isUnlocked('gaypletionist'),
      ),
    ];
  }
}

/// Scope making [AchievementService] available to descendants.
class AchievementScope extends InheritedNotifier<AchievementService> {
  const AchievementScope({
    super.key,
    required AchievementService service,
    required super.child,
  }) : super(notifier: service);

  static AchievementService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AchievementScope>();
    assert(
      scope != null,
      'No AchievementScope found in context. Wrap your app in an AchievementScope.',
    );
    return scope!.notifier!;
  }

  static AchievementService? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AchievementScope>();
    return scope?.notifier;
  }
}
