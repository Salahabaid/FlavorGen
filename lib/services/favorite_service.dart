import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flavorgen/models/recipe.dart' as model;
import 'dart:convert';
import 'package:http/http.dart' as http;

class FavoriteService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  // Ajouter une recette aux favoris
  Future<void> addFavorite(model.Recipe recipe) async {
    final uid = userId;
    if (uid == null) return;
    await _firestore
        .collection('favorites')
        .doc(uid)
        .collection('recipes')
        .doc(recipe.id.toString())
        .set(recipe.toMap());

    // Récupère le token FCM de l'utilisateur cible depuis Firestore
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final fcmToken = userDoc.data()?['fcmToken'];

    // Appelle la fonction d'envoi FCM
    if (fcmToken != null) {
      await sendFCMNotification(
        serverKey:
            'cMON22DaQMO8Lzw3zznc7s:APA91bFz2WQmABlBZasLvxVhMC9zkKhjY4gBiiyLnL3FAmnat9uaM7xo7xjvcv-iLMJ5p5IdDcajGIDq6XSI8fPfMg7UnTYjoHUFnWhN99pekEvTLWUZ42s', // Mets ici ta clé serveur FCM (voir ci-dessous)
        fcmToken: fcmToken,
        title: 'Favori ajouté',
        body: 'La recette "${recipe.title}" a été ajoutée à vos favoris.',
      );
    }
  }

  // Supprimer une recette des favoris
  Future<void> removeFavorite(String recipeId) async {
    final uid = userId;
    if (uid == null) return;
    await _firestore
        .collection('favorites')
        .doc(uid)
        .collection('recipes')
        .doc(recipeId)
        .delete();
  }

  // Vérifier si une recette est favorite
  Future<bool> isFavorite(String recipeId) async {
    final uid = userId;
    if (uid == null) return false;
    final doc =
        await _firestore
            .collection('favorites')
            .doc(uid)
            .collection('recipes')
            .doc(recipeId)
            .get();
    return doc.exists;
  }

  // Récupérer tous les favoris de l'utilisateur (stream de Recipe)
  Stream<List<model.Recipe>> getFavorites() {
    final uid = userId;
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection('favorites')
        .doc(uid)
        .collection('recipes')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => model.Recipe.fromJson(doc.data()))
                  .toList(),
        );
  }

  Future<void> sendFCMNotification({
    required String serverKey,
    required String fcmToken,
    required String title,
    required String body,
  }) async {
    final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };
    final payload = {
      'to': fcmToken,
      'notification': {'title': title, 'body': body},
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      print('Erreur FCM: ${response.body}');
    }
    print('FCM status: ${response.statusCode}');
    print('FCM response: ${response.body}');
  }
}
