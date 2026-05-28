import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;

import 'package:permission_handler/permission_handler.dart';

import '../providers/settings_provider.dart';
import '../providers/timer_provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_scale.dart';
import '../widgets/control_bar.dart';
import '../widgets/countdown_display.dart';
import '../widgets/input_panel.dart';

// ---------------------------------------------------------------------------
// Home screen — dispatches to phone or tablet layout
// ---------------------------------------------------------------------------
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    // Listen for chime events to play audio
    ref.listenManual(chimeEventProvider, (_, next) {
      next.whenData((_) async {
        final customPath = ref.read(customChimeSoundPathProvider);
        if (customPath != null && File(customPath).existsSync()) {
          await _audioPlayer.play(DeviceFileSource(customPath));
        } else {
          await _audioPlayer.play(AssetSource('audio/chime.mp3'));
        }
      });
    });
  }

  Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        await Permission.notification.request();
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background rich space gradient glow
          const _BackgroundGlow(),

          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth >= 600;
                if (isTablet) {
                  return Center(
                    child: SizedBox(
                      width: 500,
                      child: LayoutBuilder(
                        builder: (context, tabletConstraints) {
                          final scaleX = (tabletConstraints.maxWidth / 375.0).clamp(0.85, 1.4);
                          final scaleY = (tabletConstraints.maxHeight / 812.0).clamp(0.85, 1.4);
                          final scaleFactor = ((scaleX + scaleY) / 2.0).clamp(0.85, 1.4);

                          return ResponsiveScale(
                            scaleX: scaleX,
                            scaleY: scaleY,
                            scaleFactor: scaleFactor,
                            child: _MobileLayout(constraints: tabletConstraints),
                          );
                        },
                      ),
                    ),
                  );
                } else {
                  final scaleX = (constraints.maxWidth / 375.0).clamp(0.85, 1.4);
                  final scaleY = (constraints.maxHeight / 812.0).clamp(0.85, 1.4);
                  final scaleFactor = ((scaleX + scaleY) / 2.0).clamp(0.85, 1.4);

                  return ResponsiveScale(
                    scaleX: scaleX,
                    scaleY: scaleY,
                    scaleFactor: scaleFactor,
                    child: _MobileLayout(constraints: constraints),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Background ambient glow effect — dynamic animated multi-color theme gradient
// ---------------------------------------------------------------------------
class _BackgroundGlow extends StatefulWidget {
  const _BackgroundGlow();

  @override
  State<_BackgroundGlow> createState() => _BackgroundGlowState();
}

class _BackgroundGlowState extends State<_BackgroundGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // smooth drifting cycle
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _AnimatedGradientPainter(_controller),
          );
        },
      ),
    );
  }
}

class _AnimatedGradientPainter extends CustomPainter {
  _AnimatedGradientPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;

    // Solid base dark blue-black background matching reference image
    final bgPaint = Paint()..color = const Color(0xFF030611);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final centerX = size.width * 0.5;
    final centerY = size.height * 0.55;

    // Main vibrant blue glowing core blob centered in the middle-bottom
    final mainGlowRadius = size.width * 0.95;
    final pulseRadius = mainGlowRadius * (1.0 + 0.06 * math.sin(t * 2 * math.pi));
    final blueCenter = Offset(
      centerX + size.width * 0.02 * math.sin(t * 2 * math.pi),
      centerY + size.height * 0.04 * math.cos(t * 2 * math.pi),
    );
    final bluePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0048FF).withValues(alpha: 0.85), // highly saturated royal blue
          const Color(0xFF003CFF).withValues(alpha: 0.4),
          const Color(0xFF001188).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: blueCenter, radius: pulseRadius));
    canvas.drawCircle(blueCenter, pulseRadius, bluePaint);

    // Dynamic secondary cyan-blue hot-spot to create a dazzling neon overlay
    final hotSpotRadius = size.width * 0.48;
    final hotSpotPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF3888FF).withValues(alpha: 0.75), // hot-spot core
          const Color(0xFF0044FF).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: blueCenter, radius: hotSpotRadius));
    canvas.drawCircle(blueCenter, hotSpotRadius, hotSpotPaint);

    // Shifting violet glow to add gorgeous color depth
    final violetCenter = Offset(
      centerX - size.width * 0.07 * math.cos((t + 0.45) * 2 * math.pi),
      centerY - size.height * 0.03 * math.sin((t + 0.45) * 2 * math.pi),
    );
    final violetRadius = size.width * 0.65;
    final violetPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF220E44).withValues(alpha: 0.6),
          const Color(0xFF220E44).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: violetCenter, radius: violetRadius));
    canvas.drawCircle(violetCenter, violetRadius, violetPaint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedGradientPainter oldDelegate) =>
      oldDelegate.animation.value != animation.value;
}

