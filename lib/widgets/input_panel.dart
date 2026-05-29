import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_scale.dart';
import 'unified_wheel_picker.dart';

class InputPanel extends ConsumerWidget {
  const InputPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ResponsiveScale.of(context);

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        SizedBox(height: scale.h(24)),
        Text(
          'SET INTERVAL',
          style: TextStyle(
            fontSize: scale.sp(10),
            fontWeight: FontWeight.w500,
            letterSpacing: scale.w(5.0),
            color: Colors.white.withValues(alpha: 0.35),
          ),
        ),
        SizedBox(height: scale.h(22)),

        // The unified 3-column scroll picker
        const Expanded(child: UnifiedWheelPicker()),

        SizedBox(height: scale.h(24)),

        // Dynamic presets label
        Text(
          'PRESETS',
          style: TextStyle(
            fontSize: scale.sp(10),
            fontWeight: FontWeight.w500,
            letterSpacing: scale.w(5.0),
            color: Colors.white.withValues(alpha: 0.30),
          ),
        ),
        SizedBox(height: scale.h(16)),

        // Dynamic, horizontally scrollable presets list
        Consumer(
          builder: (context, ref, child) {
            final presets = ref.watch(presetsProvider);

            if (presets.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: scale.h(8)),
                  child: Text(
                    'No saved presets — add from Options',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: scale.sp(12),
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            }

            return PresetsScrollArea(
              presets: presets,
              presetBuilder: (context, preset) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: scale.w(4)),
                  child: _buildPresetButton(
                    context,
                    ref,
                    label: preset.label,
                    mins: preset.minutes,
                    secs: preset.seconds,
                    reps: preset.reps,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPresetButton(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required int mins,
    required int secs,
    required int reps,
  }) {
    final currentMin = ref.watch(intervalMinutesProvider);
    final currentSec = ref.watch(intervalSecondsProvider);
    final currentRep = ref.watch(totalRepsProvider);
    final isActive = currentMin == mins && currentSec == secs && currentRep == reps;

    final scale = ResponsiveScale.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(intervalMinutesProvider.notifier).set(mins);
        ref.read(intervalSecondsProvider.notifier).set(secs);
        ref.read(totalRepsProvider.notifier).set(reps);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(scale.sp(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: scale.w(20),
              vertical: scale.h(10),
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(scale.sp(20)),
              border: Border.all(
                color: isActive
                    ? AppColors.primaryLight.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.10),
                width: 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.45),
                fontSize: scale.sp(12),
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                letterSpacing: scale.w(0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Horizontally scrollable presets list with elegant fade-out & blue chevrons
// ---------------------------------------------------------------------------
class PresetsScrollArea extends StatefulWidget {
  final List<ChimePreset> presets;
  final Widget Function(BuildContext, ChimePreset) presetBuilder;

  const PresetsScrollArea({
    super.key,
    required this.presets,
    required this.presetBuilder,
  });

  @override
  State<PresetsScrollArea> createState() => _PresetsScrollAreaState();
}

class _PresetsScrollAreaState extends State<PresetsScrollArea> {
  late final ScrollController _scrollController;
  bool _showLeftArrow = true;
  bool _showRightArrow = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateArrows);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PresetsScrollArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  void _updateArrows() {
    if (!mounted || !_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    // If the list fits perfectly on the screen, show both arrows for design symmetry.
    // If it is scrollable, dynamically fade them out when reaching the scroll limits.
    final isScrollable = maxScroll > 4.0;
    final showLeft = !isScrollable || (currentScroll > 4);
    final showRight = !isScrollable || (currentScroll < maxScroll - 4);
    
    if (_showLeftArrow != showLeft || _showRightArrow != showRight) {
      setState(() {
        _showLeftArrow = showLeft;
        _showRightArrow = showRight;
      });
    }
  }

  void _scroll(bool forward) {
    if (!_scrollController.hasClients) return;
    final double scrollAmount = 140.0;
    final double target = _scrollController.offset + (forward ? scrollAmount : -scrollAmount);
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = ResponsiveScale.of(context);

    // Determine progressive edge-fade states based on scroll position
    final double maxScroll = _scrollController.hasClients ? _scrollController.position.maxScrollExtent : 0.0;
    final double currentScroll = _scrollController.hasClients ? _scrollController.position.pixels : 0.0;
    final bool isScrollable = maxScroll > 4.0;
    
    final bool fadeLeft = isScrollable && currentScroll > 4;
    final bool fadeRight = isScrollable && currentScroll < maxScroll - 4;

    return SizedBox(
      height: scale.h(48), // Comfortable height for preset pills
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none, // Allow chevrons to sit outside parent bounds
        alignment: Alignment.center,
        children: [
          // The horizontal scroll view of presets wrapped in a smooth fading ShaderMask
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    fadeLeft ? Colors.transparent : Colors.white,
                    Colors.white,
                    Colors.white,
                    fadeRight ? Colors.transparent : Colors.white,
                  ],
                  stops: const [0.0, 0.12, 0.88, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification) {
                    _updateArrows();
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: scale.w(12)), // Spacious side margins
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widget.presets.map((preset) {
                      return widget.presetBuilder(context, preset);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

          // Left Arrow - Sleek floating chevron positioned in the outer margins
          Positioned(
            left: -scale.w(24), // Positioned further to the absolute edge to avoid overlapping the presets
            top: 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: _showLeftArrow ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: IgnorePointer(
                ignoring: !_showLeftArrow,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _scroll(false);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: scale.w(36),
                    height: double.infinity,
                    color: Colors.transparent,
                    alignment: Alignment.centerLeft,
                    child: Icon(
                      Icons.chevron_left,
                      color: AppColors.selectedItem.withValues(alpha: 0.8), // Sleek, semi-transparent cyan color
                      size: scale.sp(27), // Sleek thin sharp chevron
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Right Arrow - Sleek floating chevron positioned in the outer margins
          Positioned(
            right: -scale.w(24), // Positioned further to the absolute edge to avoid overlapping the presets
            top: 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: _showRightArrow ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: IgnorePointer(
                ignoring: !_showRightArrow,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _scroll(true);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: scale.w(36),
                    height: double.infinity,
                    color: Colors.transparent,
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.chevron_right,
                      color: AppColors.selectedItem.withValues(alpha: 0.8), // Sleek, semi-transparent cyan color
                      size: scale.sp(27), // Sleek thin sharp chevron
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
