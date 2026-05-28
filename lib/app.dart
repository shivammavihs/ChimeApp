import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/home_screen.dart';
import '../theme/app_theme.dart';

class ChimeApp extends ConsumerWidget {
  const ChimeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppColors.isDark = true;

    // Force system status-bar icons & navigation bar colors to match theme dynamically
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return MaterialApp(
      title: 'tickr',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
