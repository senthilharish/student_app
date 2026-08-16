import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const _keyThemeMode = 'theme_mode';
  static const _keyNotificationsMuted = 'notifications_muted';
  static const _keyQuietHoursEnabled = 'quiet_hours_enabled';
  static const _keyQuietHoursStart = 'quiet_hours_start';
  static const _keyQuietHoursEnd = 'quiet_hours_end';

  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsMuted = false;
  bool _quietHoursEnabled = false;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 21, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 6, minute: 0);
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get notificationsMuted => _notificationsMuted;
  bool get quietHoursEnabled => _quietHoursEnabled;
  TimeOfDay get quietHoursStart => _quietHoursStart;
  TimeOfDay get quietHoursEnd => _quietHoursEnd;
  bool get isLoaded => _isLoaded;

  SettingsService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_keyThemeMode);
    if (modeIndex != null && modeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[modeIndex];
    }
    _notificationsMuted = prefs.getBool(_keyNotificationsMuted) ?? false;
    _quietHoursEnabled = prefs.getBool(_keyQuietHoursEnabled) ?? false;
    _quietHoursStart = _decodeTime(
      prefs.getString(_keyQuietHoursStart),
      _quietHoursStart,
    );
    _quietHoursEnd = _decodeTime(
      prefs.getString(_keyQuietHoursEnd),
      _quietHoursEnd,
    );
    _isLoaded = true;
    notifyListeners();
  }

  TimeOfDay _decodeTime(String? value, TimeOfDay fallback) {
    if (value == null) return fallback;
    final parts = value.split(':');
    if (parts.length != 2) return fallback;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return fallback;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _encodeTime(TimeOfDay time) => '${time.hour}:${time.minute}';

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }

  Future<void> setNotificationsMuted(bool muted) async {
    _notificationsMuted = muted;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsMuted, muted);
  }

  Future<void> setQuietHoursEnabled(bool enabled) async {
    _quietHoursEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyQuietHoursEnabled, enabled);
  }

  Future<void> setQuietHoursStart(TimeOfDay time) async {
    _quietHoursStart = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyQuietHoursStart, _encodeTime(time));
  }

  Future<void> setQuietHoursEnd(TimeOfDay time) async {
    _quietHoursEnd = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyQuietHoursEnd, _encodeTime(time));
  }

  /// Whether the current moment falls inside the configured quiet hours window.
  bool isWithinQuietHours() {
    if (!_quietHoursEnabled) return false;
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = _quietHoursStart.hour * 60 + _quietHoursStart.minute;
    final endMinutes = _quietHoursEnd.hour * 60 + _quietHoursEnd.minute;

    if (startMinutes == endMinutes) return false;
    if (startMinutes < endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    }
    // Window wraps past midnight (e.g. 21:00 -> 06:00).
    return nowMinutes >= startMinutes || nowMinutes < endMinutes;
  }

  /// Static, non-reactive check used by services that aren't wired to Provider.
  static Future<bool> shouldSuppressNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final muted = prefs.getBool(_keyNotificationsMuted) ?? false;
    if (muted) return true;

    final quietEnabled = prefs.getBool(_keyQuietHoursEnabled) ?? false;
    if (!quietEnabled) return false;

    final start = _decodeTimeStatic(
      prefs.getString(_keyQuietHoursStart),
      const TimeOfDay(hour: 21, minute: 0),
    );
    final end = _decodeTimeStatic(
      prefs.getString(_keyQuietHoursEnd),
      const TimeOfDay(hour: 6, minute: 0),
    );

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes == endMinutes) return false;
    if (startMinutes < endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    }
    return nowMinutes >= startMinutes || nowMinutes < endMinutes;
  }

  static TimeOfDay _decodeTimeStatic(String? value, TimeOfDay fallback) {
    if (value == null) return fallback;
    final parts = value.split(':');
    if (parts.length != 2) return fallback;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return fallback;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
