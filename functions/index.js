const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// ─── Existing: Safety Notification ───────────────────────────────────────────

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

// ─── Scheduled: Reset hasWalkedToday setiap tengah malam WIB ─────────────────
//
// Cron "0 17 * * *" = jam 17:00 UTC = 00:00 WIB (UTC+7)
// Menggunakan firebase-functions v1 (gen 1) agar kompatibel dengan Spark plan.

exports.resetDailyWalkStatus = functions
    .pubsub.schedule("0 17 * * *")
    .timeZone("UTC")
    .onRun(async (_context) => {
      const db = admin.firestore();
      const rollatorRef = db.collection("rollators");

      const snapshot = await rollatorRef.get();

      if (snapshot.empty) {
        console.log("resetDailyWalkStatus: tidak ada dokumen ditemukan.");
        return null;
      }

      const BATCH_LIMIT = 500;
      let batch = db.batch();
      let opCount = 0;
      let totalReset = 0;

      for (const doc of snapshot.docs) {
        batch.update(doc.ref, {
          hasWalkedToday: false,
          lastResetAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        opCount++;
        totalReset++;

        if (opCount === BATCH_LIMIT) {
          await batch.commit();
          console.log(`Batch committed: ${totalReset} dokumen di-reset.`);
          batch = db.batch();
          opCount = 0;
        }
      }

      if (opCount > 0) {
        await batch.commit();
      }

      console.log(
          `resetDailyWalkStatus selesai: total ${totalReset} dokumen.`,
      );
      return null;
    });

// ─── Scheduled: Reset dashboard hasWalkedToday (dokumen spesifik) ────────────

exports.resetDailyDashboardStatus = functions
    .pubsub.schedule("0 17 * * *")
    .timeZone("UTC")
    .onRun(async (_context) => {
      const db = admin.firestore();

      await db.collection("dashboard").doc("albert").set(
          {
            hasWalkedToday: false,
            lastResetAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          {merge: true},
      );

      console.log("resetDailyDashboardStatus: hasWalkedToday di-reset.");
      return null;
    });
