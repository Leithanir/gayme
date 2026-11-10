import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementDefinition {
  final String id;
  final String name;
  final String task;
  final String? hint;
  final bool isHidden;
  final IconData icon;
  final Color color;

  const AchievementDefinition({
    required this.id,
    required this.name,
    required this.task,
    this.hint,
    required this.isHidden,
    required this.icon,
    required this.color,
  });
}

class AchievementManager extends ChangeNotifier {
  final Set<String> _unlockedAchievementIds = {'first_steps'};
  final Set<String> _encounteredSituationIds = {};
  final Set<String> _correctlyAnsweredSituationIds = {};
  final Set<String> _correctlyAnsweredStereotypeIds = {};
  final Set<String> _correctlyAnsweredRespectfulIds = {};

  int _gamesPlayed = 0;
  int _gamesCompleted = 0;
  int _totalCorrect = 0;
  int _totalWrong = 0;
  int _totalAnswered = 0;
  int _currentCorrectStreak = 0;
  int _explanationsReadCount = 0;
  bool _hasDroppedBelow50 = false;
  bool _hasReached90AfterDrop = false;
  int _quietObserverCount = 0;
  int _lastGameFinishedTimestamp = 0;

  // Game-specific active session state
  int gameCorrectCount = 0;
  int gameWrongCount = 0;
  List<bool> gameAnswerHistory = [];
  List<String> gameSwipeDirections = [];
  DateTime? cardStartTime;
  bool lastAnswerWasIncorrect = false;

  AchievementManager() {
    initPersistence();
  }

  Future<void> initPersistence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unlocked = prefs.getStringList('unlocked_achievements');
      if (unlocked != null) {
        _unlockedAchievementIds.clear();
        _unlockedAchievementIds.addAll(unlocked);
      }
      _unlockedAchievementIds.add('first_steps');

      _encounteredSituationIds.addAll(prefs.getStringList('encountered_situations') ?? []);
      _correctlyAnsweredSituationIds.addAll(prefs.getStringList('correct_situations') ?? []);
      _correctlyAnsweredStereotypeIds.addAll(prefs.getStringList('correct_stereotypes') ?? []);
      _correctlyAnsweredRespectfulIds.addAll(prefs.getStringList('correct_respectful') ?? []);

