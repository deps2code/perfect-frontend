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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF246B5A)),
        useMaterial3: true,
      ),
      home: const LobbyScreen(),
    );
  }
}
