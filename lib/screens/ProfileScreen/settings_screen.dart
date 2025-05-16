import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flavorgen/screens/Authentification/signin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'password_and_security_screen.dart';
import 'personal_info_screen.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _SettingsTile(
                    icon: Icons.security,
                    text: 'Password and security',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PasswordAndSecurityScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.person_outline,
                    text: 'Personal information',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PersonalInfoScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_none,
                    text: 'Notification',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.logout,
                    text: 'Logout',
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignInScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.delete_outline,
                    text: 'Delete all my recipes',
                    textColor: Color(0xFFE63946),
                    iconColor: Color(0xFFE63946),
                    onTap: () async {
                      await _deleteAllFavorites(context);
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.delete_forever_outlined,
                    text: 'Delete account',
                    textColor: Color(0xFFE63946),
                    iconColor: Color(0xFFE63946),
                    onTap: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      try {
                        // Supprimer le document Firestore
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .delete();

                        // Supprimer le compte Firebase Auth
                        await user.delete();

                        // Rediriger vers la page de connexion
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignInScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        if (e.code == 'requires-recent-login') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please re-authenticate to delete your account.',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.message}')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAllFavorites(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final recipesRef = FirebaseFirestore.instance
        .collection('favorites')
        .doc(user.uid)
        .collection('recipes');

    final snapshot = await recipesRef.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All favorite recipes deleted')),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String text;
  final Color? textColor;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    this.icon,
    this.iconWidget,
    required this.text,
    this.textColor,
    this.iconColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                iconWidget ??
                    Icon(icon, color: iconColor ?? const Color(0xFF9FA5C0)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: textColor ?? const Color(0xFF3E5481),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                trailing ??
                    const Icon(
                      Icons.keyboard_arrow_right,
                      color: Color(0xFF9FA5C0),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
