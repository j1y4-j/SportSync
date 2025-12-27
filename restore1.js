const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function restoreUsersWithBookings() {
  const usersSnapshot = await db.collection("users").get();

  for (const userDoc of usersSnapshot.docs) {
    const userId = userDoc.id;

    // Query all slots where bookedBy contains this user
    const slotsSnapshot = await db.collectionGroup("slots")
      .where("bookedBy", "array-contains", userId)
      .get();

    const totalBookings = slotsSnapshot.size;

    await db.collection("users").doc(userId).update({ totalBookings });

    console.log(`User ${userId} updated. Total bookings: ${totalBookings}`);
  }
}

restoreUsersWithBookings().then(() => {
  console.log("All users restored with totalBookings!");
  process.exit(0);
}).catch(err => {
  console.error(err);
  process.exit(1);
});
