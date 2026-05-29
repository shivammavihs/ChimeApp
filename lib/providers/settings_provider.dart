import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Keys
// ---------------------------------------------------------------------------
const _kIntervalMinutes = 'interval_minutes';
const _kIntervalSeconds = 'interval_seconds';
const _kTotalReps = 'total_reps';

// ---------------------------------------------------------------------------
// SharedPreferences singleton provider
// ---------------------------------------------------------------------------
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

// ---------------------------------------------------------------------------
// Interval minutes (1–60)
// ---------------------------------------------------------------------------
final intervalMinutesProvider = StateNotifierProvider<IntSettingNotifier, int>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return IntSettingNotifier(
      prefs: prefs,
      key: _kIntervalMinutes,
      defaultValue: 3,
      min: 0,
      max: 60,
    );
  },
);

// ---------------------------------------------------------------------------
// Interval seconds (0–59) – fine-grained control within the minute
// ---------------------------------------------------------------------------
final intervalSecondsProvider =
    StateNotifierProvider<IntSettingNotifier, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return IntSettingNotifier(
    prefs: prefs,
    key: _kIntervalSeconds,
    defaultValue: 0,
    min: 0,
    max: 59,
  );
});

// ---------------------------------------------------------------------------
// Total repetitions (1–99)
// ---------------------------------------------------------------------------
final totalRepsProvider = StateNotifierProvider<IntSettingNotifier, int>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return IntSettingNotifier(
      prefs: prefs,
      key: _kTotalReps,
      defaultValue: 5,
      min: 1,
      max: 99,
    );
  },
);

// ---------------------------------------------------------------------------
// Derived: total interval in seconds
// ---------------------------------------------------------------------------
final intervalSecondsTotal = Provider<int>((ref) {
  final m = ref.watch(intervalMinutesProvider);
  final s = ref.watch(intervalSecondsProvider);
  final total = m * 60 + s;
  return total < 1 ? 1 : total;
});

// ---------------------------------------------------------------------------
// Generic integer setting notifier
// ---------------------------------------------------------------------------
class IntSettingNotifier extends StateNotifier<int> {
  IntSettingNotifier({
    required SharedPreferences prefs,
    required String key,
    required int defaultValue,
    required int min,
    required int max,
  })  : _prefs = prefs,
        _key = key,
        _min = min,
        _max = max,
        super(prefs.getInt(key) ?? defaultValue);

  final SharedPreferences _prefs;
  final String _key;
  final int _min;
  final int _max;

  void increment() => _set(state + 1);
  void decrement() => _set(state - 1);
  void set(int value) => _set(value);

  void _set(int value) {
    final clamped = value.clamp(_min, _max);
    if (clamped == state) return;
    state = clamped;
    _prefs.setInt(_key, clamped);
  }
}

// ---------------------------------------------------------------------------
// Custom Chime Sound Path Persistence
// ---------------------------------------------------------------------------
const _kCustomChimeSoundPath = 'custom_chime_sound_path';

final customChimeSoundPathProvider =
    StateNotifierProvider<StringSettingNotifier, String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StringSettingNotifier(
    prefs: prefs,
    key: _kCustomChimeSoundPath,
    defaultValue: null,
  );
});

class StringSettingNotifier extends StateNotifier<String?> {
  StringSettingNotifier({
    required SharedPreferences prefs,
    required String key,
    String? defaultValue,
  })  : _prefs = prefs,
        _key = key,
        super(prefs.getString(key) ?? defaultValue);

  final SharedPreferences _prefs;
  final String _key;

  void set(String? value) {
    if (value == state) return;
    state = value;
    if (value == null) {
      _prefs.remove(_key);
    } else {
      _prefs.setString(_key, value);
    }
  }

  void clear() => set(null);
}

// ---------------------------------------------------------------------------
// Theme mode persistence
// ---------------------------------------------------------------------------
const _kIsDarkMode = 'is_dark_mode';

final isDarkModeProvider = StateNotifierProvider<BoolSettingNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BoolSettingNotifier(
    prefs: prefs,
    key: _kIsDarkMode,
    defaultValue: true,
  );
});

class BoolSettingNotifier extends StateNotifier<bool> {
  BoolSettingNotifier({
    required SharedPreferences prefs,
    required String key,
    required bool defaultValue,
  })  : _prefs = prefs,
        _key = key,
        super(prefs.getBool(key) ?? defaultValue);

  final SharedPreferences _prefs;
  final String _key;

  void toggle() => set(!state);

