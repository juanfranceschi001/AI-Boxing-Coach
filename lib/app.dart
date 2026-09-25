import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class AiBoxingCoachApp extends StatelessWidget {
  const AiBoxingCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Boxing Coach',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ).copyWith(
          secondary: Colors.redAccent,
          tertiary: Colors.red,
          error: Colors.redAccent,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
