import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

const db = admin.firestore();

// ────────────────────────────────────────────────────────────────
// 1. Audit Logger — logs all document writes to the `logs` collection
// ────────────────────────────────────────────────────────────────
export const auditLogger = functions.firestore
  .document('{collection}/{docId}')
  .onWrite(async (change, context) => {
    const { collection, docId } = context.params;

    // Skip audit logs to avoid infinite loops
    if (collection === 'logs' || collection === 'audit_logs') return;

    const eventType = !change.before.exists
      ? 'CREATE'
      : !change.after.exists
      ? 'DELETE'
      : 'UPDATE';

    // Capture the diff for updates
    let changes: Record<string, { from: unknown; to: unknown }> = {};
    if (eventType === 'UPDATE') {
      const beforeData = change.before.data() ?? {};
      const afterData = change.after.data() ?? {};
      for (const key of Object.keys({ ...beforeData, ...afterData })) {
        if (beforeData[key] !== afterData[key]) {
          changes[key] = { from: beforeData[key], to: afterData[key] };
        }
      }
    }

    const logEntry: Record<string, unknown> = {
      collection,
      docId,
      eventType,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      userId: context.auth?.uid ?? 'system',
    };

    if (eventType !== 'DELETE') {
      logEntry.afterData = change.after.data();
    }
    if (Object.keys(changes).length > 0) {
      logEntry.changes = changes;
    }

    await db.collection('logs').add(logEntry);
  });

// ────────────────────────────────────────────────────────────────
// 2. Pit Guard — warns when pit fuel level drops below threshold
// ────────────────────────────────────────────────────────────────
export const pitGuard = functions.firestore
  .document('pit_refills/{refillId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const pitId = data.pitId as string;

    // Get the pit document to check current volume
    const pitDoc = await db.collection('pits').doc(pitId).get();
    if (!pitDoc.exists) return;

    const pitData = pitDoc.data();
    if (!pitData) return;

    const currentVolume = (pitData.currentVolume as number) ?? 0;
    const capacity = (pitData.capacity as number) ?? 1;
    const fillPercent = (currentVolume / capacity) * 100;

    if (fillPercent < 20) {
      await db.collection('notifications').add({
        type: 'LOW_FUEL_WARNING',
        pitId,
        pitName: pitData.name ?? 'Unknown Pit',
        currentVolume,
        capacity,
        fillPercent: Math.round(fillPercent * 100) / 100,
        message: `Pit "${pitData.name ?? 'Unknown'}" is at ${fillPercent.toFixed(1)}% capacity (${currentVolume}/${capacity} L)`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        acknowledged: false,
      });
    }
  });

// ────────────────────────────────────────────────────────────────
// 3. Scheduled Daily Summary — runs every day at 23:00
// ────────────────────────────────────────────────────────────────
export const dailySummary = functions.pubsub
  .schedule('0 23 * * *')
  .timeZone('Africa/Casablanca')
  .onRun(async (context) => {
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const todayEnd = new Date(todayStart.getTime() + 24 * 60 * 60 * 1000);

    const todayStartTs = admin.firestore.Timestamp.fromDate(todayStart);
    const todayEndTs = admin.firestore.Timestamp.fromDate(todayEnd);

    // Aggregate today's sales
    const salesQuery = await db.collection('sales')
      .where('isDeleted', '==', false)
      .where('timestamp', '>=', todayStartTs)
      .where('timestamp', '<', todayEndTs)
      .get();

    let totalRevenue = 0;
    let totalSales = 0;
    const fuelVolume = 0;
    const productCount = 0;

    for (const doc of salesQuery.docs) {
      const data = doc.data();
      totalRevenue += (data.totalAmount as number) ?? 0;
      totalSales++;
    }

    // Count active shifts
    const shiftsQuery = await db.collection('work_shifts')
      .where('status', '==', 'OPEN')
      .get();

    // Count pending payments
    const paymentsQuery = await db.collection('payments')
      .where('status', '==', 'PENDING')
      .get();

    // Write daily summary
    await db.collection('daily_summaries').add({
      date: todayStartTs,
      totalRevenue,
      totalSales,
      fuelVolume,
      productCount,
      averageSale: totalSales > 0 ? totalRevenue / totalSales : 0,
      openShifts: shiftsQuery.size,
      pendingPayments: paymentsQuery.size,
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    functions.logger.info(`Daily summary generated: ${totalRevenue} MAD from ${totalSales} sales`);
  });

// ────────────────────────────────────────────────────────────────
// 4. User Profile Cleanup — deletes user profile when auth account is removed
// ────────────────────────────────────────────────────────────────
export const onUserDelete = functions.auth
  .user()
  .onDelete(async (user) => {
    const uid = user.uid;

    // Delete user profile from Firestore
    try {
      await db.collection('users').doc(uid).update({
        isDeleted: true,
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (e) {
      functions.logger.warn(`Could not soft-delete user profile for ${uid}: ${e}`);
    }
  });
