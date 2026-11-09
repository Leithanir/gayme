import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'app_settings.dart';
import 'game/game_session.dart';

const List<Shadow> comicShadows = [
  Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
  Shadow(color: Colors.black, offset: Offset(-2, -2), blurRadius: 0),
  Shadow(color: Colors.black, offset: Offset(2, -2), blurRadius: 0),
  Shadow(color: Colors.black, offset: Offset(-2, 2), blurRadius: 0),
];

/// End-of-round summary with a review of the cards that were missed.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.session});

  final GameSession session;

  static const Color neonPink = Color(0xFFFF00E6);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonBlue = Color(0xFF00E5FF);
  static const Color neonPurple = Color(0xFFC45CFF);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late final VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset(
      'assets/videos/GamePlay.mp4',
    );
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _videoController.initialize();
      await _videoController.setLooping(true);
      await _videoController.play();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('GamePlay.mp4 failed to load in ResultsScreen: $e');
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final isFilipino = settings.isFilipino;
    final missed = widget.session.missed;
    final accuracy = widget.session.accuracy;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildVideoBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    isFilipino ? 'RESULTA' : 'RESULTS',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ResultsScreen.neonPurple,
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
                          color: ResultsScreen.neonPink,
                          onTap: () => Navigator.pop(context, false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          label: isFilipino ? 'MAGLARO MULI' : 'PLAY AGAIN',
                          color: ResultsScreen.neonGreen,
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

  Widget _buildVideoBackground() {
    if (!_videoController.value.isInitialized) {
      return const SizedBox.expand(child: ColoredBox(color: Color(0xFF080817)));
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _videoController.value.size.width,
        height: _videoController.value.size.height,
        child: VideoPlayer(_videoController),
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

    return CustomPaint(
      foregroundPainter: _ThickComicBorderPainter(
        color: ResultsScreen.neonPurple,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF3A0B4F).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  '${widget.session.correctCount} / ${widget.session.total}',
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
                    color: ResultsScreen.neonGreen,
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
          ),
        ),
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
            color: ResultsScreen.neonGreen,
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

    return CustomPaint(
      foregroundPainter: _ThickComicBorderPainter(
        color: ResultsScreen.neonPink,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3A0B4F).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feedback.card.textFor(languageCode),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                    shadows: comicShadows,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThickComicBorderPainter extends CustomPainter {
  final Color color;

  _ThickComicBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final borderRect = rect.deflate(2);
    final rrect = RRect.fromRectAndRadius(
      borderRect,
      const Radius.circular(20),
    );

    final blackOutline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = Colors.black;

    canvas.drawRRect(rrect, blackOutline);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = color;

    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ThickComicBorderPainter oldDelegate) {
    return oldDelegate.color != color;
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
