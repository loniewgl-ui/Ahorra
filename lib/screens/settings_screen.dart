// settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/ahorra_colors.dart';
import 'welcome_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  String _selectedCurrency = 'PHP';
  String _selectedTheme = 'System';

  final List<String> _currencies = ['PHP', 'USD', 'EUR', 'GBP', 'JPY', 'AUD'];
  final List<String> _themes = ['Light', 'Dark', 'System'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _biometricEnabled = prefs.getBool('biometric') ?? false;
      _selectedCurrency = prefs.getString('currency') ?? 'PHP';
      _selectedTheme = prefs.getString('theme') ?? 'System';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notificationsEnabled);
    await prefs.setBool('biometric', _biometricEnabled);
    await prefs.setString('currency', _selectedCurrency);
    await prefs.setString('theme', _selectedTheme);
  }

  void _toggleNotifications(bool value) {
    setState(() => _notificationsEnabled = value);
    _saveSettings();
  }

  void _toggleBiometric(bool value) {
    setState(() => _biometricEnabled = value);
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
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F0),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
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
                  // Profile summary
                  Row(
                    children: [
                      Container(
                        width: size.width * 0.18,
                        height: size.width * 0.18,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Center(
                          child: Text(
                            '👤',
                            style: TextStyle(fontSize: size.width * 0.09),
                          ),
                        ),
                      ),
                      SizedBox(width: size.width * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'John Doe',
                              style: TextStyle(
                                color: AhorraColors.textWhite,
                                fontSize: size.width * 0.05,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'john.doe@example.com',
                              style: TextStyle(
                                color: AhorraColors.textMuted,
                                fontSize: size.width * 0.033,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
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
                    ],
                  ),
                ],
              ),
            ),

            // Settings List
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: hPad,
                  vertical: size.height * 0.02,
                ),
                child: Column(
                  children: [
                    // Preferences Section
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
                        _SwitchSettingsTile(
                          icon: Icons.fingerprint,
                          title: 'Biometric Login',
                          subtitle: 'Use fingerprint or face ID to unlock',
                          value: _biometricEnabled,
                          onChanged: _toggleBiometric,
                        ),
                      ],
                    ),

                    SizedBox(height: size.height * 0.02),

                    // Data Section
                    _SettingsSection(
                      title: 'Data Management',
                      children: [
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
                          subtitle: 'Export as CSV or PDF',
                          onTap: () => _showComingSoon('Export'),
                        ),
                      ],
                    ),

                    SizedBox(height: size.height * 0.02),

                    // Support Section
                    _SettingsSection(
                      title: 'Support',
                      children: [
                        _SettingsTile(
                          icon: Icons.help_outline,
                          title: 'Help Center',
                          subtitle: 'FAQs and guides',
                          onTap: () => _showComingSoon('Help Center'),
                        ),
                        _SettingsTile(
                          icon: Icons.feedback_outlined,
                          title: 'Send Feedback',
                          subtitle: 'Help us improve Ahorra',
                          onTap: () => _showComingSoon('Feedback'),
                        ),
                        _SettingsTile(
                          icon: Icons.star_outline,
                          title: 'Rate the App',
                          subtitle: 'Rate us on the store',
                          onTap: () => _showComingSoon('Rate'),
                        ),
                        _SettingsTile(
                          icon: Icons.description_outlined,
                          title: 'Terms & Conditions',
                          subtitle: 'Read our terms',
                          onTap: () => _showComingSoon('Terms'),
                        ),
                        _SettingsTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          subtitle: 'How we handle your data',
                          onTap: () => _showComingSoon('Privacy'),
                        ),
                      ],
                    ),

                    SizedBox(height: size.height * 0.02),

                    // Danger Zone
                    _SettingsSection(
                      title: 'Account',
                      children: [
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

                    // Version info
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
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: AhorraColors.teal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─── Settings Section ─────────────────────────────────────────────────────────

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

// ─── Settings Tile (onTap) ────────────────────────────────────────────────────

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
                  color: AhorraColors.teal.withOpacity(0.1),
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

// ─── Switch Settings Tile ─────────────────────────────────────────────────────

class _SwitchSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AhorraColors.teal,
            activeTrackColor: AhorraColors.teal.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}
