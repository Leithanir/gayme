import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'app_settings.dart';
import 'game_screen.dart';
import 'achievement_screen.dart';
import 'achievement_system.dart';

const List<Shadow> comicShadows = [
  Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
  Shadow(color: Colors.black, offset: Offset(-2, -2), blurRadius: 0),
  Shadow(color: Colors.black, offset: Offset(2, -2), blurRadius: 0),
  Shadow(color: Colors.black, offset: Offset(-2, 2), blurRadius: 0),
];

void main() {
  runApp(const StereotypicalApp());
}

const List<Color> rainbowColors = [
  Color(0xFFFF00E6),
  Color(0xFFFFF500),
  Color(0xFF39FF14),
  Color(0xFF00F5FF),
  Color(0xFF9D00FF),
  Color(0xFFFF00E6),
];

class StereotypicalApp extends StatefulWidget {
  const StereotypicalApp({super.key});

  @override
  State<StereotypicalApp> createState() => _StereotypicalAppState();
}

class _StereotypicalAppState extends State<StereotypicalApp> {
  final AppSettings _settings = AppSettings();

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      settings: _settings,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Stereotypical',
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          fontFamily: 'Arial',
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white, shadows: comicShadows),
            bodyMedium: TextStyle(color: Colors.white, shadows: comicShadows),
            bodySmall: TextStyle(color: Colors.white, shadows: comicShadows),
            titleLarge: TextStyle(color: Colors.white, shadows: comicShadows),
            titleMedium: TextStyle(color: Colors.white, shadows: comicShadows),
            titleSmall: TextStyle(color: Colors.white, shadows: comicShadows),
            labelLarge: TextStyle(color: Colors.white, shadows: comicShadows),
            labelMedium: TextStyle(color: Colors.white, shadows: comicShadows),
            labelSmall: TextStyle(color: Colors.white, shadows: comicShadows),
            headlineLarge: TextStyle(color: Colors.white, shadows: comicShadows),
            headlineMedium: TextStyle(color: Colors.white, shadows: comicShadows),
            headlineSmall: TextStyle(color: Colors.white, shadows: comicShadows),
          ),
        ),
        home: const VideoSplashScreen(),
      ),
    );
  }
}

