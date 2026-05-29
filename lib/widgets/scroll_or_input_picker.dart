import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/vibration_service.dart';
import '../theme/app_theme.dart';

class ScrollOrInputPicker extends ConsumerStatefulWidget {
  const ScrollOrInputPicker({
    super.key,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.unit,
    required this.onChanged,
    this.enabled = true,
  });

  final int value;
  final int minValue;
  final int maxValue;
  final String unit;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  ConsumerState<ScrollOrInputPicker> createState() => _ScrollOrInputPickerState();
}

class _ScrollOrInputPickerState extends ConsumerState<ScrollOrInputPicker> {
  bool _isEditing = false;
  late TextEditingController _textCtrl;
  late FixedExtentScrollController _scrollCtrl;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.value.toString().padLeft(2, '0'));
    _scrollCtrl = FixedExtentScrollController(initialItem: widget.value - widget.minValue);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant ScrollOrInputPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _textCtrl.text = widget.value.toString().padLeft(2, '0');
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpToItem(widget.value - widget.minValue);
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _saveAndToggle();
    }
  }

  void _startEditing() {
    if (!widget.enabled) return;
    setState(() {
      _isEditing = true;
      _textCtrl.text = widget.value.toString();
      _textCtrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _textCtrl.text.length,
      );
    });
    _focusNode.requestFocus();
  }

  void _saveAndToggle() {
    final text = _textCtrl.text;
    int? newValue = int.tryParse(text);
    if (newValue != null) {
      newValue = newValue.clamp(widget.minValue, widget.maxValue);
      widget.onChanged(newValue);
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpToItem(newValue - widget.minValue);
      }
    }
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 3000),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(anim),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: _isEditing ? _buildInputMode(theme) : _buildScrollMode(theme),
    );
  }

  Widget _buildInputMode(ThemeData theme) {
    return Container(
      key: const ValueKey('input_mode'),
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 70,
            child: TextField(
              controller: _textCtrl,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _saveAndToggle(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              VibrationService.vibrateForTap(ref.read(tapsHapticStrengthProvider) ?? 'medium');
              _saveAndToggle();
            },
            icon: Icon(
              Icons.check_circle_rounded,
              color: AppColors.primaryLight,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollMode(ThemeData theme) {
    final totalItems = widget.maxValue - widget.minValue + 1;

    return Stack(
      key: const ValueKey('scroll_mode'),
      alignment: Alignment.center,
      children: [
        // List of numbers
        SizedBox(
          height: 120,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // Ensure we provide tactile haptics feedback if scroll clicks (optional)
              return false;
            },
            child: ListWheelScrollView.useDelegate(
              controller: _scrollCtrl,
              itemExtent: 40,
              perspective: 0.007,
              diameterRatio: 1.2,
              physics: widget.enabled
                  ? const FixedExtentScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              onSelectedItemChanged: (index) {
                if (widget.enabled) {
                  final val = index + widget.minValue;
                  if (val != widget.value) {
                    VibrationService.vibrateForScroll(ref.read(scrollHapticStrengthProvider) ?? 'heavy');
                  }
                  widget.onChanged(val);
                }
              },
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  if (index < 0 || index >= totalItems) return null;
                  final itemValue = index + widget.minValue;
                  final isSelected = itemValue == widget.value;

                  return Center(
                    child: Text(
                      itemValue.toString().padLeft(2, '0'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: isSelected ? 24 : 18,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? (widget.enabled ? AppColors.textPrimary : AppColors.textDisabled)
                            : AppColors.textMuted.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                },
                childCount: totalItems,
              ),
            ),
          ),
        ),

        // Middle highlighted indicator overlay
        IgnorePointer(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.enabled
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.textDisabled.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
        ),

        // Invisible tap overlay on the center area to trigger direct typing
        if (widget.enabled)
          Positioned(
            height: 44,
            left: 0,
            right: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                VibrationService.vibrateForTap(ref.read(tapsHapticStrengthProvider) ?? 'medium');
                _startEditing();
              },
            ),
          ),

        // Unit label below the wheel
        Positioned(
          bottom: 4,
          child: IgnorePointer(
            child: Text(
              widget.unit,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: widget.enabled ? AppColors.textMuted : AppColors.textDisabled,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
