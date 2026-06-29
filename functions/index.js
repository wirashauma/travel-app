const functions = require('firebase-functions');
const admin = require('firebase-admin');
const fetch = require('node-fetch');

admin.initializeApp();

// ─────────────────────────────────────────────────────
//  ENVIRONMENT VARIABLES (set via Firebase CLI)
//
//  firebase functions:config:set \
//    midtrans.server_key="SB-Mid-server-xxxxx" \
//    midtrans.client_key="SB-Mid-client-xxxxx" \
//    midtrans.is_production="false"
// ─────────────────────────────────────────────────────

const MIDTRANS_BASE_URL = functions.config().midtrans?.is_production === 'true'
  ? 'https://app.midtrans.com/snap/v1'
  : 'https://app.sandbox.midtrans.com/snap/v1';

/**
 * Generate Midtrans Snap token — dipanggil dari Flutter.
 *
 * Request body:
 * {
 *   "orderId": "booking_firestore_id",
 *   "grossAmount": 150000,
 *   "customerName": "John Doe",
 *   "customerEmail": "john@email.com",
 *   "customerPhone": "08123456789",
 *   "itemName": "Padang → Bukittinggi",
 *   "itemQuantity": 2
 * }
 */
exports.generateSnapToken = functions.https.onCall(async (data, context) => {
  // ── Validasi: user harus terautentikasi ──
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Harus login terlebih dahulu'
    );
  }

  const serverKey = functions.config().midtrans?.server_key;
  const clientKey = functions.config().midtrans?.client_key;

  if (!serverKey || !clientKey) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Midtrans server key / client key belum dikonfigurasi. ' +
      'Jalankan: firebase functions:config:set midtrans.server_key="..." midtrans.client_key="..."'
    );
  }

  const {
    orderId,
    grossAmount,
    customerName,
    customerEmail,
    customerPhone,
    itemName,
    itemQuantity,
  } = data;

  // ── Validasi field wajib ──
  if (!orderId || !grossAmount) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'orderId dan grossAmount wajib diisi'
    );
  }

  const auth = Buffer.from(`${serverKey}:`).toString('base64');

  const payload = {
    transaction_details: {
      order_id: orderId,
      gross_amount: grossAmount,
    },
    customer_details: {
      first_name: customerName || 'Penumpang',
      email: customerEmail || '',
      phone: customerPhone || '',
    },
    item_details: [
      {
        id: orderId,
        price: grossAmount,
        quantity: itemQuantity || 1,
        name: itemName || 'Tiket Travel',
        category: 'Transportasi',
      },
    ],
    callbacks: {
      finish: 'https://etravel.app/payment-finish',
      unfinish: 'https://etravel.app/payment-unfinish',
      error: 'https://etravel.app/payment-error',
    },
    enabled_payments: [
      'bca_va',
      'bni_va',
      'bri_va',
      'mandiri_va',
      'gopay',
      'shopeepay',
      'qris',
    ],
  };

  functions.logger.info('Generating Midtrans Snap token', { orderId, grossAmount });

  try {
    const response = await fetch(`${MIDTRANS_BASE_URL}/transactions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': `Basic ${auth}`,
      },
      body: JSON.stringify(payload),
    });

    const result = await response.json();

    if (!response.ok) {
      functions.logger.error('Midtrans API error', {
        status: response.status,
        body: result,
      });
      throw new functions.https.HttpsError(
        'internal',
        `Midtrans API error: ${result.status_message || response.status}`
      );
    }

    functions.logger.info('Snap token generated', { token: result.token });

    return {
      token: result.token,
      redirectUrl: result.redirect_url,
    };
  } catch (error) {
    functions.logger.error('Failed to generate Snap token', error);
    throw new functions.https.HttpsError(
      'internal',
      `Gagal generate token: ${error.message}`
    );
  }
});

/**
 * Webhook endpoint — dipanggil Midtrans setelah pembayaran selesai.
 *
 * Midtrans → HTTP POST → Cloud Function → update Firestore booking status.
 *
 * Setup di dashboard Midtrans:
 *   Payment Notification URL → https://{region}-{project}.cloudfunctions.net/midtransWebhook
 */
exports.midtransWebhook = functions.https.onRequest(async (req, res) => {
  // Hanya terima POST
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  const notification = req.body;
  const orderId = notification.order_id;
  const transactionStatus = notification.transaction_status;
  const fraudStatus = notification.fraud_status;

  functions.logger.info('Midtrans webhook received', {
    orderId,
    transactionStatus,
    fraudStatus,
  });

  if (!orderId) {
    res.status(400).json({ error: 'Missing order_id' });
    return;
  }

  try {
    const bookingRef = admin.firestore().collection('bookings').doc(orderId);
    const bookingSnap = await bookingRef.get();

    if (!bookingSnap.exists) {
      functions.logger.warn('Booking not found', { orderId });
      res.status(404).json({ error: 'Booking not found' });
      return;
    }

    // Mapping status Midtrans → booking status
    let newStatus = null;

    if (transactionStatus === 'capture' || transactionStatus === 'settlement') {
      // capture (credit card), settlement (VA/EWallet/QRIS)
      if (fraudStatus === 'accept' || !fraudStatus) {
        newStatus = 'paid';
      }
    } else if (transactionStatus === 'pending') {
      newStatus = 'pending';
    } else if (
      transactionStatus === 'deny' ||
      transactionStatus === 'cancel' ||
      transactionStatus === 'expire'
    ) {
      newStatus = 'cancelled';
    }

    if (newStatus) {
      await admin.firestore().runTransaction(async (t) => {
        const bSnap = await t.get(bookingRef);
        if (!bSnap.exists) return;
        const bData = bSnap.data();
        const currentStatus = bData.status || '';

        const bookingUpdates = {
          status: newStatus,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        if (newStatus === 'paid') {
          bookingUpdates.paidAt = admin.firestore.FieldValue.serverTimestamp();
        }

        const fleetId = bData.fleetId || '';
        const departureDate = bData.departureDate || '';
        const departureTime = bData.departureTime || '';
        const seatLabels = bData.selectedSeatLabels || [];
        const seatsBooked = bData.seatsBooked || seatLabels.length;
        const totalPrice = bData.totalPrice || 0;

        let lockRef = null;
        let lockSnap = null;
        if (fleetId && departureDate && departureTime) {
          const datePart = departureDate.replace(/ /g, '_');
          const timePart = departureTime.replace(/ /g, '_');
          const lockDocId = `${fleetId}_${datePart}_${timePart}`;
          lockRef = admin.firestore().collection('seat_locks').doc(lockDocId);
          lockSnap = await t.get(lockRef);
        }

        let fleetRef = null;
        let fleetSnap = null;
        if (fleetId) {
          fleetRef = admin.firestore().collection('fleets').doc(fleetId);
          fleetSnap = await t.get(fleetRef);
        }

        if (newStatus === 'paid' && currentStatus === 'pending') {
          if (lockSnap && lockSnap.exists && lockRef) {
            const seats = lockSnap.data().seats || {};
            const updatedSeats = { ...seats };
            let changed = false;
            for (const seat of seatLabels) {
              if (updatedSeats[seat] && updatedSeats[seat].bookingId === orderId) {
                updatedSeats[seat] = {
                  bookingId: orderId,
                  status: 'paid',
                };
                changed = true;
              }
            }
            if (changed) {
              t.update(lockRef, { seats: updatedSeats });
            }
          }
        } else if (newStatus === 'cancelled' && (currentStatus === 'pending' || currentStatus === 'paid')) {
          let updatedSeats = null;
          if (lockSnap && lockSnap.exists && lockRef) {
            const seats = lockSnap.data().seats || {};
            updatedSeats = { ...seats };
            let changed = false;
            for (const seat of seatLabels) {
              if (updatedSeats[seat] && updatedSeats[seat].bookingId === orderId) {
                delete updatedSeats[seat];
                changed = true;
              }
            }
            if (changed) {
              t.update(lockRef, { seats: updatedSeats });
            }
          }

          if (fleetSnap && fleetSnap.exists && fleetRef) {
            const fleetData = fleetSnap.data();
            const totalSeats = fleetData.totalSeats || 0;
            const remainingSeats = updatedSeats || {};
            let activeLocks = 0;
            for (const seatKey in remainingSeats) {
              const entry = remainingSeats[seatKey];
              const st = entry.status || '';
              if (['paid', 'used', 'validated', 'completed', 'pending'].includes(st)) {
                activeLocks++;
              }
            }
            const newAvailableSeats = Math.max(0, Math.min(totalSeats, totalSeats - activeLocks));
            t.update(fleetRef, {
              availableSeats: newAvailableSeats,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }

          if (currentStatus === 'paid') {
            bookingUpdates.refundAmount = 0;
            bookingUpdates.refundPenalty = totalPrice;
            bookingUpdates.refundStatus = 'forfeited';
            bookingUpdates.refundProcessedAt = admin.firestore.FieldValue.serverTimestamp();
          }
        }

        t.update(bookingRef, bookingUpdates);
      });
      functions.logger.info('Booking status updated via transaction', { orderId, newStatus });
    }

    res.status(200).json({ ok: true });
  } catch (error) {
    functions.logger.error('Webhook processing error', error);
    res.status(500).json({ error: error.message });
  }
});
