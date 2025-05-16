import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:otp/otp.dart';

class TwoFactorAuthScreen extends StatefulWidget {
  const TwoFactorAuthScreen({super.key});

  @override
  State<TwoFactorAuthScreen> createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends State<TwoFactorAuthScreen> {
  final _passwordController = TextEditingController();
  final _totpController = TextEditingController();
  bool _showQRCode = false;
  bool _showTotpInput = false;
  String? _qrCodeUrl;
  String? _secretKey;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _totpController.dispose();
    super.dispose();
  }

  Future<void> _verifyPasswordAndGenerateQR() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user logged in');
      }

      // Re-authenticate user
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);

      // Générer une clé secrète TOTP (base32)
      final secret = OTP.randomSecret();

      // Générer l'URL otpauth pour Google Authenticator
      final otpauthUrl =
          'otpauth://totp/FlavorApp:${user.email}?secret=$secret&issuer=FlavorApp&digits=6';

      // Stocker le secret dans Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'totp_secret': secret,
      }, SetOptions(merge: true));

      setState(() {
        _showQRCode = true;
        _qrCodeUrl =
            'https://api.qrserver.com/v1/create-qr-code/?data=${Uri.encodeComponent(otpauthUrl)}&size=180x180';
        _secretKey = secret;
      });
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? 'An error occurred';
      if (e.code == 'wrong-password') {
        message = 'Current password is incorrect';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Vérifier le code TOTP saisi par l'utilisateur
  Future<void> _verifyTotpCode() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final secret = doc.data()?['totp_secret'];
      if (secret == null) throw Exception('No TOTP secret found');

      final code = _totpController.text.trim();
      final generated = OTP.generateTOTPCodeString(
        secret,
        DateTime.now().millisecondsSinceEpoch,
        interval: 30,
        length: 6,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );

      if (code == generated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('TOTP validé, accès autorisé')),
        );
        await Future.delayed(
          const Duration(seconds: 1),
        ); // Laisse le temps d'afficher le message
        if (mounted)
          Navigator.pop(context); // Retour à l'écran précédent (profil)
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Code incorrect')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Two-Factor Authentication',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            if (!_showQRCode && !_showTotpInput) ...[
              const Text(
                'Please re-enter your password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E5481),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF9FA5C0),
                  ),
                  hintText: 'Password',
                  hintStyle: const TextStyle(color: Color(0xFF9FA5C0)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyPasswordAndGenerateQR,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1FCC79),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Continue',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                ),
              ),
            ] else if (_showQRCode) ...[
              const Text(
                'Scan the QR code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E5481),
                ),
              ),
              const SizedBox(height: 16),
              if (_qrCodeUrl != null)
                Image.network(_qrCodeUrl!, height: 180, width: 180),
              const SizedBox(height: 16),
              const Text(
                'Use an authenticator app extension to scan',
                style: TextStyle(fontSize: 14, color: Color(0xFF9FA5C0)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Unable to scan? You can use the setup key to manually configure your authenticator app.',
                style: TextStyle(fontSize: 12, color: Color(0xFF9FA5C0)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_secretKey != null)
                SelectableText(
                  _secretKey!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Color(0xFF3E5481),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showQRCode = false;
                      _showTotpInput = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1FCC79),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'J\'ai scanné le QR code',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ] else if (_showTotpInput) ...[
              const Text(
                'Enter the 6-digit code from your Authenticator app',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E5481),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _totpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF9FA5C0),
                  ),
                  hintText: '123456',
                  hintStyle: const TextStyle(color: Color(0xFF9FA5C0)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyTotpCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1FCC79),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Valider le code',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
