import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedMode = preferences.getString(_themeModeKey);

    switch (savedMode) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'auto':
      default:
        _themeMode = ThemeMode.system;
        break;
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();

    switch (mode) {
      case ThemeMode.light:
        await preferences.setString(_themeModeKey, 'light');
        break;
      case ThemeMode.dark:
        await preferences.setString(_themeModeKey, 'dark');
        break;
      case ThemeMode.system:
        await preferences.setString(_themeModeKey, 'auto');
        break;
    }
  }
}

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static ThemeController of(BuildContext context) {
    final scope =
    context.dependOnInheritedWidgetOfExactType<ThemeScope>();

    assert(scope != null, 'ThemeScope not found in widget tree.');

    return scope!.notifier!;
  }
}