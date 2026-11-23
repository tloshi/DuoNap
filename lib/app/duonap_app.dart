import 'package:flutter/material.dart';

import '../ui/today/duonap_today_screen.dart';
import 'duonap_theme.dart';

class DuoNapApp extends StatelessWidget {
  const DuoNapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DuoNap',
      debugShowCheckedModeBanner: false,
      theme: DuoNapTheme.dark(),
      home: const DuoNapTodayScreen(),
    );
  }
}
