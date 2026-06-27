import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final themeMode = await ThemeModeNotifier.load();
  runApp(ProviderScope(
    overrides: [
      initialThemeModeProvider.overrideWithValue(themeMode),
    ],
    child: const App(),
  ));
}
