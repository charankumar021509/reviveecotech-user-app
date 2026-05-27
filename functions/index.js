/**
 * ─────────────────────────────────────────────────────────────────────────────
 * REVIVE ECO TECH - BACKEND FUNCTIONS (Hybrid v1/v2)
 * ─────────────────────────────────────────────────────────────────────────────
 */

// 1. V2 IMPORTS (For Database & Callable Functions)
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");

// 2. V1 IMPORT (For Auth Trigger - Bulletproof)
const functions = require("firebase-functions/v1");

// 3. ADMIN SDK
const admin = require("firebase-admin");
admin.initializeApp();

// 4. CONFIG
setGlobalOptions({ region: "asia-south1", maxInstances: 10 });

/**
 * HELPER: Sends Notification (Push + Database)
 */
async function sendNotification(userId, title, body, pickupId) {
  try {
    // A. Write to Firestore
    await admin.firestore()
      .collection("notifications")
      .doc(userId)
      .collection("userNotifications")
      .add({
        title: title,
        description: body,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        pickupId: pickupId,
        type: 'order_status'
      });

    // B. Send Push Notification
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return;

    await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      data: {
        pickupId: pickupId,
        click_action: "FLUTTER_NOTIFICATION_CLICK"
      }
    });

    console.log(`Push notification sent to: ${userId}`);
  } catch (error) {
    console.error("Error in sendNotification:", error);
  }
}

/**
 * ─────────────────────────────────────────────────────────────────────────────
 * TRIGGER 1: Create User Profile (Using v1 Syntax)
 * Reason: v1 Auth triggers are stable and don't require Identity Platform API.
 * ─────────────────────────────────────────────────────────────────────────────
 */
exports.createUserProfile = functions.auth.user().onCreate(async (user) => {
  const db = admin.firestore();

  // ✅ UPDATED: Added { merge: true } to prevent overwriting the role
  // if the assignUserRole function finishes a split second faster.
  await db.collection("users").doc(user.uid).set({
    phone: user.phoneNumber || "",
    email: user.email || "",
    name: "User-" + user.uid.substring(0, 6),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    fcmToken: "",
    currentAddress: null
  }, { merge: true });

  console.log(`✅ Created profile for user: ${user.uid}`);
});

/**
 * ─────────────────────────────────────────────────────────────────────────────
 * NEW TRIGGER: Assign User Role (v2 Callable)
 * Called immediately after signup from the Flutter App.
 * ─────────────────────────────────────────────────────────────────────────────
 */
exports.assignUserRole = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const uid = request.auth.uid;
  const requestedRole = request.data.role; // Expects 'customer' or 'scrap_collector'

  if (!['customer', 'scrap_collector'].includes(requestedRole)) {
    throw new HttpsError("invalid-argument", "Invalid role specified.");
  }

  try {
    // 1. Set Custom Claim
    await admin.auth().setCustomUserClaims(uid, { role: requestedRole });

    // 2. Mirror in Firestore using merge to avoid wiping auth trigger data
    await admin.firestore().collection('users').doc(uid).set({
      role: requestedRole,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    console.log(`✅ Role ${requestedRole} assigned successfully to user: ${uid}`);
    return { success: true, message: `Role ${requestedRole} assigned successfully.` };
  } catch (error) {
    console.error("Error assigning role:", error);
    throw new HttpsError("internal", "Failed to assign role.");
  }
});

/**
 * ─────────────────────────────────────────────────────────────────────────────
 * TRIGGER 2: Update User Profile (v2 Callable)
 * Called from Flutter for secure updates.
 * ─────────────────────────────────────────────────────────────────────────────
 */
exports.updateUserProfile = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const uid = request.auth.uid;
  const { name, phone, email } = request.data;
  const db = admin.firestore();
  const usersRef = db.collection("users");

  // Check Duplicate Phone
  if (phone) {
    const phoneSnapshot = await usersRef.where("phone", "==", phone).get();
    if (!phoneSnapshot.empty) {
      for (const doc of phoneSnapshot.docs) {
        if (doc.id !== uid) {
          throw new HttpsError("already-exists", "Phone number already in use.");
        }
      }
    }
  }

  // Check Duplicate Email
  if (email) {
    const emailSnapshot = await usersRef.where("email", "==", email).get();
    if (!emailSnapshot.empty) {
      for (const doc of emailSnapshot.docs) {
        if (doc.id !== uid) {
          throw new HttpsError("already-exists", "Email already in use.");
        }
      }
    }
  }

  // Update
  const updates = {};
  if (name) updates.name = name;
  if (phone) updates.phone = phone;
  if (email) updates.email = email;
  updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();

  await usersRef.doc(uid).set(updates, { merge: true });

  return { success: true, message: "Profile updated successfully." };
});

/**
 * ─────────────────────────────────────────────────────────────────────────────
 * TRIGGER 3: Pickup Created (v2 Notification)
 * ─────────────────────────────────────────────────────────────────────────────
 */
exports.onPickupCreated = onDocumentCreated("pickups/{pickupId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const data = snapshot.data();
  const userId = data.userId;
  const pickupId = event.params.pickupId;

  let dateString = "upcoming date";
  if (data.pickupDate) {
    const dateObj = data.pickupDate.toDate();
    // ✅ FIX: Force Asia/Kolkata timezone
    dateString = dateObj.toLocaleDateString("en-IN", {
      day: "numeric",
      month: "short",
      timeZone: "Asia/Kolkata"
    });
  }

  const title = "Pickup Requested";
  const body = `We received your request for ${dateString}. Please wait for confirmation.`;

  return sendNotification(userId, title, body, pickupId);
});

