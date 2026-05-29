import 'dart:io';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import 'package:permission_handler/permission_handler.dart';

import '../providers/settings_provider.dart';
import '../providers/timer_provider.dart';
import '../services/vibration_service.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_scale.dart';
import '../widgets/control_bar.dart';
import '../widgets/countdown_display.dart';
import '../widgets/input_panel.dart';
import 'presets_screen.dart';
import 'chimes_screen.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    // Listen for chime events to play audio reactively
    ref.listenManual(chimeEventProvider, (_, next) {
      next.whenData((_) async {
        final selectedType = ref.read(selectedChimeTypeProvider) ?? 'dragon_studio_alert';
        final customPath = ref.read(customChimeSoundPathProvider);
        
        // Trigger vibration in the rhythm of the chime
        VibrationService.vibrateForChime(selectedType);

        if (selectedType == 'custom' && customPath != null && File(customPath).existsSync()) {
          await _audioPlayer.play(DeviceFileSource(customPath));
        } else {
          final Map<String, String> builtInChimes = {
            'dragon_studio_alert': 'audio/dragon_studio_alert.mp3',
            'notification_message_alert': 'audio/notification_message_alert.mp3',
            'clear_mobile_notification': 'audio/clear_mobile_notification.mp3',
            'mysterious_ringtone': 'audio/mysterious_ringtone.mp3',
            'new_notification_030': 'audio/new_notification_030.mp3',
            'new_notification_050': 'audio/new_notification_050.mp3',
            'new_notification_060': 'audio/new_notification_060.mp3',
            'new_notification_061': 'audio/new_notification_061.mp3',
          };
          final assetPath = builtInChimes[selectedType] ?? 'audio/dragon_studio_alert.mp3';
          await _audioPlayer.play(AssetSource(assetPath));
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
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const _TickrDrawer(),
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background rich space gradient glow
          BackgroundGlow(isDark: isDark),

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
                            child: _MobileLayout(
                              constraints: tabletConstraints,
                              onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                            ),
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
                    child: _MobileLayout(
                      constraints: constraints,
                      onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
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
class BackgroundGlow extends StatefulWidget {
  const BackgroundGlow({required this.isDark, super.key});
  final bool isDark;

  @override
  State<BackgroundGlow> createState() => _BackgroundGlowState();
}

class _BackgroundGlowState extends State<BackgroundGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // smooth drifting cycle - sped up by 200% (3x faster)
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
      child: Stack(
        children: [
          // Base custom painted dynamic morphing liquid blobs
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: AnimatedGradientPainter(_controller, widget.isDark),
                );
              },
            ),
          ),
          // Glassmorphic backdrop blur overlay to blend the blobs into soft dynamic fogs
          Positioned.fill(
            child: IgnorePointer(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 95, sigmaY: 95),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedGradientPainter extends CustomPainter {
  AnimatedGradientPainter(this.animation, this.isDark) : super(repaint: animation);

  final Animation<double> animation;
  final bool isDark;

  // Render organic morphing liquid blob instead of simple circles
  void _drawBlob(
    Canvas canvas,
    Offset center,
    double baseRadius,
    Paint paint,
    double t,
    double seed,
  ) {
    final path = Path();
    const int pointsCount = 8;
    final double angleStep = (2 * math.pi) / pointsCount;
    final List<Offset> points = [];

    // Calculate morphing wave distortion at 8 radial control points
    for (int i = 0; i < pointsCount; i++) {
      final double angle = i * angleStep;
      
      // Dynamic noise waves with multiple frequencies and seed values to randomize shapes
      final double radiusNoise = 0.16 * math.sin(angle * 3 + t * 2 * math.pi + seed) +
                                0.08 * math.cos(angle * 5 - t * 4 * math.pi + seed * 1.7) +
                                0.04 * math.sin(angle * 2 + t * 6 * math.pi + seed * 3.1);
      final double currentRadius = baseRadius * (1.0 + radiusNoise);
      final double x = center.dx + currentRadius * math.cos(angle);
      final double y = center.dy + currentRadius * math.sin(angle);
      points.add(Offset(x, y));
    }

    // Connect control points using smooth quadratic bezier curves
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < pointsCount; i++) {
      final p1 = points[(i + 1) % pointsCount];
      final controlAngle = i * angleStep + (angleStep / 2);
      
      // Smooth control point distance using the same noise wave formula
      final double controlRadiusNoise = 0.16 * math.sin(controlAngle * 3 + t * 2 * math.pi + seed) +
                                       0.08 * math.cos(controlAngle * 5 - t * 4 * math.pi + seed * 1.7) +
                                       0.04 * math.sin(controlAngle * 2 + t * 6 * math.pi + seed * 3.1);
      final double controlRadius = baseRadius * (1.0 + controlRadiusNoise);
      final cpX = center.dx + controlRadius * math.cos(controlAngle);
      final cpY = center.dy + controlRadius * math.sin(controlAngle);

      path.quadraticBezierTo(cpX, cpY, p1.dx, p1.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;

    if (isDark) {
      // Dark mode: deep space background
      final bgPaint = Paint()..color = const Color(0xFF010208);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

      final centerX = size.width * 0.5;
      final centerY = size.height * 0.68;

      // ── Primary: vivid dark BLUE blob ──
      // Drifts with its own orbit so it separates from the purple
      final blueRadius = size.width * 0.85;
      final blueCenter = Offset(
        centerX + size.width * 0.08 * math.sin(t * 2 * math.pi),
        centerY + size.height * 0.05 * math.cos(t * 2 * math.pi + 0.3),
      );
      final bluePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF1A3A9F).withValues(alpha: 0.90), // vivid dark blue
            const Color(0xFF0E1F5E).withValues(alpha: 0.50),
            const Color(0x00030611),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: blueCenter, radius: blueRadius * 1.3));
      _drawBlob(canvas, blueCenter, blueRadius, bluePaint, t, 1.0);

      // ── Secondary: vivid dark PURPLE blob ──
      // Counter-orbits the blue so the two visibly shift and overlap
      final purpleRadius = size.width * 0.70;
      final purpleCenter = Offset(
        centerX - size.width * 0.10 * math.cos(t * 2 * math.pi + 1.2),
        centerY - size.height * 0.04 * math.sin(t * 2 * math.pi + 0.8),
      );
      final purplePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF6B1FAA).withValues(alpha: 0.85), // vivid dark purple
            const Color(0xFF3A0B63).withValues(alpha: 0.40),
            const Color(0x00030611),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: purpleCenter, radius: purpleRadius * 1.3));
      _drawBlob(canvas, purpleCenter, purpleRadius, purplePaint, t, 3.2);

      // ── Blended indigo overlap glow ──
      // Sits between the two, creating a smooth purple-blue transition zone
      final blendCenter = Offset(
        (blueCenter.dx + purpleCenter.dx) * 0.5,
        (blueCenter.dy + purpleCenter.dy) * 0.5,
      );
      final blendRadius = size.width * 0.50;
      final blendPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF2E1B6B).withValues(alpha: 0.70), // deep indigo blend
            const Color(0xFF150830).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: blendCenter, radius: blendRadius * 1.3));
      _drawBlob(canvas, blendCenter, blendRadius, blendPaint, t, 5.5);
    } else {
      // Light mode: Gorgeous pastel flowing gradient glow
      final bgPaint = Paint()..color = const Color(0xFFF4F6FC); // base light blue-gray
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

      final centerX = size.width * 0.5;
      final centerY = size.height * 0.68;

      // Soft warm sky-blue glow
      final mainGlowRadius = size.width * 1.1;
      final blueCenter = Offset(
        centerX + size.width * 0.03 * math.sin(t * 2 * math.pi),
        centerY + size.height * 0.03 * math.cos(t * 2 * math.pi),
      );
      final bluePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFD4E2FF).withValues(alpha: 0.85), // pastel baby blue
            const Color(0xFFE0EBFF).withValues(alpha: 0.4),
            const Color(0xFFF4F6FC).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: blueCenter, radius: mainGlowRadius * 1.25));
      _drawBlob(canvas, blueCenter, mainGlowRadius, bluePaint, t, 1.5);

      // Soft warm lavender glow
      final secondaryCenter = Offset(
        centerX - size.width * 0.05 * math.cos((t + 0.3) * 2 * math.pi),
        centerY - size.height * 0.04 * math.sin((t + 0.3) * 2 * math.pi),
      );
      final secondaryRadius = size.width * 0.75;
      final secondaryPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFF3E5F5).withValues(alpha: 0.8), // pastel lavender
            const Color(0xFFF9F3FC).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: secondaryCenter, radius: secondaryRadius * 1.25));
      _drawBlob(canvas, secondaryCenter, secondaryRadius, secondaryPaint, t, 3.0);

      // Soft warm peach/rose glow
      final peachCenter = Offset(
        centerX + size.width * 0.04 * math.cos((t - 0.2) * 2 * math.pi),
        centerY + size.height * 0.05 * math.sin((t - 0.2) * 2 * math.pi),
      );
      final peachRadius = size.width * 0.6;
      final peachPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE8E8).withValues(alpha: 0.75), // soft peach/pink
            const Color(0xFFFFF7F7).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: peachCenter, radius: peachRadius * 1.25));
      _drawBlob(canvas, peachCenter, peachRadius, peachPaint, t, 5.0);
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedGradientPainter oldDelegate) =>
      oldDelegate.animation.value != animation.value || oldDelegate.isDark != isDark;
}

