import 'package:flutter/material.dart';
import 'change_password_screen.dart';
import 'two_factor_auth_screen.dart';

class PasswordAndSecurityScreen extends StatelessWidget {
  const PasswordAndSecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Password and security',
          style: TextStyle(color: Color(0xFF3E5481)),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF3E5481)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo Flavor
            Center(child: Image.asset('assets/images/logo.png', height: 48)),
            const SizedBox(height: 32),
            const Text(
              'Password and security',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E5481),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your passwords, login preferences and recovery methods.',
              style: TextStyle(fontSize: 14, color: Color(0xFF9FA5C0)),
            ),
            const SizedBox(height: 32),
            _SecurityOptionTile(
              icon: Icons.lock_outline,
              text: 'Change password',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _SecurityOptionTile(
              icon: Icons.verified_user_outlined,
              text: 'Two-factor authentification',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TwoFactorAuthScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SecurityOptionTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _SecurityOptionTile({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF9FA5C0)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF3E5481),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_right, color: Color(0xFF9FA5C0)),
            ],
          ),
        ),
      ),
    );
  }
}