      _gamesPlayed = prefs.getInt('games_played') ?? 0;
      _gamesCompleted = prefs.getInt('games_completed') ?? 0;
      _totalCorrect = prefs.getInt('total_correct') ?? 0;
      _totalWrong = prefs.getInt('total_wrong') ?? 0;
      _totalAnswered = prefs.getInt('total_answered') ?? 0;
      _currentCorrectStreak = prefs.getInt('current_streak') ?? 0;
      _explanationsReadCount = prefs.getInt('explanations_read') ?? 0;
      _hasDroppedBelow50 = prefs.getBool('dropped_below_50') ?? false;
      _hasReached90AfterDrop = prefs.getBool('reached_90_after') ?? false;
      _quietObserverCount = prefs.getInt('quiet_observer_count') ?? 0;
      _lastGameFinishedTimestamp = prefs.getInt('last_game_finished_ts') ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Achievement persistence init error: $e');
    }
  }

  Future<void> _savePersistence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('unlocked_achievements', _unlockedAchievementIds.toList());
      await prefs.setStringList('encountered_situations', _encounteredSituationIds.toList());
      await prefs.setStringList('correct_situations', _correctlyAnsweredSituationIds.toList());
      await prefs.setStringList('correct_stereotypes', _correctlyAnsweredStereotypeIds.toList());
      await prefs.setStringList('correct_respectful', _correctlyAnsweredRespectfulIds.toList());

      await prefs.setInt('games_played', _gamesPlayed);
      await prefs.setInt('games_completed', _gamesCompleted);
      await prefs.setInt('total_correct', _totalCorrect);
      await prefs.setInt('total_wrong', _totalWrong);
      await prefs.setInt('total_answered', _totalAnswered);
      await prefs.setInt('current_streak', _currentCorrectStreak);
      await prefs.setInt('explanations_read', _explanationsReadCount);
      await prefs.setBool('dropped_below_50', _hasDroppedBelow50);
      await prefs.setBool('reached_90_after', _hasReached90AfterDrop);
      await prefs.setInt('quiet_observer_count', _quietObserverCount);
      await prefs.setInt('last_game_finished_ts', _lastGameFinishedTimestamp);
    } catch (e) {
      debugPrint('Achievement persistence save error: $e');
    }
  }

  bool isUnlocked(String id) => _unlockedAchievementIds.contains(id);

  // Exactly 30 Achievements Definition (15 Visible, 15 Hidden)
  static const List<AchievementDefinition> allAchievements = [
    // --- 15 VISIBLE ACHIEVEMENTS ---
    AchievementDefinition(
      id: 'first_steps',
      name: 'FIRST STEPS',
      task: 'Play your first game.',
      isHidden: false,
      icon: Icons.play_arrow_rounded,
      color: Color(0xFF39FF14),
    ),
    AchievementDefinition(
      id: 'sharp_eye',
      name: 'SHARP EYE',
      task: 'Get 5 correct answers.',
      isHidden: false,
      icon: Icons.remove_red_eye_rounded,
      color: Color(0xFF00E5FF),
    ),
    AchievementDefinition(
      id: 'open_mind',
      name: 'OPEN MIND',
      task: 'Complete 10 situations.',
      isHidden: false,
      icon: Icons.psychology_rounded,
      color: Color(0xFFFF00E6),
    ),
    AchievementDefinition(
      id: 'breaking_labels',
      name: 'BREAKING LABELS',
      task: 'Get 10 correct answers in a row.',
      isHidden: false,
      icon: Icons.link_off_rounded,
      color: Color(0xFFFFF500),
    ),
    AchievementDefinition(
      id: 'fair_judgment',
      name: 'FAIR JUDGMENT',
      task: 'Finish a game with at least 80% accuracy.',
      isHidden: false,
      icon: Icons.balance_rounded,
      color: Color(0xFF39FF14),
    ),
    AchievementDefinition(
      id: 'no_assumptions',
      name: 'NO ASSUMPTIONS',
      task: 'Get a perfect game.',
      isHidden: false,
      icon: Icons.stars_rounded,
      color: Color(0xFFFF00E6),
    ),
    AchievementDefinition(
      id: 'perspective_shift',
      name: 'PERSPECTIVE SHIFT',
      task: 'Play 5 games.',
      isHidden: false,
      icon: Icons.swap_horiz_rounded,
      color: Color(0xFF00E5FF),
    ),
    AchievementDefinition(
      id: 'pattern_breaker',
      name: 'PATTERN BREAKER',
      task: 'Play 10 games.',
      isHidden: false,
      icon: Icons.bolt_rounded,
      color: Color(0xFFFFF500),
    ),
    AchievementDefinition(
      id: 'knowledge_seeker',
      name: 'KNOWLEDGE SEEKER',
      task: 'Read 20 explanations.',
      isHidden: false,
      icon: Icons.menu_book_rounded,
      color: Color(0xFF39FF14),
    ),
    AchievementDefinition(
      id: 'situation_collector',
      name: 'SITUATION COLLECTOR',
      task: 'Encounter all 50 unique situations.',
      isHidden: false,
      icon: Icons.folder_special_rounded,
      color: Color(0xFFFF00E6),
    ),
    AchievementDefinition(
      id: 'situation_master',
      name: 'SITUATION MASTER',
      task: 'Correctly answer all 50 unique situations at least once.',
      isHidden: false,
      icon: Icons.verified_rounded,
      color: Color(0xFF00E5FF),
    ),
    AchievementDefinition(
      id: 'stereotype_breaker',
      name: 'STEREOTYPE BREAKER',
      task: 'Correctly identify all 25 stereotype situations.',
      isHidden: false,
      icon: Icons.heart_broken_rounded,
      color: Color(0xFFFFF500),
    ),
    AchievementDefinition(
      id: 'respect_champion',
      name: 'RESPECT CHAMPION',
      task: 'Correctly identify all 25 respectful situations.',
      isHidden: false,
      icon: Icons.favorite_rounded,
      color: Color(0xFF39FF14),
    ),
    AchievementDefinition(
      id: 'consistent_thinker',
      name: 'CONSISTENT THINKER',
      task: 'Maintain at least 80% overall accuracy.',
      isHidden: false,
      icon: Icons.trending_up_rounded,
      color: Color(0xFFFF00E6),
    ),
    AchievementDefinition(
      id: 'no_stereotype_master',
      name: 'NO STEREOTYPE MASTER',
      task: 'Correctly answer all 50 situations and complete both 25-situation categories.',
      isHidden: false,
      icon: Icons.military_tech_rounded,
      color: Color(0xFFFFF500),
    ),

    // --- 15 HIDDEN ACHIEVEMENTS ---
    AchievementDefinition(
      id: 'walking_red_flag',
      name: 'WALKING RED FLAG',
      task: 'Get 10 wrong answers across games.',
      hint: 'Not every choice can be the right one.',
      isHidden: true,
      icon: Icons.flag_rounded,
      color: Color(0xFFE53935),
    ),
    AchievementDefinition(
      id: 'professional_assumer',
      name: 'PROFESSIONAL ASSUMER',
      task: 'Get every swipe wrong in a 10-question game.',
      hint: 'Sometimes, first impressions can be misleading.',
      isHidden: true,
      icon: Icons.visibility_off_rounded,
      color: Color(0xFFE53935),
    ),
    AchievementDefinition(
      id: 'no_thoughts_just_vibes',
      name: 'NO THOUGHTS, JUST VIBES',
      task: 'Swipe the same direction 10 times in a row.',
      hint: 'You seem to have a favorite.',
      isHidden: true,
      icon: Icons.waves_rounded,
      color: Color(0xFF00E5FF),
    ),
    AchievementDefinition(
      id: 'plot_twist',
      name: 'PLOT TWIST',
      task: 'Get the first 9 swipes wrong and the final swipe correct.',
      hint: "There's always room for a comeback.",
      isHidden: true,
      icon: Icons.redo_rounded,
      color: Color(0xFFFFF500),
    ),
    AchievementDefinition(
      id: 'speed_of_judgment',
      name: 'SPEED OF JUDGMENT',
      task: 'Swipe extremely quickly on a situation.',
      hint: "You didn't waste much time thinking.",
      isHidden: true,
      icon: Icons.flash_on_rounded,
      color: Color(0xFF39FF14),
    ),
    AchievementDefinition(
      id: 'character_development',
      name: 'CHARACTER DEVELOPMENT',
      task: 'Drop below 50% accuracy, then later reach 90%_.',
      hint: 'Mistakes are part of learning.',
      isHidden: true,
      icon: Icons.trending_flat_rounded,
      color: Color(0xFFFF00E6),
    ),
    AchievementDefinition(
      id: 'lucky_guess',
      name: 'LUCKY GUESS',
      task: 'Get a correct swipe immediately after an incorrect one.',
      hint: 'Even you might surprise yourself.',
      isHidden: true,
      icon: Icons.casino_rounded,
      color: Color(0xFF00E5FF),
    ),
    AchievementDefinition(
      id: 'recovery',
      name: 'RECOVERY',
      task: 'Get 3 correct answers in a row after getting a wrong answer.',
      hint: "One mistake doesn't decide everything.",
      isHidden: true,
      icon: Icons.healing_rounded,
      color: Color(0xFF39FF14),
    ),
    AchievementDefinition(
      id: 'overthinker',
      name: 'OVERTHINKER',
      task: 'Take an unusually long time before swiping.',
      hint: "It's not always that complicated.",
      isHidden: true,
      icon: Icons.hourglass_empty_rounded,
      color: Color(0xFFFFF500),
    ),
    AchievementDefinition(
      id: 'mixed_thinker',
      name: 'MIXED THINKER',
      task: 'Get both correct and incorrect answers in the same game.',
      hint: "You don't always see things the same way.",
      isHidden: true,
      icon: Icons.shuffle_rounded,
      color: Color(0xFFFF00E6),
    ),
    AchievementDefinition(
      id: 'one_more_game',
      name: 'ONE MORE GAME',
      task: 'Start another game shortly after finishing one.',
      hint: 'You could stop now... but why?',
      isHidden: true,
      icon: Icons.replay_rounded,
      color: Color(0xFF00E5FF),
    ),
    AchievementDefinition(
      id: 'close_call',
      name: 'CLOSE CALL',
      task: 'Finish a game with accuracy close to 50%.',
      hint: "Sometimes, it's almost too close to call.",
      isHidden: true,
      icon: Icons.show_chart_rounded,
      color: Color(0xFFFFF500),
    ),
    AchievementDefinition(
      id: 'unpredictable',
      name: 'UNPREDICTABLE',
      task: 'Have a highly mixed pattern of correct and incorrect swipes.',
      hint: "Even you don't know what you'll choose next.",
      isHidden: true,
      icon: Icons.extension_rounded,
      color: Color(0xFFFF00E6),
    ),
    AchievementDefinition(
      id: 'quiet_observer',
      name: 'QUIET OBSERVER',
      task: 'Encounter many situations while taking your time before swiping.',
      hint: 'Take your time. Look closely.',
      isHidden: true,
      icon: Icons.remove_red_eye_outlined,
      color: Color(0xFF39FF14),
    ),
    AchievementDefinition(
      id: 'ultimate_thinker',
      name: 'ULTIMATE THINKER',
      task: 'Complete 20 games.',
      hint: "You've come a long way.",
      isHidden: true,
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFFFFF500),
    ),
  ];

  String getProgressString(String id) {
    switch (id) {
      case 'situation_collector':
        return '${_encounteredSituationIds.length}/50';
      case 'situation_master':
        return '${_correctlyAnsweredSituationIds.length}/50';
      case 'stereotype_breaker':
        return '${_correctlyAnsweredStereotypeIds.length}/25';
      case 'respect_champion':
        return '${_correctlyAnsweredRespectfulIds.length}/25';
      case 'sharp_eye':
        return '${_totalCorrect.clamp(0, 5)}/5';
      case 'open_mind':
        return '${_totalAnswered.clamp(0, 10)}/10';
      case 'perspective_shift':
        return '${_gamesPlayed.clamp(0, 5)}/5';
      case 'pattern_breaker':
        return '${_gamesPlayed.clamp(0, 10)}/10';
      case 'knowledge_seeker':
        return '${_explanationsReadCount.clamp(0, 20)}/20';
      case 'walking_red_flag':
        return '${_totalWrong.clamp(0, 10)}/10';
      case 'ultimate_thinker':
        return '${_gamesCompleted.clamp(0, 20)}/20';
      default:
        return '';
    }
  }

  AchievementDefinition? _tryUnlock(String id) {
    if (_unlockedAchievementIds.contains(id)) return null;
    _unlockedAchievementIds.add(id);
    _savePersistence();
    notifyListeners();

    for (final def in allAchievements) {
      if (def.id == id) return def;
    }
    return null;
  }

  void recordGameStarted() {
    _gamesPlayed++;
    if (_lastGameFinishedTimestamp > 0) {
      final diff = DateTime.now().millisecondsSinceEpoch - _lastGameFinishedTimestamp;
      if (diff > 0 && diff <= 30000) {
        _tryUnlock('one_more_game');
      }
    }

    _tryUnlock('first_steps');
    if (_gamesPlayed >= 5) _tryUnlock('perspective_shift');
    if (_gamesPlayed >= 10) _tryUnlock('pattern_breaker');
    if (_gamesCompleted >= 20) _tryUnlock('ultimate_thinker');

    gameCorrectCount = 0;
    gameWrongCount = 0;
    gameAnswerHistory.clear();
    gameSwipeDirections.clear();
    cardStartTime = DateTime.now();
    lastAnswerWasIncorrect = false;

    _savePersistence();
  }

  AchievementDefinition? recordAnswer({
    required String situationId,
    required bool isStereotype,
    required bool isCorrect,
    required double elapsedSeconds,
    required String swipeDirection,
  }) {
    _encounteredSituationIds.add(situationId);
    _totalAnswered++;
    gameSwipeDirections.add(swipeDirection);

    if (elapsedSeconds < 1.0) {
      final unlocked = _tryUnlock('speed_of_judgment');
      if (unlocked != null) return unlocked;
    }
    if (elapsedSeconds > 15.0) {
      final unlocked = _tryUnlock('overthinker');
      if (unlocked != null) return unlocked;
    }
    if (elapsedSeconds > 10.0) {
      _quietObserverCount++;
      if (_quietObserverCount >= 5) {
        final unlocked = _tryUnlock('quiet_observer');
        if (unlocked != null) return unlocked;
      }
    }

    if (gameSwipeDirections.length >= 10) {
      final last10 = gameSwipeDirections.sublist(gameSwipeDirections.length - 10);
      if (last10.every((d) => d == last10.first)) {
        final unlocked = _tryUnlock('no_thoughts_just_vibes');
        if (unlocked != null) return unlocked;
      }
    }

    AchievementDefinition? triggered;

    if (isCorrect) {
      _totalCorrect++;
      _currentCorrectStreak++;
      gameCorrectCount++;
      gameAnswerHistory.add(true);

      _correctlyAnsweredSituationIds.add(situationId);
      if (isStereotype) {
        _correctlyAnsweredStereotypeIds.add(situationId);
      } else {
        _correctlyAnsweredRespectfulIds.add(situationId);
      }

      if (lastAnswerWasIncorrect) {
        triggered = _tryUnlock('lucky_guess') ?? triggered;
      }

      if (gameAnswerHistory.length >= 4) {
        final h = gameAnswerHistory;
        if (h[h.length - 4] == false &&
            h[h.length - 3] == true &&
            h[h.length - 2] == true &&
            h[h.length - 1] == true) {
          triggered = _tryUnlock('recovery') ?? triggered;
        }
      }

      if (_currentCorrectStreak >= 10) {
        triggered = _tryUnlock('breaking_labels') ?? triggered;
      }

      if (_totalCorrect >= 5) {
        triggered = _tryUnlock('sharp_eye') ?? triggered;
      }

      lastAnswerWasIncorrect = false;
    } else {
      _totalWrong++;
      _currentCorrectStreak = 0;
      gameWrongCount++;
      gameAnswerHistory.add(false);

      if (_totalWrong >= 10) {
        triggered = _tryUnlock('walking_red_flag') ?? triggered;
      }

      lastAnswerWasIncorrect = true;
    }

    if (_encounteredSituationIds.length >= 50) {
      triggered = _tryUnlock('situation_collector') ?? triggered;
    }
    if (_correctlyAnsweredSituationIds.length >= 50) {
      triggered = _tryUnlock('situation_master') ?? triggered;
    }
    if (_correctlyAnsweredStereotypeIds.length >= 25) {
      triggered = _tryUnlock('stereotype_breaker') ?? triggered;
    }
    if (_correctlyAnsweredRespectfulIds.length >= 25) {
      triggered = _tryUnlock('respect_champion') ?? triggered;
    }
    if (_correctlyAnsweredSituationIds.length >= 50 &&
        _correctlyAnsweredStereotypeIds.length >= 25 &&
        _correctlyAnsweredRespectfulIds.length >= 25) {
      triggered = _tryUnlock('no_stereotype_master') ?? triggered;
    }
    if (_totalAnswered >= 10 && (_totalCorrect / _totalAnswered) >= 0.8) {
      triggered = _tryUnlock('consistent_thinker') ?? triggered;
    }

    cardStartTime = DateTime.now();
    _savePersistence();
    return triggered;
  }

  void incrementExplanationsRead() {
    _explanationsReadCount++;
    if (_explanationsReadCount >= 20) {
      _tryUnlock('knowledge_seeker');
    }
    _savePersistence();
  }

  AchievementDefinition? recordGameCompleted() {
    _gamesCompleted++;
    _lastGameFinishedTimestamp = DateTime.now().millisecondsSinceEpoch;

    AchievementDefinition? triggered;

    final totalGameAnswers = gameCorrectCount + gameWrongCount;
    final accuracy = totalGameAnswers > 0 ? gameCorrectCount / totalGameAnswers : 0.0;

    if (totalGameAnswers >= 10) {
      triggered = _tryUnlock('open_mind') ?? triggered;
    }
    if (totalGameAnswers > 0 && accuracy >= 0.8) {
      triggered = _tryUnlock('fair_judgment') ?? triggered;
    }
    if (totalGameAnswers > 0 && accuracy == 1.0) {
      triggered = _tryUnlock('no_assumptions') ?? triggered;
    }
    if (totalGameAnswers == 10 && gameWrongCount == 10) {
      triggered = _tryUnlock('professional_assumer') ?? triggered;
    }
    if (gameAnswerHistory.length == 10) {
      final first9Wrong = gameAnswerHistory.sublist(0, 9).every((a) => a == false);
      final lastCorrect = gameAnswerHistory.last == true;
      if (first9Wrong && lastCorrect) {
        triggered = _tryUnlock('plot_twist') ?? triggered;
      }
    }
    if (gameCorrectCount > 0 && gameWrongCount > 0) {
      triggered = _tryUnlock('mixed_thinker') ?? triggered;
    }
    if (totalGameAnswers == 10 && gameCorrectCount == 5) {
      triggered = _tryUnlock('close_call') ?? triggered;
    }
    if (gameAnswerHistory.length >= 5) {
      final h = gameAnswerHistory;
      bool isMixedPattern = true;
      for (int i = 0; i < h.length - 1; i++) {
        if (h[i] == h[i+1]) {
          isMixedPattern = false;
          break;
        }
      }
      if (isMixedPattern) {
        triggered = _tryUnlock('unpredictable') ?? triggered;
      }
    }
    if (accuracy < 0.5) {
      _hasDroppedBelow50 = true;
    }
    if (_hasDroppedBelow50 && accuracy >= 0.9) {
      _hasReached90AfterDrop = true;
      triggered = _tryUnlock('character_development') ?? triggered;
    }
    if (_gamesCompleted >= 20) {
      triggered = _tryUnlock('ultimate_thinker') ?? triggered;
    }

    _savePersistence();
    return triggered;
  }
}
