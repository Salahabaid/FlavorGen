import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flavorgen/models/recipe.dart' as model;

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
}
