/// Single source of truth for all app constants.
class K {
  K._();

  // ── App ───────────────────────────────────────────────────────────────
  static const appName     = 'Sarian Supplier';
  static const appVersion  = '2.0.0';

  // ── Firestore collections ──────────────────────────────────────────────
  static const users       = 'users';
  static const products    = 'products';
  static const categories  = 'categories';
  static const orders      = 'orders';
  static const cart        = 'cart';
  static const admins      = 'admins'; // sub-collection for admin FCM tokens

  // ── User roles ─────────────────────────────────────────────────────────
  static const roleAdmin   = 'admin';
  static const roleUser    = 'user';

  // ── Order statuses ─────────────────────────────────────────────────────
  static const sPending    = 'pending';
  static const sAccepted   = 'accepted';
  static const sProcessing = 'processing';
  static const sDispatched = 'dispatched';
  static const sDelivered  = 'delivered';
  static const sCancelled  = 'cancelled';

  static const activeStatuses   = [sPending, sAccepted, sProcessing];
  static const upcomingStatuses = [sDispatched];
  static const previousStatuses = [sDelivered, sCancelled];

  // ── Pagination ─────────────────────────────────────────────────────────
  static const pageSize    = 20;

  // ── SharedPrefs ────────────────────────────────────────────────────────
  static const prefTheme   = 'theme_mode';
  static const prefFcmToken = 'fcm_token';
}
