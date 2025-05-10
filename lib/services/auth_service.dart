import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Inscription avec e-mail et mot de passe
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await userCredential.user!.sendEmailVerification();

      return userCredential.user;
    } catch (e) {
      print('Erreur lors de l\'inscription : $e');
      return null;
    }
  }

  Future<bool> checkEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> sendVerificationEmail() async {
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.sendEmailVerification();
        print('Email de vérification renvoyé avec succès');
      } else {
        print('Aucun utilisateur connecté pour envoyer la vérification');
        throw Exception('Utilisateur non authentifié');
      }
    } catch (e) {
      print('Erreur lors de l\'envoi de l\'email de vérification: $e');
      rethrow;
    }
  }

  // Connexion avec e-mail et mot de passe
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Erreur lors de la connexion : $e');
      return null;
    }
  }

  // Inscription avec Google
  Future<User?> signUpWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await userCredential.user!.sendEmailVerification();
      }

      return userCredential.user;
    } catch (e) {
      print('Erreur Google SignUp: $e');
      return null;
    }
  }

  // Connexion avec Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // L'utilisateur a annulé
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      return userCredential.user;
    } catch (e) {
      print('Erreur lors de la connexion avec Google : $e');
      return null;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ✅ Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Email de réinitialisation envoyé');
    } catch (e) {
      print('Erreur lors de la réinitialisation du mot de passe : $e');
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }
}
