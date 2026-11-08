import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'game/game_session.dart';

const List<Shadow> comicShadows = [
  Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
  Shadow(color: Colors.black, offset: Offset(-2, -2), blurRadius: 0),
  Shadow(color: Colors.black, offset: Offset(2, -2), blurRadius: 0),
  Shadow(color: Colors.black, offset: Offset(-2, 2), blurRadius: 0),
];

/// End-of-round summary with a review of the cards that were missed.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.session});

  final GameSession session;

  static const Color neonPink = Color(0xFFFF00E6);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonBlue = Color(0xFF00E5FF);
  static const Color neonPurple = Color(0xFFC45CFF);

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final isFilipino = settings.isFilipino;
    final missed = session.missed;
    final accuracy = session.accuracy;

    return Scaffold(
      backgroundColor: const Color(0xFF080817),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF170C63),
                  Color(0xFF080817),
                  Color(0xFF3A0B4F),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    isFilipino ? 'RESULTA' : 'RESULTS',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: neonPurple,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      shadows: comicShadows,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _scoreCard(isFilipino, accuracy),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      missed.isEmpty
                          ? (isFilipino
                              ? 'WALANG MALI'
                              : 'NO MISTAKES')
                          : (isFilipino
                              ? 'MGA CARD NA BALIKAN'
                              : 'CARDS TO REVIEW'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        shadows: comicShadows,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: missed.isEmpty
                        ? _perfectRound(isFilipino)
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 8),
                            itemCount: missed.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return _MissedCard(
                                feedback: missed[index],
                                languageCode: settings.languageCode,
                                isFilipino: isFilipino,
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'MENU',
                          color: neonPink,
                          onTap: () => Navigator.pop(context, false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          label: isFilipino ? 'MAGLARO MULI' : 'PLAY AGAIN',
                          color: neonGreen,
                          onTap: () => Navigator.pop(context, true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreCard(bool isFilipino, double accuracy) {
    final message = accuracy >= 0.8
        ? (isFilipino ? 'Magaling!' : 'Great job!')
        : accuracy >= 0.5
            ? (isFilipino
                ? 'Magandang pagsisikap!'
                : 'Good effort!')
            : (isFilipino
                ? 'Magpatuloy sa pag-aaral!'
                : 'Keep practicing!');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: neonPurple.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: neonPurple.withValues(alpha: 0.2),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${session.correctCount} / ${session.total}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w900,
              height: 1,
              shadows: comicShadows,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(accuracy * 100).round()}% ${isFilipino ? 'TAMA' : 'CORRECT'}',
            style: const TextStyle(
              color: neonGreen,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              shadows: comicShadows,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE6B4FF),
              fontSize: 15,
              shadows: comicShadows,
            ),
          ),
        ],
      ),
    );
  }

  Widget _perfectRound(bool isFilipino) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: neonGreen,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            isFilipino ? 'Perpektong round!' : 'Perfect round!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: comicShadows,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissedCard extends StatelessWidget {
  const _MissedCard({
    required this.feedback,
    required this.languageCode,
    required this.isFilipino,
  });

  final GameFeedback feedback;
  final String languageCode;
  final bool isFilipino;

  String _sideLabel(SwipeSide side) {
    if (side == SwipeSide.left) {
      return isFilipino ? 'ISTERYOTIPO' : 'STEREOTYPE';
    }
    return isFilipino ? 'MAGALANG' : 'RESPECTFUL';
  }

  @override
  Widget build(BuildContext context) {
    final correctSide = GameSession.expectedSide(feedback.card);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ResultsScreen.neonPink.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            feedback.card.textFor(languageCode),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.35,
              shadows: comicShadows,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFilipino
                ? 'Pinili mo: ${_sideLabel(feedback.chosen)}  •  Tama: ${_sideLabel(correctSide)}'
                : 'You chose: ${_sideLabel(feedback.chosen)}  •  Correct: ${_sideLabel(correctSide)}',
            style: const TextStyle(
              color: ResultsScreen.neonPink,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              shadows: comicShadows,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            feedback.card.explanationFor(languageCode),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.35,
              shadows: comicShadows,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.8)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          shadows: comicShadows,
        ),
      ),
    );
  }
}
