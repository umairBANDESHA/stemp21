const {setGlobalOptions} = require("firebase-functions");
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

setGlobalOptions({maxInstances: 10});

exports.deleteUserAuth = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "Request not authenticated",
    );
  }

  const callerUid = context.auth.uid;
  const callerDoc = await admin
      .firestore()
      .collection("users")
      .doc(callerUid)
      .get();

  if (!callerDoc.exists ||
        !["Admin", "Sub-admin"].includes(callerDoc.data().role)
  ) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Only Admin or Sub-admin can delete users",
    );
  }

  const uidToDelete = data.uid;
  if (!uidToDelete) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "UID is required",
    );
  }

  try {
    await admin.auth().deleteUser(uidToDelete);
    return {success: true};
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});
