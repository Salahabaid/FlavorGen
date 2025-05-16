/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 * eslint-disable max-len
 */
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendFavoritePush = functions.firestore
    .document('favorites/{userId}/recipes/{recipeId}')
    .onCreate(async (snap, context) => {
      const userId = context.params.userId;
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      const userData = userDoc.data();
      if (!userData || !userData.notif_push || !userData.fcmToken) return null;

      const recipe = snap.data();
      const message =
      'La recette "' +
      recipe.title +
      '" a été ajoutée à vos favoris.';
      const payload = {
        notification: {
          title: 'Favori ajouté',
          body: message,
        },
      };
      return admin.messaging().sendToDevice(userData.fcmToken, payload);
    });
