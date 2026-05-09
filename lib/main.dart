// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/app_data.dart';
import 'screens/welcome_screen.dart';

void main() => runApp(const AhorraApp());

class AhorraApp extends StatelessWidget {
  const AhorraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppData()..load(),
      child: MaterialApp(
        title: 'Ahorra',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: const WelcomeScreen(),
      ),
    );
  }
}