// ---------------------------------------------------------------------------
// Mobile layout (< 600dp) — responsive, vertical flex, non-scrollable
// ---------------------------------------------------------------------------
class _MobileLayout extends ConsumerWidget {
  const _MobileLayout({
    required this.constraints,
    required this.onMenuPressed,
  });

  final BoxConstraints constraints;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(timerProvider.select((s) => s.status));
    final isIdle = status == ChimeStatus.idle;

    final scale = ResponsiveScale.of(context);
    // Dynamically size countdown arc to scale with screen height and scale factor
    final arcSize = (constraints.maxHeight * 0.32).clamp(180.0, 280.0 * scale.scaleFactor);

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: scale.h(12),
      ),
      child: Column(
        children: [
          SizedBox(height: scale.h(12)),

          // App header — unpadded horizontally so the hamburger menu sits at the far left edge
          _AppHeader(onMenuPressed: onMenuPressed),

          const Spacer(flex: 2),

          // Transition between Setup Wheel Picker and Active Countdown Display — padded horizontally by 24
          Expanded(
            flex: 12,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: scale.w(24)),
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
          ),

          const Spacer(flex: 2),

          // Controls Bar (Starts/stops/pauses) — padded horizontally by 24
          Padding(
            padding: EdgeInsets.symmetric(horizontal: scale.w(24)),
            child: const ControlBar(),
          ),

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
  const _AppHeader({required this.onMenuPressed});

  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ResponsiveScale.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scale.w(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: AppColors.textPrimary.withValues(alpha: 0.5),
              size: scale.sp(28),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              onMenuPressed();
            },
          ),
          Text(
            'TICKR',
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.8),
              fontSize: scale.sp(19),
              letterSpacing: scale.w(10.0),
              fontWeight: FontWeight.w300,
            ),
          ),
          SizedBox(width: scale.w(48)), // Balances the 48dp leading hamburger icon touch target for perfect centering
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide-out Left Navigation Drawer
// ---------------------------------------------------------------------------
class _TickrDrawer extends ConsumerWidget {
  const _TickrDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    // Determine layout scale dynamically
    final isTablet = screenWidth >= 600;
    final layoutWidth = isTablet ? 500.0 : screenWidth;
    
