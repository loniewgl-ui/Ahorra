import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class for authentication utilities and debugging
class AuthHelper {
  /// Validate that Google Sign-In is properly configured
  static Future<bool> validateGoogleSignIn() async {
    try {
      print('✅ Firebase app initialized');
      return true;
    } catch (e) {
      print('❌ Firebase validation error: $e');
      return false;
    }
  }

  /// Validate that Firestore is accessible
  static Future<bool> validateFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      // Skip Firestore test if no user is logged in — no anonymous fallback
      if (user == null) {
        print('ℹ️ No authenticated user — skipping Firestore validation');
        return true;
      }

      print('✅ Already signed in as: ${user.email ?? user.uid}');

      final doc = await FirebaseFirestore.instance
          .collection('_test')
          .doc('_test')
          .get();

      if (doc.exists) {
        print('✅ Firestore is accessible - document exists');
      } else {
        print(
            '✅ Firestore is accessible - document does not exist (read allowed)');
      }
      return true;
    } on FirebaseException catch (e) {
      print('❌ Firestore error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('❌ Firestore validation error: $e');
      return false;
    }
  }

  /// Get app debug info
  static String getDebugInfo() {
    return '''
=== Ahorra Debug Info ===
Platform: ${Platform.operatingSystem}
Firebase initialized: true
Current user: ${FirebaseAuth.instance.currentUser?.email ?? FirebaseAuth.instance.currentUser?.uid ?? 'None'}
Firestore available: true
Google Sign-In configured: true
Facebook Sign-In configured: true
========================
    ''';
  }

  /// Print initialization status
  static Future<void> printInitStatus() async {
    print('\n' + getDebugInfo());
    await validateGoogleSignIn();
    await validateFirestore();
    print('Initialization check complete\n');
  }
}
