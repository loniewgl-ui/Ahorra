// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'utils/app_data.dart';
import 'utils/auth_helper.dart';
import 'utils/notification_service.dart';
import 'screens/setup/splash_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/setup/pin_setup_screen.dart';
import 'screens/setup/pin_entry_screen.dart';

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
  String? _lastFirebaseUid;
  String? _localUid;
  bool? _hasLocalPin;
  bool _checkingLocal = true;

  @override
  void initState() {
    super.initState();
    _checkLocalAuth();
  }

  Future<void> _checkLocalAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('lastUid');
    if (uid != null && uid.isNotEmpty) {
      final pin = prefs.getString('pin_$uid');
      if (pin != null && pin.isNotEmpty) {
        _localUid = uid;
        _hasLocalPin = true;
      }
    }
    _checkingLocal = false;
    if (mounted) setState(() {});
  }

  Future<bool> _hasPinSet(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final localPin = prefs.getString('pin_$uid');
    if (localPin != null) return true;

    // Check Firestore for PIN hash (new device, same account)
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final pinHash = doc.data()?['pinHash'] as String?;
      if (pinHash != null && pinHash.isNotEmpty) {
        await prefs.setString('pin_$uid', pinHash);
        return true;
      }
    } catch (_) {}

    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingLocal) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D2E2B),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

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

        if (user != null && user.uid != _lastFirebaseUid) {
          _lastFirebaseUid = user.uid;
          _localUid = null;
          _hasLocalPin = null;
          SharedPreferences.getInstance().then((prefs) {
            prefs.setString('lastUid', user.uid);
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AppData>().load();
          });
        }

        // Fallback: Firebase user is null but we have a local PIN → offline access
        if (user == null && _localUid != null && _hasLocalPin == true) {
          return PinEntryScreen(uid: _localUid);
        }

        if (user == null) {
          _lastFirebaseUid = null;
          return const WelcomeScreen();
        }

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
              return const PinSetupScreen();
            } else {
              return const PinEntryScreen();
            }
          },
        );
      },
    );
  }
}