    final scaleX = (layoutWidth / 375.0).clamp(0.85, 1.4);
    final scaleY = (screenHeight / 812.0).clamp(0.85, 1.4);
    final scaleFactor = ((scaleX + scaleY) / 2.0).clamp(0.85, 1.4);

    // Calculate drawer width: 30% of screen width on tablet, 75% on mobile
    final drawerWidth = isTablet 
        ? (screenWidth * 0.3).clamp(280.0, 450.0) 
        : (screenWidth * 0.75).clamp(240.0, 320.0);

    return ResponsiveScale(
      scaleX: scaleX,
      scaleY: scaleY,
      scaleFactor: scaleFactor,
      child: Builder(
        builder: (context) {
          final scale = ResponsiveScale.of(context);
          return SizedBox(
            width: drawerWidth,
            child: Drawer(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xDC090D1C),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      border: Border(
                        right: BorderSide(
                          color: Color(0x26FFFFFF),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: scale.h(40)),
                          // Elegant, minimalist OPTIONS header
                          Text(
                            'OPTIONS',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: scale.sp(16),
                              letterSpacing: scale.w(6.0),
                              fontWeight: FontWeight.w300,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: scale.h(40)),

                          // Drawer items leading to dedicated pages
                          _buildDrawerItem(
                            context,
                            icon: Icons.tune_rounded,
                            title: 'Presets',
                            onTap: () {
                              Navigator.pop(context); // Close drawer
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const PresetsScreen()),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            context,
                            icon: Icons.volume_up_rounded,
                            title: 'Chime Sounds',
                            onTap: () {
                              Navigator.pop(context); // Close drawer
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ChimesScreen()),
                              );
                            },
                          ),

                          const Spacer(),

                          Center(
                            child: Text(
                              'v1.0.0 • T I C K R',
                              style: TextStyle(
                                color: AppColors.textDisabled,
                                fontSize: scale.sp(10),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          SizedBox(height: scale.h(20)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final scale = ResponsiveScale.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: scale.w(16), vertical: scale.h(2)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: scale.w(12), vertical: scale.h(14)),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppColors.textPrimary.withValues(alpha: 0.7),
                size: scale.sp(20),
              ),
              SizedBox(width: scale.w(16)),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: scale.sp(14),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted.withValues(alpha: 0.4),
                size: scale.sp(18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