  void set(bool value) {
    if (value == state) return;
    state = value;
    _prefs.setBool(_key, value);
  }
}

// ---------------------------------------------------------------------------
// Haptics Strengths Persistence
// ---------------------------------------------------------------------------
const _kTapsHapticStrength = 'taps_haptic_strength';
const _kScrollHapticStrength = 'scroll_haptic_strength';
const _kChimeHapticStrength = 'chime_haptic_strength';

final tapsHapticStrengthProvider =
    StateNotifierProvider<StringSettingNotifier, String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StringSettingNotifier(
    prefs: prefs,
    key: _kTapsHapticStrength,
    defaultValue: 'medium',
  );
});

final scrollHapticStrengthProvider =
    StateNotifierProvider<StringSettingNotifier, String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StringSettingNotifier(
    prefs: prefs,
    key: _kScrollHapticStrength,
    defaultValue: 'heavy', // Make default 'heavy' as request asked to increase dial haptics
  );
});

final chimeHapticStrengthProvider =
    StateNotifierProvider<StringSettingNotifier, String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StringSettingNotifier(
    prefs: prefs,
    key: _kChimeHapticStrength,
    defaultValue: 'medium',
  );
});

// ---------------------------------------------------------------------------
// Selected chime type persistence ('dragon_studio_alert', 'notification_message_alert', etc.)
// ---------------------------------------------------------------------------
const _kSelectedChimeType = 'selected_chime_type';

final selectedChimeTypeProvider =
    StateNotifierProvider<StringSettingNotifier, String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StringSettingNotifier(
    prefs: prefs,
    key: _kSelectedChimeType,
    defaultValue: 'dragon_studio_alert',
  );
});

// ---------------------------------------------------------------------------
// Chime Preset Model and Provider
// ---------------------------------------------------------------------------
class ChimePreset {
  final String id;
  final String label;
  final int minutes;
  final int seconds;
  final int reps;

  ChimePreset({
    required this.id,
    required this.label,
    required this.minutes,
    required this.seconds,
    required this.reps,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'minutes': minutes,
        'seconds': seconds,
        'reps': reps,
      };

  factory ChimePreset.fromJson(Map<String, dynamic> json) => ChimePreset(
        id: json['id'] as String,
        label: json['label'] as String,
        minutes: json['minutes'] as int,
        seconds: json['seconds'] as int,
        reps: json['reps'] as int,
      );
}

const _kPresets = 'chime_presets';

final presetsProvider =
    StateNotifierProvider<PresetsNotifier, List<ChimePreset>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PresetsNotifier(prefs: prefs);
});

class PresetsNotifier extends StateNotifier<List<ChimePreset>> {
  PresetsNotifier({required SharedPreferences prefs})
      : _prefs = prefs,
        super(_loadPresets(prefs));

  final SharedPreferences _prefs;

  static List<ChimePreset> _loadPresets(SharedPreferences prefs) {
    final list = prefs.getStringList(_kPresets);
    final defaultPresets = [
      ChimePreset(id: '1', label: '1m (5x)', minutes: 1, seconds: 0, reps: 5),
      ChimePreset(id: '2', label: '3m (5x)', minutes: 3, seconds: 0, reps: 5),
      ChimePreset(id: '3', label: '5m (10x)', minutes: 5, seconds: 0, reps: 10),
      ChimePreset(id: '4', label: '10m (10x)', minutes: 10, seconds: 0, reps: 10),
      ChimePreset(id: '5', label: '15m (15x)', minutes: 15, seconds: 0, reps: 15),
    ];
    if (list == null) {
      return defaultPresets;
    }
    try {
      final parsed = list
          .map((str) => ChimePreset.fromJson(json.decode(str) as Map<String, dynamic>))
          .toList();
      // If the user only has the original 3 defaults, upgrade them to the new 5 defaults
      if (parsed.length == 3 &&
          parsed[0].label == '1m (5x)' &&
          parsed[2].label == '5m (10x)') {
        return defaultPresets;
      }
      return parsed;
    } catch (e) {
      return defaultPresets;
    }
  }

  void _save() {
    final list = state.map((p) => json.encode(p.toJson())).toList();
    _prefs.setStringList(_kPresets, list);
  }

  void addPreset({
    required String label,
    required int minutes,
    required int seconds,
    required int reps,
  }) {
    final newPreset = ChimePreset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label,
      minutes: minutes,
      seconds: seconds,
      reps: reps,
    );
    state = [...state, newPreset];
    _save();
  }

  void deletePreset(String id) {
    state = state.where((p) => p.id != id).toList();
    _save();
  }
}