// ============================================================
// VIDEO SPLASH SCREEN
// ============================================================

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late VideoPlayerController _videoController;

  bool _finished = false;

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.asset(
      'assets/videos/Intro.mp4',
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _videoController.initialize();

      await _videoController.setLooping(false);

      await _videoController.play();

      _videoController.addListener(_videoListener);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Intro.mp4 failed to load: $e');

      _goToMainMenu();
    }
  }

  void _videoListener() {
    if (!_videoController.value.isInitialized) {
      return;
    }

    final position = _videoController.value.position;
    final duration = _videoController.value.duration;

    if (duration > Duration.zero &&
        position >= duration &&
        !_finished) {
      _finished = true;
      _goToMainMenu();
    }
  }

  void _goToMainMenu() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MainMenu(),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _goToMainMenu,
        child: SizedBox.expand(
          child: _videoController.value.isInitialized
              ? FittedBox(
                  // INTRO STAYS CONTAIN
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

// ============================================================
// MAIN MENU
// ============================================================

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rainbowController;

  late final VideoPlayerController _menuVideoController;

  late AppSettings _settings;

  bool get isFilipino => _settings.isFilipino;

  @override
  void initState() {
    super.initState();

    _rainbowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _menuVideoController = VideoPlayerController.asset(
      'assets/videos/MainMenu.mp4',
    );

    _initializeMenuVideo();
  }

  Future<void> _initializeMenuVideo() async {
    try {
      await _menuVideoController.initialize();

      await _menuVideoController.setLooping(true);

      await _menuVideoController.play();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('MainMenu.mp4 failed to load: $e');
    }
  }

  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _settings = SettingsScope.of(context);

    final animation = ModalRoute.of(context)?.animation;
    if (_routeAnimation != animation) {
      _routeAnimation?.removeStatusListener(_animationStatusListener);
      _routeAnimation = animation;
      _routeAnimation?.addStatusListener(_animationStatusListener);
    }

    if (ModalRoute.of(context)?.isCurrent == true && _menuVideoController.value.isInitialized) {
      _menuVideoController.play();
      _menuVideoController.setLooping(true);
    }
  }

  void _animationStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (ModalRoute.of(context)?.isCurrent == true) {
        if (_menuVideoController.value.isInitialized) {
          _menuVideoController.play();
          _menuVideoController.setLooping(true);
        }
      }
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_animationStatusListener);
    _rainbowController.dispose();
    _menuVideoController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ==================================================
          // MAIN MENU VIDEO
          // NO FALLBACK
          // NO GRADIENT
          // NO BLACK OVERLAY
          // ==================================================

          if (_menuVideoController.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _menuVideoController.value.size.width,
                height: _menuVideoController.value.size.height,
                child: VideoPlayer(_menuVideoController),
              ),
            ),

          // ==================================================
          // MENU CONTENT
          // ==================================================

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                final logoSize =
                (width * 0.70).clamp(210.0, 320.0);

                final iconSize =
                width < 380 ? 58.0 : 66.0;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // ==================================================
                    // TOP-LEFT ACHIEVEMENT PROGRESS BADGE
                    // ==================================================
                    Positioned(
                      top: 10,
                      left: 12,
                      child: GestureDetector(
                        onTap: showAchievements,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111126)
                                .withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFFFF500),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(3, 4),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.emoji_events_rounded,
                                color: Color(0xFFFFF500),
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${AchievementManager.allAchievements.where((a) => _settings.achievements.isUnlocked(a.id)).length} / ${AchievementManager.allAchievements.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 60,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: AchievementManager.allAchievements
                                            .where((a) => _settings.achievements.isUnlocked(a.id))
                                            .length /
                                            AchievementManager.allAchievements.length,
                                        minHeight: 5,
                                        backgroundColor:
                                        Colors.white.withValues(alpha: 0.15),
                                        valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF39FF14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ==================================================
                    // LOGO
                    // ==================================================

                    Positioned(
                      top: height * 0.07,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: StereotypicalLogo(
                          size: logoSize,
                          rotation:
                          _rainbowController.value * 6.28318,
                          animation: _rainbowController,
                        ),
                      ),
                    ),

                    // ==================================================
                    // SETTINGS
                    // ==================================================

                    Positioned(
                      top: height * 0.43,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: NeonIcon(
                          icon: Icons.settings_rounded,
                          color: const Color(0xFFB76BFF),
                          onTap: showSettings,
                          size: iconSize,
                        ),
                      ),
                    ),

                    // ==================================================
                    // HOW TO PLAY
                    // ==================================================

                    Positioned(
                      top: height * 0.51,
                      left: width * 0.20,
                      child: NeonIcon(
                        icon: Icons.help_outline_rounded,
                        color: const Color(0xFF00B8D4),
                        onTap: showHowToPlay,
                        size: iconSize,
                      ),
                    ),

                    // ==================================================
                    // ACHIEVEMENTS
                    // ==================================================

                    Positioned(
                      top: height * 0.51,
                      right: width * 0.20,
                      child: NeonIcon(
                        icon: Icons.emoji_events_rounded,
                        color: const Color(0xFFFFB300),
                        onTap: showAchievements,
                        size: iconSize,
                      ),
                    ),

                    // ==================================================
                    // CREDITS
                    // ==================================================

                    Positioned(
                      top: height * 0.60,
                      left: width * 0.08,
                      child: NeonIcon(
                        icon: Icons.people_alt_rounded,
                        color: const Color(0xFFE83E8C),
                        onTap: showCredits,
                        size: iconSize,
                      ),
                    ),

                    // ==================================================
                    // EXIT
                    // ==================================================

                    Positioned(
                      top: height * 0.60,
                      right: width * 0.08,
                      child: NeonIcon(
                        icon: Icons.exit_to_app_rounded,
                        color: const Color(0xFFE53935),
                        onTap: confirmExit,
                        size: iconSize,
                      ),
                    ),

                    // ==================================================
                    // PLAY BUTTON
                    // ==================================================

                    Positioned(
                      top: height * 0.56,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _rainbowController,
                          builder: (context, child) {
                            return ComicPlayButton(
                              size: iconSize * 1.35,
                              rotation:
                              _rainbowController.value * 6.28318,
                              onTap: startGame,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // START GAME
  // ============================================================

  void startGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GameScreen(),
      ),
    );
  }

  // ============================================================
  // ACHIEVEMENTS
  // ============================================================

  void showAchievements() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AchievementScreen(),
      ),
    );
  }

  // ============================================================
  // EXIT
  // ============================================================

  void confirmExit() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Exit',
      barrierColor: Colors.black.withValues(alpha: 0.25),
      pageBuilder: (
          dialogContext,
          animation,
          secondaryAnimation,
          ) {
        return _GlassDialog(
          title: isFilipino
              ? 'LUMABAS SA LARO?'
              : 'EXIT GAME?',
          children: [
            Text(
              isFilipino
                  ? 'Sigurado ka bang gusto mong lumabas?'
                  : 'Are you sure you want to exit?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                height: 1.5,
                shadows: comicShadows,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label:
                    isFilipino ? 'KANSELAHIN' : 'CANCEL',
                    color: const Color(0xFF00A6C7),
                    onTap: () =>
                        Navigator.pop(dialogContext),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    label:
                    isFilipino ? 'LUMABAS' : 'EXIT',
                    color: const Color(0xFFE53935),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      SystemNavigator.pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
      transitionBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
          ) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.92,
              end: 1,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  // ============================================================
  // SETTINGS
  // ============================================================

  void showSettings() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Settings',
      barrierColor: Colors.black.withValues(alpha: 0.25),
      transitionDuration:
      const Duration(milliseconds: 250),
      pageBuilder: (
          dialogContext,
          animation,
          secondaryAnimation,
          ) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ListenableBuilder(
              listenable: _settings,
              builder: (context, _) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius:
                    BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 20,
                        sigmaY: 20,
                      ),
                      child: Container(
                        width: 420,
                        constraints: BoxConstraints(
                          maxHeight:
                          MediaQuery.of(context)
                              .size
                              .height *
                              0.85,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111126)
                              .withValues(alpha: 0.20),
                          borderRadius:
                          BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.black,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC45CFF)
                                  .withValues(alpha: 0.12),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding:
                          const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize:
                            MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.settings,
                                    color:
                                    Color(0xFFC45CFF),
                                    size: 26,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isFilipino
                                          ? 'MGA SETTING'
                                          : 'SETTINGS',
                                      style:
                                      const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight:
                                        FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.pop(
                                            dialogContext),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              _settingsSection('AUDIO'),

                              const SizedBox(height: 16),

                              _SettingsVolumeControl(
                                icon:
                                _settings.musicVolume ==
                                    0
                                    ? Icons.music_off
                                    : Icons.music_note,
                                title: isFilipino
                                    ? 'Musika'
                                    : 'Music',
                                value:
                                _settings.musicVolume,
                                onChanged: (value) {
                                  _settings.musicVolume =
                                      value;
                                },
                                onIconTap:
                                _settings.toggleMusic,
                              ),

                              const SizedBox(height: 12),

                              _SettingsVolumeControl(
                                icon:
                                _settings.sfxVolume == 0
                                    ? Icons.volume_off
                                    : Icons.volume_up,
                                title: isFilipino
                                    ? 'Epekto ng Tunog'
                                    : 'Sound Effects',
                                value:
                                _settings.sfxVolume,
                                onChanged: (value) {
                                  _settings.sfxVolume =
                                      value;
                                },
                                onIconTap:
                                _settings.toggleSfx,
                              ),

                              const SizedBox(height: 24),

                              _settingsSection(
                                isFilipino
                                    ? 'WIKA'
                                    : 'LANGUAGE',
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child:
                                    _SettingsLanguageButton(
                                      label: 'English',
                                      selected:
                                      _settings
                                          .language ==
                                          AppSettings
                                              .english,
                                      onTap: () {
                                        _settings
                                            .language =
                                            AppSettings
                                                .english;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child:
                                    _SettingsLanguageButton(
                                      label: 'Filipino',
                                      selected:
                                      _settings
                                          .language ==
                                          AppSettings
                                              .filipino,
                                      onTap: () {
                                        _settings
                                            .language =
                                            AppSettings
                                                .filipino;
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              Divider(
                                color: Colors.white
                                    .withValues(alpha: 0.2),
                              ),

                              const SizedBox(height: 8),

                              _DialogButton(
                                label: isFilipino
                                    ? 'TAPOS NA'
                                    : 'DONE',
                                color:
                                const Color(0xFF00A6C7),
                                onTap: () =>
                                    Navigator.pop(
                                        dialogContext),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      transitionBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
          ) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.92,
              end: 1,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget _settingsSection(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFC45CFF),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  // ============================================================
  // HOW TO PLAY
  // ============================================================

  void showHowToPlay() {
    showInfoDialog(
      isFilipino
          ? 'PAANO MAGLARO'
          : 'HOW TO PLAY',
      isFilipino
          ? 'Basahing mabuti ang bawat sitwasyon.\n\n'
          'Mag-swipe pakaliwa o pakanan upang pumili ng sagot.\n\n'
          'Matutong umunawa at gumalang sa iba’t ibang pagkakakilanlan ng kasarian.'
          : 'Read each situation carefully.\n\n'
          'Swipe left or right to choose your answer.\n\n'
          'Learn how your choices can help promote understanding and respect for different gender identities.',
    );
  }

  // ============================================================
  // CREDITS
  // ============================================================

  void showCredits() {
    showInfoDialog(
      isFilipino
          ? 'MGA KREDITO'
          : 'CREDITS',
      isFilipino
          ? 'STEREOTYPICAL\n\n'
          'Ginawa ng TEAM MAKKI.\n\n'
          'Dorencio, Willmoore B.\n'
          'Francis, Jade Rhyss D.\n'
          'Quintero, Genesis Joed T\n.'
          'Tundagui, Patrick jr .\n'


          : 'STEREOTYPICAL\n\n'
          'Developed by TEAM MAKKI.\n\n'
          'Dorencio, Willmoore B.\n'
          'Francis, Jade Rhyss D.\n'
          'Quintero, Genesis Joed T.\n'
          'Tundagui, Patrick jr .\n'
    );
  }

  // ============================================================
  // INFO DIALOG
  // ============================================================

  void showInfoDialog(
      String title,
      String message,
      ) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor:
      Colors.black.withValues(alpha: 0.25),
      pageBuilder: (
          dialogContext,
          animation,
          secondaryAnimation,
          ) {
        return _GlassDialog(
          title: title,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                height: 1.5,
                shadows: comicShadows,
              ),
            ),
            const SizedBox(height: 20),
            _DialogButton(
              label:
              isFilipino ? 'ISARA' : 'CLOSE',
              color: const Color(0xFF00A6C7),
              onTap: () =>
                  Navigator.pop(dialogContext),
            ),
          ],
        );
      },
      transitionBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
          ) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.92,
              end: 1,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

// ============================================================
// COMIC PLAY BUTTON
// ============================================================

class ComicPlayButton extends StatelessWidget {
  final double size;
  final double rotation;
  final VoidCallback onTap;

  const ComicPlayButton({
    super.key,
    required this.size,
    required this.rotation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          transform: GradientRotation(rotation),
          colors: rainbowColors,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 0,
            spreadRadius: 0,
            offset: Offset(6, 7),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF3D2378),
          border: Border.all(
            color: Colors.black,
            width: 4,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Center(
              child: Container(
                width: size * 0.58,
                height: size * 0.58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                  Colors.white.withValues(alpha: 0.12),
                  border: Border.all(
                    color:
                    Colors.white.withValues(alpha: 0.75),
                    width: 3,
                  ),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: size * 0.43,
                  shadows: const [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SETTINGS VOLUME CONTROL
// ============================================================

class _SettingsVolumeControl
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback onIconTap;

  const _SettingsVolumeControl({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.onIconTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color:
        Colors.white.withValues(alpha: 0.06),
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onIconTap,
                child: Icon(
                  icon,
                  color: value == 0
                      ? Colors.white54
                      : const Color(0xFF00A6C7),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: comicShadows,
                  ),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  color: Color(0xFF00A6C7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data:
            SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor:
              const Color(0xFFC45CFF),
              inactiveTrackColor:
              Colors.white24,
              thumbColor:
              const Color(0xFF39FF14),
              overlayColor:
              Colors.transparent,
              thumbShape:
              const RoundSliderThumbShape(
                enabledThumbRadius: 9,
              ),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 1,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LANGUAGE BUTTON
// ============================================================

class _SettingsLanguageButton
    extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SettingsLanguageButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(14),
      child: Container(
        padding:
        const EdgeInsets.symmetric(
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFC45CFF)
              .withValues(alpha: 0.2)
              : Colors.white
              .withValues(alpha: 0.04),
          borderRadius:
          BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFFC45CFF)
                : Colors.white
                .withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            if (selected) ...[
              const Icon(
                Icons.check_circle,
                color: Color(0xFFC45CFF),
                size: 16,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.normal,
                shadows: comicShadows,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DIALOG BUTTON
// ============================================================

class _DialogButton
    extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style:
        OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(
            color:
            color.withValues(alpha: 0.8),
          ),
          padding:
          const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 13,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight:
            FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// GLASS DIALOG
// ============================================================

class _GlassDialog
    extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _GlassDialog({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding:
          const EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius:
            BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 20,
                sigmaY: 20,
              ),
              child: Container(
                width: 420,
                constraints:
                BoxConstraints(
                  maxHeight:
                  MediaQuery.of(context)
                      .size
                      .height *
                      0.85,
                ),
                padding:
                const EdgeInsets.all(24),
                decoration:
                BoxDecoration(
                  color: const Color(
                    0xFF111126,
                  ).withValues(
                    alpha: 0.20,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    28,
                  ),
                  border: Border.all(
                    color: Colors.black,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                      const Color(
                        0xFFC45CFF,
                      ).withValues(
                        alpha: 0.12,
                      ),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child:
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign:
                        TextAlign.center,
                        style:
                        const TextStyle(
                          color:
                          Colors.white,
                          fontSize: 20,
                          fontWeight:
                          FontWeight.w900,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color:
                              Colors.black,
                              offset:
                              Offset(
                                2,
                                2,
                              ),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEREOTYPICAL LOGO
// ============================================================

class StereotypicalLogo
    extends StatelessWidget {
  final double size;
  final double rotation;
  final Animation<double> animation;

  const StereotypicalLogo({
    super.key,
    required this.size,
    required this.rotation,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final currentRotation =
            animation.value * 6.28318;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ==================================================
              // BACKGROUND SYMBOL
              // ==================================================

              Opacity(
                opacity: 0.25,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    size * 0.08,
                  ),
                  child: Text(
                    '⚧',
                    style: TextStyle(
                      fontSize:
                      size * 0.65,
                      fontWeight:
                      FontWeight.bold,
                      color:
                      Colors.white,
                      shadows: const [
                        Shadow(
                          color:
                          Colors.black,
                          offset:
                          Offset(4, 5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ==================================================
              // LOGO TEXT
              // ==================================================

              Padding(
                padding:
                EdgeInsets.symmetric(
                  horizontal:
                  size * 0.07,
                ),
                child: FittedBox(
                  fit:
                  BoxFit.scaleDown,
                  child: Stack(
                    alignment:
                    Alignment.center,
                    children: [
                      // Thick black comic outline
                      Text(
                        'STEREOTYPICAL',
                        textAlign:
                        TextAlign.center,
                        style:
                        TextStyle(
                          fontSize:
                          size * 0.12,
                          fontWeight:
                          FontWeight.w900,
                          letterSpacing: 1,
                          foreground:
                          Paint()
                            ..style =
                                PaintingStyle
                                    .stroke
                            ..strokeWidth =
                            11
                            ..strokeJoin =
                                StrokeJoin
                                    .round
                            ..color =
                                Colors.black,
                        ),
                      ),

                      // Secondary purple outline
                      Text(
                        'STEREOTYPICAL',
                        textAlign:
                        TextAlign.center,
                        style:
                        TextStyle(
                          fontSize:
                          size * 0.12,
                          fontWeight:
                          FontWeight.w900,
                          letterSpacing: 1,
                          foreground:
                          Paint()
                            ..style =
                                PaintingStyle
                                    .stroke
                            ..strokeWidth =
                            5
                            ..strokeJoin =
                                StrokeJoin
                                    .round
                            ..color =
                            const Color(
                              0xFF5B248F,
                            ),
                        ),
                      ),

                      // Main comic text
                      ShaderMask(
                        blendMode:
                        BlendMode.srcIn,
                        shaderCallback:
                            (bounds) {
                          return const LinearGradient(
                            begin:
                            Alignment.topLeft,
                            end:
                            Alignment.bottomRight,
                            colors: [
                              Color(
                                0xFFFF4FCB,
                              ),
                              Color(
                                0xFFFFE94A,
                              ),
                              Color(
                                0xFF62F04A,
                              ),
                              Color(
                                0xFF39DFFF,
                              ),
                              Color(
                                0xFFA45BFF,
                              ),
                            ],
                          ).createShader(
                            bounds,
                          );
                        },
                        child: Text(
                          'STEREOTYPICAL',
                          textAlign:
                          TextAlign.center,
                          style:
                          TextStyle(
                            fontSize:
                            size * 0.12,
                            fontWeight:
                            FontWeight.w900,
                            letterSpacing: 1,
                            color:
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==================================================
              // COMIC RAINBOW SLASH
              // ==================================================

              Transform.rotate(
                angle: -0.72,
                child: Stack(
                  alignment:
                  Alignment.center,
                  children: [
                    // Black outline
                    Container(
                      width:
                      size * 1.10,
                      height: 11,
                      decoration:
                      BoxDecoration(
                        color:
                        Colors.black,
                        borderRadius:
                        BorderRadius
                            .circular(
                          20,
                        ),
                      ),
                    ),

                    // Animated rainbow strip
                    Container(
                      width:
                      size * 1.04,
                      height: 6,
                      decoration:
                      BoxDecoration(
                        gradient:
                        SweepGradient(
                          transform:
                          GradientRotation(
                            currentRotation,
                          ),
                          colors:
                          rainbowColors,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // ANIMATED COMIC CIRCLE
              // ==================================================

              CustomPaint(
                size:
                Size(size, size),
                painter:
                RainbowCirclePainter(
                  rotation:
                  currentRotation,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// RAINBOW CIRCLE PAINTER
// ============================================================

class RainbowCirclePainter
    extends CustomPainter {
  final double rotation;

  RainbowCirclePainter({
    required this.rotation,
  });

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final rect =
    Offset.zero & size;

    final center =
        rect.center;

    final radius =
        size.width / 2 - 8;

    // ==========================================================
    // HARD BLACK COMIC SHADOW
    // ==========================================================

    final shadowPaint = Paint()
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 12
      ..color =
          Colors.black;

    canvas.drawCircle(
      center.translate(5, 6),
      radius,
      shadowPaint,
    );

    // ==========================================================
    // BLACK OUTER OUTLINE
    // ==========================================================

    final outlinePaint = Paint()
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 12
      ..color =
          Colors.black;

    canvas.drawCircle(
      center,
      radius,
      outlinePaint,
    );

    // ==========================================================
    // ANIMATED RAINBOW
    // ==========================================================

    final shader =
    SweepGradient(
      transform:
      GradientRotation(
        rotation,
      ),
      colors:
      rainbowColors,
    ).createShader(rect);

    final rainbowPaint = Paint()
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 7
      ..shader = shader;

    canvas.drawCircle(
      center,
      radius,
      rainbowPaint,
    );

    // ==========================================================
    // WHITE COMIC HIGHLIGHT
    // ==========================================================

    final highlightPaint = Paint()
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white
          .withValues(alpha: 0.75);

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius - 3,
      ),
      -2.7,
      1.35,
      false,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(
      covariant RainbowCirclePainter
      oldDelegate,
      ) {
    return oldDelegate.rotation !=
        rotation;
  }
}

// ============================================================
// COMIC ICON
// ============================================================

class NeonIcon
    extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;

  const NeonIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 54,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(40),
        child: Container(
          width: size,
          height: size,
          decoration:
          BoxDecoration(
            shape:
            BoxShape.circle,

            // Main comic color
            color: color,

            // Thick black comic outline
            border: Border.all(
              color:
              Colors.black,
              width: 4,
            ),

            // Hard offset shadow
            boxShadow: const [
              BoxShadow(
                color:
                Colors.black,
                blurRadius: 0,
                spreadRadius: 0,
                offset:
                Offset(5, 6),
              ),
            ],
          ),
          child: Container(
            margin:
            const EdgeInsets.all(4),
            decoration:
            BoxDecoration(
              shape:
              BoxShape.circle,
              color: Colors.white
                  .withValues(
                alpha: 0.16,
              ),
              border:
              Border.all(
                color: Colors.white
                    .withValues(
                  alpha: 0.90,
                ),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color:
              Colors.white,
              size:
              size * 0.54,
              shadows: const [
                Shadow(
                  color:
                  Colors.black,
                  offset:
                  Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

