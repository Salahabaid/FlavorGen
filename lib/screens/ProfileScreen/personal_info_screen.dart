import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _country;
  File? _avatarFile;
  String? _avatarUrl;
  bool _isLoading = false;

  String? _countryCode = '+33'; // Valeur par défaut (France)
  String? _countryName = 'France';

  final List<String> _countries = [
    'France',
    'United Kingdom',
    'USA',
    'Germany',
    'Spain',
    'Italy',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final data = doc.data();
    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _emailController.text = data['email'] ?? user.email ?? '';
      _phoneController.text = data['phone'] ?? '';
      _country = data['country'];
      _avatarUrl = data['photoUrl'];
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
      // TODO: Upload to Firebase Storage and get URL, then update Firestore
    }
  }

  // Validation avancée
  bool _validateFields() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
      return false;
    }
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Phone number is required')));
      return false;
    }
    if (_countryName == null || _countryName!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Country is required')));
      return false;
    }
    return true;
  }

  // Upload avatar to Firebase Storage and get URL
  Future<String?> _uploadAvatar(File file, String uid) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('$uid.jpg');
      final uploadTask = await ref.putFile(file);
      if (uploadTask.state == TaskState.success) {
        return await ref.getDownloadURL();
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Avatar upload failed: $e')));
      return null;
    }
  }

  Future<String?> _saveAvatarLocally(File file, String uid) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final localPath = '${dir.path}/avatar_$uid.jpg';
      final localFile = await file.copy(localPath);
      return localFile.path;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Avatar local save failed: $e')));
      return null;
    }
  }

  Future<void> _saveChanges() async {
    if (!_validateFields()) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? photoUrl = _avatarUrl;
    // Save avatar locally if a new file is selected
    if (_avatarFile != null) {
      photoUrl = await _saveAvatarLocally(_avatarFile!, user.uid);
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'country': _countryName,
      if (photoUrl != null) 'photoUrl': photoUrl,
    }, SetOptions(merge: true));

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
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
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage:
                            _avatarFile != null
                                ? FileImage(_avatarFile!)
                                : (_avatarUrl != null
                                        ? FileImage(File(_avatarUrl!))
                                        : const AssetImage(
                                          'assets/images/avatar_placeholder.png',
                                        ))
                                    as ImageProvider,
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 16,
                            child: Icon(
                              Icons.edit,
                              color: Colors.grey[700],
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    IntlPhoneField(
                      controller: _phoneController,
                      initialCountryCode:
                          _countryCode?.replaceAll('+', '') ?? 'FR',
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (phone) {
                        // phone.countryCode contient le code, phone.number le numéro
                        setState(() {
                          _countryCode = '+${phone.countryCode}';
                          _countryName = phone.countryISOCode;
                        });
                      },
                      onCountryChanged: (country) {
                        setState(() {
                          _countryCode = '+${country.dialCode}';
                          _countryName = country.name;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(_countryName ?? 'Select country'),
                      trailing: const Icon(Icons.arrow_drop_down),
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          showPhoneCode:
                              false, // <-- N'affiche pas le code dans la liste
                          onSelect: (Country country) {
                            setState(() {
                              _countryName = country.name;
                              _countryCode =
                                  '+${country.phoneCode}'; // Toujours mis à jour pour le champ téléphone
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1FCC79),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save changes',
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF3E5481)),
      title: Text(text, style: const TextStyle(color: Color(0xFF3E5481))),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
