import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _push = false;
  bool _email = false;
  bool _suggestions = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    initFCM();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final data = doc.data();
    setState(() {
      _push = data?['notif_push'] ?? false;
      _email = data?['notif_email'] ?? false;
      _suggestions = data?['notif_suggestions'] ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'notif_push': _push,
      'notif_email': _email,
      'notif_suggestions': _suggestions,
    }, SetOptions(merge: true));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification settings updated')),
    );
  }

  void initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Demander la permission (iOS)
    await messaging.requestPermission();

    // Obtenir le token
    String? token = await messaging.getToken();
    print('FCM Token: $token');

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3E5481),
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Push Notifications'),
                      value: _push,
                      onChanged: (val) => setState(() => _push = val),
                    ),
                    SwitchListTile(
                      title: const Text('Email Notifications'),
                      value: _email,
                      onChanged: (val) => setState(() => _email = val),
                    ),
                    SwitchListTile(
                      title: const Text('Suggestions'),
                      value: _suggestions,
                      onChanged: (val) => setState(() => _suggestions = val),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1FCC79),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