// ---------------------------------------------------------------------------
// Mobile layout (< 600dp) — responsive, vertical flex, non-scrollable
// ---------------------------------------------------------------------------
class _MobileLayout extends ConsumerWidget {
  const _MobileLayout({required this.constraints});
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(timerProvider.select((s) => s.status));
    final isIdle = status == ChimeStatus.idle;

    final scale = ResponsiveScale.of(context);
    // Dynamically size countdown arc to scale with screen height and scale factor
    final arcSize = (constraints.maxHeight * 0.32).clamp(180.0, 280.0 * scale.scaleFactor);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: scale.w(24),
        vertical: scale.h(12),
      ),
      child: Column(
        children: [
          SizedBox(height: scale.h(12)),

          // App header
          const _AppHeader(),

          const Spacer(flex: 2),

          // Transition between Setup Wheel Picker and Active Countdown Display
          Expanded(
            flex: 12,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
              child: isIdle
                  ? const InputPanel(key: ValueKey('setup_view'))
                  : Center(
                      key: const ValueKey('active_view'),
                      child: CountdownDisplay(arcSize: arcSize),
                    ),
            ),
          ),

          const Spacer(flex: 2),

          // Controls Bar (Starts/stops/pauses)
          const ControlBar(),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App header — logo + title
// ---------------------------------------------------------------------------
class _AppHeader extends ConsumerWidget {
  const _AppHeader();

  Future<void> _pickCustomSound(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final pickedFile = File(result.files.single.path!);
        final ext = pickedFile.path.split('.').last;
        final appDir = await getApplicationDocumentsDirectory();
        
        final savedFile = await pickedFile.copy(
          '${appDir.path}/custom_chime.$ext',
        );

        ref.read(customChimeSoundPathProvider.notifier).set(savedFile.path);

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceGlass,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.primary, width: 1),
            ),
            content: const Text(
              'Custom chime sound set successfully!',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          behavior: SnackBarBehavior.floating,
          content: Text('Failed to pick sound: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customSoundPath = ref.watch(customChimeSoundPathProvider);
    final scale = ResponsiveScale.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scale.w(4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: Colors.white.withValues(alpha: 0.8),
              size: scale.sp(22),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.presetBg,
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    'Menu feature coming soon!',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              );
            },
          ),
          Text(
            'TICKR',
            style: TextStyle(
              color: Colors.white,
              fontSize: scale.sp(16),
              letterSpacing: scale.w(8.0),
              fontWeight: FontWeight.w300,
            ),
          ),
          Tooltip(
            message: customSoundPath != null 
                ? 'Sound: Custom (Long press to reset)' 
                : 'Tap to set custom chime sound',
            child: GestureDetector(
              onLongPress: () {
                if (customSoundPath != null) {
                  ref.read(customChimeSoundPathProvider.notifier).clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.presetBg,
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'Chime sound reset to default.',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  );
                }
              },
              child: IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: customSoundPath != null
                      ? AppColors.accent
                      : Colors.white.withValues(alpha: 0.8),
                  size: scale.sp(22),
                ),
                onPressed: () => _pickCustomSound(context, ref),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
