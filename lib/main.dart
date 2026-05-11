// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'utils/app_data.dart';
import 'utils/auth_helper.dart';
import 'utils/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/pin_setup_screen.dart';
import 'screens/pin_entry_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AuthHelper.printInitStatus();
  await NotificationService.init();
  runApp(const AhorraApp());
}

class AhorraApp extends StatelessWidget {
  const AhorraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppData(),
      child: MaterialApp(
        title: 'Ahorra',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: const SplashScreen(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastUid;

  Future<bool> _hasPinSet(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString('pin_$uid');
    return pin != null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D2E2B),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final user = snapshot.data;

        if (user != null && user.uid != _lastUid) {
          _lastUid = user.uid;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AppData>().load();
          });
        }

        if (user == null) {
          _lastUid = null;
          return const WelcomeScreen();
        }

        // This FutureBuilder forces the PIN screen EVERY time the user is authenticated
        return FutureBuilder<bool>(
          future: _hasPinSet(user.uid),
          builder: (_, pinSnapshot) {
            if (pinSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                backgroundColor: Color(0xFF0D2E2B),
                body: Center(
                    child: CircularProgressIndicator(color: Colors.white)),
              );
            }
            final hasPin = pinSnapshot.data ?? false;
            if (!hasPin) {
              return const PinSetupScreen(); // first time → create PIN
            } else {
              return const PinEntryScreen(); // every other time → enter PIN
            }
          },
        );
      },
    );
  }
}
