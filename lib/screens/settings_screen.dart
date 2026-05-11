// lib/screens/settings_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart'; // ⬅️ ADDED for sharing
import '../utils/ahorra_colors.dart';
import '../utils/app_data.dart';
import '../utils/data_export_helper.dart';
import 'welcome_screen.dart';
import 'data_debug_screen.dart';
import 'terms_screen.dart';

Future<String> _copyImageFile(Map<String, String> args) async {
  final source = File(args['sourcePath']!);
  final dest = await source.copy(args['destPath']!);
  return dest.path;
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _notificationsEnabled = true;
  String _selectedCurrency = 'PHP';
  String _selectedTheme = 'System';
  bool _isLoading = false;
  String? _localImagePath;

  User? get _user => FirebaseAuth.instance.currentUser;

  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();

  final List<String> _currencies = [
    'PHP',
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'AUD',
    'CAD',
  ];
  final List<String> _themes = ['Light', 'Dark', 'System'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadUserData();
    _loadLocalProfileImage();
  }

  Future<void> _loadLocalProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image_${user.uid}');
    if (path != null && File(path).existsSync() && mounted) {
      setState(() => _localImagePath = path);
    }
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;
    _displayNameController.text = _user?.displayName ?? '';
    _emailController.text = _user?.email ?? '';
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _selectedCurrency = prefs.getString('currency') ?? 'PHP';
      _selectedTheme = prefs.getString('theme') ?? 'System';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notificationsEnabled);
    await prefs.setString('currency', _selectedCurrency);
    await prefs.setString('theme', _selectedTheme);
  }

  void _toggleNotifications(bool value) {
    setState(() => _notificationsEnabled = value);
    _saveSettings();
  }

  void _changeCurrency(String? currency) {
    if (currency != null) {
      setState(() => _selectedCurrency = currency);
      _saveSettings();
      Navigator.of(context).pop();
    }
  }

  void _changeTheme(String? theme) {
    if (theme != null) {
      setState(() => _selectedTheme = theme);
      _saveSettings();
      Navigator.of(context).pop();
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AhorraColors.teal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCurrencyDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Currency',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._currencies.map(
              (c) => ListTile(
                title: Text(c),
                trailing: _selectedCurrency == c
                    ? const Icon(Icons.check, color: AhorraColors.teal)
                    : null,
                onTap: () => _changeCurrency(c),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Theme',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._themes.map(
              (t) => ListTile(
                title: Text(t),
                trailing: _selectedTheme == t
                    ? const Icon(Icons.check, color: AhorraColors.teal)
                    : null,
                onTap: () => _changeTheme(t),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    _displayNameController.text = _user?.displayName ?? '';
    final user = _user;
    final photoUrl = user?.photoURL;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_localImagePath != null) ...[
                CircleAvatar(
                  radius: 32,
                  backgroundImage: FileImage(File(_localImagePath!)),
                ),
                const SizedBox(height: 12),
              ] else if (photoUrl != null && photoUrl.isNotEmpty) ...[
                CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(photoUrl),
                ),
                const SizedBox(height: 12),
              ],
              TextButton.icon(
                onPressed: _pickProfileImage,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Change profile picture'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                enabled: false,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateProfile(context),
            style: ElevatedButton.styleFrom(backgroundColor: AhorraColors.teal),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _displayNameController.text.trim().isNotEmpty) {
        await user.updateDisplayName(_displayNameController.text.trim());
        await user.reload();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'displayName': _displayNameController.text.trim(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (pickedFile == null) return;
    if (mounted) Navigator.of(context).pop();
    setState(() => _isLoading = true);
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final savedPath = await compute(_copyImageFile, {
        'sourcePath': pickedFile.path,
        'destPath': '${appDir.path}/profile_${user.uid}.jpg',
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_${user.uid}', savedPath);
      if (!mounted) return;
      setState(() => _localImagePath = savedPath);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile picture: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text(
          'You signed in with Google. To change your password, please go to your Google Account settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ─── Share file helper ──────────────────────────────────────────────────
  void _shareFile(String filePath, String fileName) {
    Share.shareXFiles([
      XFile(filePath),
    ], text: 'Here is your Ahorra export file: $fileName');
  }

  // ─── EXPORT DATA – saves to app-private folder + share button ─────────────
  Future<void> _exportData() async {
    final appData = context.read<AppData>();
    final option = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Export Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV (Transactions)'),
              onTap: () => Navigator.pop(ctx, 'csv'),
            ),
            ListTile(
              leading: const Icon(Icons.data_object),
              title: const Text('JSON (All data)'),
              onTap: () => Navigator.pop(ctx, 'json'),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Full Report (TXT)'),
              onTap: () => Navigator.pop(ctx, 'report'),
            ),
          ],
        ),
      ),
    );
    if (option == null) return;

    setState(() => _isLoading = true);
    try {
      String content;
      String filename;
      switch (option) {
        case 'csv':
          content = await DataExportHelper.exportToCsv(appData.transactions);
          filename =
              'ahorra_transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
          break;
        case 'json':
          content = await DataExportHelper.exportToJson(
            appData.wallets,
            appData.transactions,
            appData.budgets,
          );
          filename =
              'ahorra_backup_${DateTime.now().millisecondsSinceEpoch}.json';
          break;
        case 'report':
          content = await DataExportHelper.generateReport(appData);
          filename =
              'ahorra_report_${DateTime.now().millisecondsSinceEpoch}.txt';
          break;
        default:
          return;
      }
      // Save to app-private folder (Ahorra Exports) using updated helper
      await DataExportHelper.saveToFile(content, filename);
      final dir = await getApplicationDocumentsDirectory();
      final fullPath = '${dir.path}/Ahorra Exports/$filename';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Saved: $filename'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'SHARE',
            textColor: Colors.white,
            onPressed: () => _shareFile(fullPath, filename),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Delete data only ────────────────────────────────────────────────────
  Future<void> _deleteData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete your wallets, transactions, budgets and all stored data, but your account will remain active.',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      final appData = context.read<AppData>();
      await appData.deleteUserData();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pin_${user.uid}');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data cleared'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Delete account ──────────────────────────────────────────────────────
  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure? This will permanently delete all your data and your account. This action cannot be undone.',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final localContext = context;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();
        await user.delete();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pin_${user.uid}');
        final appData = localContext.read<AppData>();
        await appData.clearAll();
        if (!mounted) return;
        Navigator.of(localContext).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = e.message ?? 'Account deletion failed.';
        if (e.code == 'requires-recent-login') {
          message =
              'Please sign out and sign in again before deleting your account.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Sign Out ────────────────────────────────────────────────────────────
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final appData = context.read<AppData>();
              await appData.clearAll();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ─── Help Center ─────────────────────────────────────────────────────────
  Future<void> _openHelpCenter() async {
    final uri = Uri.parse('https://sites.google.com/view/ahorra-help');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open help center. Please check your internet connection.',
          ),
        ),
      );
    }
  }

  // ─── Send Feedback (email updated) ──────────────────────────────────────
  Future<void> _sendFeedback() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'loniewaynelicayan@gmail.com',
      queryParameters: {'subject': 'Ahorra Feedback'},
    );
    try {
      await launchUrl(uri);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email app found on this device.')),
      );
    }
  }

  Future<void> _rateApp() async {
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.example.ahorra',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the store app.')),
      );
    }
  }

  void _showTerms() {
    showDialog(context: context, builder: (_) => const TermsModal());
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Your privacy is important to us.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'We do not collect any personal data beyond what is necessary for authentication and core functionality. '
                'All financial data is stored securely in Firebase Firestore and is only accessible by you when logged in. '
                'We do not share your data with third parties.\n\n'
                'If you have any questions, contact us at loniewaynelicayan@gmail.com.',
                style: TextStyle(height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final double hPad = size.width * 0.045;
    final double topInset = media.padding.top;
    final user = _user;
    final photoUrl = user?.photoURL;
    final displayName =
        user?.displayName ?? (user?.email?.split('@').first ?? 'User');
    final email = user?.email ?? 'No email';

    final DecorationImage? profileImage = _localImagePath != null
        ? DecorationImage(
            image: FileImage(File(_localImagePath!)),
            fit: BoxFit.cover,
          )
        : (photoUrl != null && photoUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(photoUrl),
                  fit: BoxFit.cover,
                )
              : null);
    final bool hasProfileImage = profileImage != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F0),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AhorraColors.bgTop, AhorraColors.bgBottom],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    hPad,
                    (topInset * 0.45) + (size.height * 0.012),
                    hPad,
                    size.height * 0.03,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Settings',
                            style: TextStyle(
                              color: AhorraColors.textWhite,
                              fontSize: size.width * 0.06,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: EdgeInsets.all(size.width * 0.025),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.close,
                                color: AhorraColors.textWhite,
                                size: size.width * 0.05,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: size.height * 0.018),
                      // Profile row
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _showEditProfileDialog,
                            child: Container(
                              width: size.width * 0.18,
                              height: size.width * 0.18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2),
                                image: profileImage,
                              ),
                              child: !hasProfileImage
                                  ? Center(
                                      child: Text(
                                        displayName.isNotEmpty
                                            ? displayName[0].toUpperCase()
                                            : '👤',
                                        style: TextStyle(
                                          fontSize: size.width * 0.09,
                                          fontWeight: FontWeight.w600,
                                          color: AhorraColors.textWhite,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          SizedBox(width: size.width * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    color: AhorraColors.textWhite,
                                    fontSize: size.width * 0.05,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  email,
                                  style: TextStyle(
                                    color: AhorraColors.textMuted,
                                    fontSize: size.width * 0.033,
                                  ),
                                ),
                                if (user?.providerData.isNotEmpty ?? false)
                                  Text(
                                    'Linked with: ${user!.providerData.first.providerId}',
                                    style: TextStyle(
                                      color: AhorraColors.textMuted,
                                      fontSize: size.width * 0.025,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _showEditProfileDialog,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: size.width * 0.04,
                                vertical: size.height * 0.008,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Edit',
                                style: TextStyle(
                                  color: AhorraColors.textLight,
                                  fontSize: size.width * 0.03,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Settings list
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: hPad,
                      vertical: size.height * 0.02,
                    ),
                    child: Column(
                      children: [
                        _SettingsSection(
                          title: 'Preferences',
                          children: [
                            _SettingsTile(
                              icon: Icons.attach_money_outlined,
                              title: 'Currency',
                              subtitle: _selectedCurrency,
                              onTap: _showCurrencyDialog,
                            ),
                            _SettingsTile(
                              icon: Icons.palette_outlined,
                              title: 'Theme',
                              subtitle: _selectedTheme,
                              onTap: _showThemeDialog,
                            ),
                            _SwitchSettingsTile(
                              icon: Icons.notifications_outlined,
                              title: 'Push Notifications',
                              value: _notificationsEnabled,
                              onChanged: _toggleNotifications,
                            ),
                          ],
                        ),
                        SizedBox(height: size.height * 0.02),
                        _SettingsSection(
                          title: 'Account',
                          children: [
                            _SettingsTile(
                              icon: Icons.edit_outlined,
                              title: 'Edit Profile',
                              subtitle: 'Update your name and photo',
                              onTap: _showEditProfileDialog,
                            ),
                            _SettingsTile(
                              icon: Icons.lock_outline,
                              title: 'Change Password',
                              subtitle:
                                  'Update your password (Google users: use Google account)',
                              onTap: _changePassword,
                            ),
                          ],
                        ),
                        SizedBox(height: size.height * 0.02),
                        _SettingsSection(
                          title: 'Data Management',
                          children: [
                            _SettingsTile(
                              icon: Icons.science,
                              title: 'Generator',
                              subtitle: 'Debug data for analytics',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DataDebugScreen(),
                                ),
                              ),
                            ),
                            _SettingsTile(
                              icon: Icons.backup_outlined,
                              title: 'Backup Data',
                              subtitle: 'Backup your data to cloud',
                              onTap: () => _showComingSoon('Backup'),
                            ),
                            _SettingsTile(
                              icon: Icons.restore_outlined,
                              title: 'Restore Data',
                              subtitle: 'Restore from backup',
                              onTap: () => _showComingSoon('Restore'),
                            ),
                            _SettingsTile(
                              icon: Icons.file_download_outlined,
                              title: 'Export Data',
                              subtitle: 'Export as CSV, JSON, or full report',
                              onTap: _exportData,
                            ),
                          ],
                        ),
                        SizedBox(height: size.height * 0.02),
                        _SettingsSection(
                          title: 'Support',
                          children: [
                            _SettingsTile(
                              icon: Icons.help_outline,
                              title: 'Help Center',
                              subtitle: 'FAQs and guides',
                              onTap: _openHelpCenter,
                            ),
                            _SettingsTile(
                              icon: Icons.feedback_outlined,
                              title: 'Send Feedback',
                              subtitle: 'Help us improve Ahorra',
                              onTap: _sendFeedback,
                            ),
                            _SettingsTile(
                              icon: Icons.star_outline,
                              title: 'Rate the App',
                              subtitle: 'Rate us on the store',
                              onTap: _rateApp,
                            ),
                            _SettingsTile(
                              icon: Icons.description_outlined,
                              title: 'Terms & Conditions',
                              subtitle: 'Read our terms',
                              onTap: _showTerms,
                            ),
                            _SettingsTile(
                              icon: Icons.privacy_tip_outlined,
                              title: 'Privacy Policy',
                              subtitle: 'How we handle your data',
                              onTap: _showPrivacyPolicy,
                            ),
                          ],
                        ),
                        SizedBox(height: size.height * 0.02),
                        _SettingsSection(
                          title: 'Danger Zone',
                          children: [
                            _SettingsTile(
                              icon: Icons.delete_sweep,
                              title: 'Clear All Data',
                              subtitle:
                                  'Delete wallets, transactions & budgets but keep your account',
                              onTap: _deleteData,
                              iconColor: Colors.orange,
                              textColor: Colors.orange,
                            ),
                            _SettingsTile(
                              icon: Icons.delete_forever,
                              title: 'Delete Account',
                              subtitle:
                                  'Permanently delete your account and all data',
                              onTap: _deleteAccount,
                              iconColor: Colors.red,
                              textColor: Colors.red,
                            ),
                            _SettingsTile(
                              icon: Icons.logout,
                              title: 'Sign Out',
                              subtitle: 'Sign out from your account',
                              onTap: _showLogoutDialog,
                              iconColor: Colors.red,
                              textColor: Colors.red,
                            ),
                          ],
                        ),
                        SizedBox(height: size.height * 0.04),
                        Center(
                          child: Text(
                            'Version 1.0.0',
                            style: TextStyle(
                              color: const Color(0xFFAAAAAA),
                              fontSize: size.width * 0.03,
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(color: AhorraColors.teal),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable widgets ────────────────────────────────────────────────────────
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: w * 0.02, bottom: w * 0.025),
          child: Text(
            title,
            style: TextStyle(
              fontSize: w * 0.038,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF555555),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });
  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.04,
            vertical: w * 0.035,
          ),
          child: Row(
            children: [
              Container(
                width: w * 0.1,
                height: w * 0.1,
                decoration: BoxDecoration(
                  color: (iconColor ?? AhorraColors.teal).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AhorraColors.teal,
                  size: w * 0.05,
                ),
              ),
              SizedBox(width: w * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.w600,
                        color: textColor ?? const Color(0xFF1A1A1A),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: w * 0.03,
                          color: const Color(0xFF888888),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: const Color(0xFFCCCCCC),
                size: w * 0.055,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchSettingsTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.02),
      child: Row(
        children: [
          Container(
            width: w * 0.1,
            height: w * 0.1,
            decoration: BoxDecoration(
              color: AhorraColors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AhorraColors.teal, size: w * 0.05),
          ),
          SizedBox(width: w * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: w * 0.038,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AhorraColors.teal,
            activeTrackColor: AhorraColors.teal.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}
