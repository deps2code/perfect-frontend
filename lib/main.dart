import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/lobby/lobby_screen.dart';

void main() {
  runApp(const ProviderScope(child: PerfectApp()));
}

class PerfectApp extends StatelessWidget {
  const PerfectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perfect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF30E6FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF031026),
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: const LobbyScreen(),
    );
  }
}
