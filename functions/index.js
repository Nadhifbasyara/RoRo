const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Trigger ketika dokumen baru dibuat di koleksi safety_notification_tests
exports.sendSafetyNotification = functions
    .runWith({memory: "256MB", timeoutSeconds: 30})
    .firestore.document("safety_notification_tests/{docId}")
    .onCreate(async (snap, context) => {
      const data = snap.data() || {};
      const title = data.title || "Safety Alert";
      const body = data.body || "Ada notifikasi safety";
      const sendToTopic = data.topic ?? "safety"; // optional override

      // Pesan FCM standar
      const message = {
        topic: sendToTopic,
        notification: {
          title: title,
          body: body,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "safety_chan",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              contentAvailable: true,
            },
          },
        },
        data: {
          type: "safety_test",
          docId: context.params.docId || "",
        },
      };

      try {
        const response = await admin.messaging().send(message);
        console.log("FCM sent, response:", response);

        // (Opsional) tulis status ke dokumen hasil
        await snap.ref.update({
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          status: "sent",
          fcmResponse: response,
        });
      } catch (err) {
        console.error("FCM send error", err);
        await snap.ref.update({
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          status: "error",
          errorMessage: err.message || String(err),
        });
      }
      return null;
    });
