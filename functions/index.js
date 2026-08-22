const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * 2nd-Gen HTTPS Callable Cloud Function for secure user account creation.
 * Exposes a callable endpoint for Admins to create HR and Employee accounts.
 */
exports.createUser = onCall(async (request) => {
  logger.info("Starting secure createUser function call.");

  try {
    // STEP 1: request.auth verification
    logger.info("STEP 1: Verifying request.auth");
    if (!request.auth) {
      logger.warn("STEP 1 Failure: request.auth is missing.");
      throw new HttpsError(
        "unauthenticated",
        "The function must be called by an authenticated user."
      );
    }

    const callerUid = request.auth.uid;
    logger.info(`STEP 1 Success: Caller is authenticated. UID: ${callerUid}`);

    // STEP 2: caller users/{callerUid} lookup
    logger.info(`STEP 2: Looking up caller profile in Firestore for UID: ${callerUid}`);
    let callerDoc;
    try {
      callerDoc = await admin.firestore().collection("users").doc(callerUid).get();
    } catch (dbErr) {
      logger.error("STEP 2 Failure: Firestore lookup query encountered an error.", dbErr);
      throw new HttpsError("internal", "An error occurred while checking administrator authorization.");
    }

    if (!callerDoc.exists) {
      logger.warn(`STEP 2 Failure: Caller profile document does not exist in users/${callerUid}`);
      throw new HttpsError(
        "failed-precondition",
        "Your system profile was not found. Access denied."
      );
    }

    // STEP 3: admin role verification
    logger.info("STEP 3: Verifying caller database role");
    const callerData = callerDoc.data();
    const callerRole = callerData ? callerData.role : null;
    logger.info(`STEP 3 details: Caller role in document is: ${callerRole}`);

    if (callerRole !== "admin") {
      logger.warn(`STEP 3 Failure: Caller role is not admin (role: ${callerRole})`);
      throw new HttpsError(
        "permission-denied",
        "Access denied: Only administrators are authorized to create users."
      );
    }
    logger.info("STEP 3 Success: Caller role is verified as admin.");

    // STEP 4: input validation
    logger.info("STEP 4: Validating input parameters");
    const { name, email, role } = request.data || {};

    if (!name || typeof name !== "string" || name.trim() === "") {
      logger.warn("STEP 4 Failure: Name parameter is invalid or empty.");
      throw new HttpsError("invalid-argument", "Name parameter is required and must be non-empty.");
    }

    if (!email || typeof email !== "string" || !email.includes("@")) {
      logger.warn("STEP 4 Failure: Email parameter is invalid or empty.");
      throw new HttpsError("invalid-argument", "A valid email address is required.");
    }

    if (role !== "hr" && role !== "employee") {
      logger.warn(`STEP 4 Failure: Invalid role requested: ${role}`);
      throw new HttpsError("invalid-argument", "Assigned role must be either 'hr' or 'employee'.");
    }
    logger.info(`STEP 4 Success: Input parameters validated. Creating user with role: ${role}`);

    // STEP 5: Firebase Admin Auth createUser()
    logger.info("STEP 5: Creating Firebase Authentication account");
    // Generate secure temporary password
    const tempPassword = Math.random().toString(36).substring(2, 8) + 
                         Math.random().toString(36).substring(2, 8).toUpperCase();

    let userRecord;
    try {
      userRecord = await admin.auth().createUser({
        email: email.trim().toLowerCase(),
        password: tempPassword,
        displayName: name.trim(),
      });
    } catch (authError) {
      logger.error("STEP 5 Failure: Auth account creation failed.", authError);
      if (authError.code === "auth/email-already-exists") {
        throw new HttpsError("already-exists", "The email address is already in use by another account.");
      }
      if (authError.code === "auth/invalid-email") {
        throw new HttpsError("invalid-argument", "The email address format is invalid.");
      }
      throw new HttpsError("internal", `Authentication registration failed: ${authError.message}`);
    }

    const generatedUid = userRecord.uid;
    logger.info(`STEP 5 Success: Auth account created. Generated UID: ${generatedUid}`);

    // STEP 6: Firestore users/{generatedUid} creation
    logger.info(`STEP 6: Mapping user profile document to users/${generatedUid}`);
    try {
      await admin.firestore().collection("users").doc(generatedUid).set({
        uid: generatedUid,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        role: role,
        status: "active",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      // 6.1 Create Audit Log (Server-side)
      try {
        await admin.firestore().collection("audit_logs").add({
          actorUid: callerUid,
          actorEmail: request.auth.token.email || "",
          action: "USER_CREATED",
          targetType: "user",
          targetId: generatedUid,
          description: `Created account for ${name.trim()} (${email.trim().toLowerCase()}) with role ${role}.`,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          metadata: {
            email: email.trim().toLowerCase(),
            role: role,
            name: name.trim()
          }
        });
      } catch (auditErr) {
        // Non-blocking: Audit log failure should not fail the user creation process
        logger.error("Failed to write USER_CREATED audit log: ", auditErr);
      }
    } catch (firestoreError) {
      logger.error(`STEP 6 Failure: Firestore document write failed for UID: ${generatedUid}. Initiating rollback.`, firestoreError);
      // Atomic rollback: Delete Auth account
      try {
        await admin.auth().deleteUser(generatedUid);
        logger.info(`STEP 6 Rollback: Successfully deleted orphaned Auth UID: ${generatedUid}`);
      } catch (rollbackError) {
        logger.error(`STEP 6 Rollback Error: Failed to delete orphaned Auth UID: ${generatedUid}`, rollbackError);
      }
      throw new HttpsError("internal", "Database profile mapping failed. Authentication was revoked.");
    }
    logger.info(`STEP 6 Success: Firestore profile mapping completed for UID: ${generatedUid}`);

    // STEP 7: successful response
    logger.info("STEP 7: Formulating successful response");
    return {
      success: true,
      uid: generatedUid,
      tempPassword: tempPassword,
    };

  } catch (error) {
    // If it's already an HttpsError, rethrow it directly
    if (error instanceof HttpsError) {
      throw error;
    }
    // For unexpected exceptions, log the full error stack and throw a generic internal error
    logger.error("Unexpected server-side exception occurred in createUser function:", error);
    throw new HttpsError("internal", "An unexpected internal server error occurred.");
  }
});

/**
 * 2nd-Gen HTTPS Callable Cloud Function for secure user profile modification.
 * Exposes a callable endpoint for Admins to update user profile information.
 */
exports.updateUser = onCall(async (request) => {
  logger.info("Starting secure updateUser function call.");

  try {
    // 1. Verify caller authentication status
    if (!request.auth) {
      logger.warn("unauthenticated access attempt.");
      throw new HttpsError(
        "unauthenticated",
        "The function must be called by an authenticated user."
      );
    }

    const callerUid = request.auth.uid;
    const actorEmail = request.auth.token.email || "";

    // 2. Fetch and verify caller role from Firestore
    const callerDoc = await admin.firestore().collection("users").doc(callerUid).get();
    if (!callerDoc.exists) {
      throw new HttpsError(
        "failed-precondition",
        "Caller profile does not exist in the database."
      );
    }

    const callerRole = callerDoc.data().role;
    if (callerRole !== "admin") {
      logger.warn(`Non-admin attempted profile modification. UID: ${callerUid}`);
      throw new HttpsError(
        "permission-denied",
        "Unauthorized: Only administrators are authorized to update users."
      );
    }

    // 3. Extract and validate parameters
    const { uid, name, role, status } = request.data || {};

    if (!uid || typeof uid !== "string" || uid.trim() === "") {
      throw new HttpsError("invalid-argument", "Target user UID is required.");
    }

    if (!name || typeof name !== "string" || name.trim() === "") {
      throw new HttpsError("invalid-argument", "Name parameter is required and must be non-empty.");
    }

    if (role !== "admin" && role !== "hr" && role !== "employee") {
      throw new HttpsError("invalid-argument", "Assigned role must be 'admin', 'hr', or 'employee'.");
    }

    if (status !== "active" && status !== "inactive") {
      throw new HttpsError("invalid-argument", "Status must be either 'active' or 'inactive'.");
    }

    // 4. Fetch the existing target user profile
    const targetDocRef = admin.firestore().collection("users").doc(uid);
    const targetDoc = await targetDocRef.get();
    if (!targetDoc.exists) {
      throw new HttpsError("not-found", "Target user profile not found.");
    }

    const oldData = targetDoc.data();
    const oldName = oldData.name || "";
    const oldRole = oldData.role || "";
    const oldStatus = oldData.status || "";

    const newName = name.trim();
    const newRole = role;
    const newStatus = status;

    // 5. Update user profile document (Admin SDK)
    await targetDocRef.update({
      name: newName,
      role: newRole,
      status: newStatus,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info(`Profile updated for target user UID: ${uid}`);

    // 6. Write audit logs for actual changes only
    const auditLogsCollection = admin.firestore().collection("audit_logs");
    const serverTimestamp = admin.firestore.FieldValue.serverTimestamp();

    if (oldName !== newName) {
      await auditLogsCollection.add({
        actorUid: callerUid,
        actorEmail: actorEmail,
        action: "USER_UPDATED",
        targetType: "user",
        targetId: uid,
        description: `Updated name for user ${newName} (previously '${oldName}').`,
        createdAt: serverTimestamp,
        metadata: { oldName, newName },
      });
    }

    if (oldRole !== newRole) {
      await auditLogsCollection.add({
        actorUid: callerUid,
        actorEmail: actorEmail,
        action: "ROLE_CHANGED",
        targetType: "user",
        targetId: uid,
        description: `Changed role of user ${newName} from '${oldRole}' to '${newRole}'.`,
        createdAt: serverTimestamp,
        metadata: { oldRole, newRole },
      });
    }

    if (oldStatus !== newStatus) {
      await auditLogsCollection.add({
        actorUid: callerUid,
        actorEmail: actorEmail,
        action: "STATUS_CHANGED",
        targetType: "user",
        targetId: uid,
        description: `Changed status of user ${newName} from '${oldStatus}' to '${newStatus}'.`,
        createdAt: serverTimestamp,
        metadata: { oldStatus, newStatus },
      });
    }

    return { success: true };

  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    logger.error("Unexpected server-side exception occurred in updateUser function:", error);
    throw new HttpsError("internal", "An unexpected internal server error occurred.");
  }
});