/**
 * ─────────────────────────────────────────────────────────────────────────────
 * TRIGGER 4: Pickup Status Changed OR Updated (v2 Notification)
 * ─────────────────────────────────────────────────────────────────────────────
 */
exports.onPickupStatusChanged = onDocumentUpdated("pickups/{pickupId}", async (event) => {
  const newData = event.data.after.data();
  const previousData = event.data.before.data();
  const userId = newData.userId;
  const pickupId = event.params.pickupId;

  let title = "";
  let body = "";

  // CASE A: Status Changed
  if (newData.status !== previousData.status) {
    // ✅ FIX: Get Proper Indian Date for Body Text
    let dateString = "today";
    if (newData.pickupDate) {
      dateString = newData.pickupDate.toDate().toLocaleDateString("en-IN", {
        day: "numeric",
        month: "short",
        timeZone: "Asia/Kolkata"
      });
    }
    const timeSlot = newData.pickupTimeSlot || "";

    switch (newData.status) {
      case "Confirmed":
        title = "Pickup Confirmed! ✅";
        // Shows: "Your pickup for 24 Oct (10 AM - 12 PM) has been accepted."
        body = `Your pickup for ${dateString} ${timeSlot ? `(${timeSlot})` : ""} has been accepted.`;
        break;
      case "Out-for-Pickup":
        title = "Agent is on the way! 🚚";
        body = "Our executive is out for pickup. Please keep your scraps ready.";
        break;
      case "Completed":
        // Use final rider price
        const amount = newData.finalPrice || 0;
        title = "Pickup Completed 🎉";
        body = `Transaction successful! You earned ₹${amount}.`;
        break;
      case "Cancelled":
        title = "Pickup Cancelled ❌";
        body = "Your pickup request has been cancelled.";
        break;
    }
  }
  // CASE B: Status Same, But Details Changed (The "Edit" Notification)
  else {
    const oldTime = previousData.pickupDate ? previousData.pickupDate.toMillis() : 0;
    const newTime = newData.pickupDate ? newData.pickupDate.toMillis() : 0;
    const oldSlot = previousData.pickupTimeSlot || "";
    const newSlot = newData.pickupTimeSlot || "";

    // If Date or Time Slot changed
    if (oldTime !== newTime || oldSlot !== newSlot) {
      // ✅ FIX: Force Asia/Kolkata timezone
      const dateObj = newData.pickupDate.toDate();
      const dateString = dateObj.toLocaleDateString("en-IN", {
        day: "numeric",
        month: "short",
        timeZone: "Asia/Kolkata"
      });

      title = "Pickup Updated ✏️";
      body = `Your pickup has been updated to ${dateString} ${newSlot ? `(${newSlot})` : ""}.`;
    }
  }

  // If no relevant change, do nothing
  if (!title) return null;

  return sendNotification(userId, title, body, pickupId);
});

// Add this to your Cloud Functions
exports.updateUserStatsOnCompletion = functions.firestore
  .document('pickups/{pickupId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    // 1. Check if status changed to 'Completed'
    if (oldData.status !== 'Completed' && newData.status === 'Completed') {
      const userId = newData.userId;

      // 2. STRICT ENFORCEMENT: Only use final actuals. Estimates are ignored entirely.
      // If the field is missing or empty, it safely defaults to 0 to prevent NaN math errors.
      const weight = Number(newData.finalWeight || 0);
      const earnings = Number(newData.amount || 0);

      // 3. Atomically Increment using FieldValue
      const userRef = admin.firestore().collection('users').doc(userId);

      try {
        await userRef.update({
          totalWeight: admin.firestore.FieldValue.increment(weight),
          totalEarnings: admin.firestore.FieldValue.increment(earnings),
          // Optional: Track count too
          completedPickupsCount: admin.firestore.FieldValue.increment(1)
        });
        console.log(`Updated stats for user ${userId}: +${weight}kg, +₹${earnings}`);
      } catch (error) {
        console.error("Failed to update user stats", error);
      }
    }
  });

/**
 * Helper Function: Batch Delete
 * Safely deletes any collection/subcollection in chunks of 500 to respect Firestore limits.
 */
async function deleteCollectionInBatches(db, collectionRef) {
  const snapshot = await collectionRef.get();
  if (snapshot.empty) return;

  const chunks = [];
  let batch = db.batch();
  let count = 0;

  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
    count++;

    if (count === 500) {
      chunks.push(batch.commit());
      batch = db.batch();
      count = 0;
    }
  });

  if (count > 0) {
    chunks.push(batch.commit());
  }

  await Promise.all(chunks);
}

/**
 * Delete User Account & PII
 * Recursively wipes the user profile, all nested subcollections (like addresses),
 * notifications, and Auth identity concurrently.
 */
exports.deleteUserAccount = functions.region('asia-south1').https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
  }

  const uid = context.auth.uid;
  const db = admin.firestore();

  try {
    // Execute deep deletions concurrently for maximum performance
    await Promise.all([
      // Recursively destroys users/{uid} AND users/{uid}/addresses
      db.recursiveDelete(db.collection('users').doc(uid)),

      // Recursively destroys notifications/{uid} AND notifications/{uid}/userNotifications
      db.recursiveDelete(db.collection('notifications').doc(uid))
    ]);

    // Destroy the Firebase Auth identity last
    await admin.auth().deleteUser(uid);

    return {
      success: true,
      message: 'Account and all personal data safely deleted.'
    };

  } catch (err) {
    console.error("Account Deletion Error:", err);
    throw new functions.https.HttpsError('internal', 'Account deletion failed.');
  }
});