/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

exports.notifyOnFavorite = functions.firestore
    .document("favorites/{userId}/recipes/{recipeId}")
    .onCreate(async (snap, context) => {
      const userId = context.params.userId;
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) return null;

      const payload = {
        notification: {
          title: "Recette ajoutée aux favoris",
          body: "Vous venez d'ajouter une recette à vos favoris.",
        },
      };
      return admin.messaging().sendToDevice(fcmToken, payload);
    });
