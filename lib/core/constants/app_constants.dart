class AppConstants {
  AppConstants._();

  static const String appName = 'Sarian Supplier';
  static const String companyName = 'Sarian Healthcare';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';
  static const String suppliersCollection = 'suppliers';
  static const String categoriesCollection = 'categories';

  // Shared Prefs keys
  static const String prefUserId = 'user_id';
  static const String prefUserRole = 'user_role';
  static const String prefOnboarded = 'onboarded';

  // User roles
  static const String roleAdmin = 'admin';
  static const String roleSupplier = 'supplier';
  static const String roleSalesRep = 'sales_rep';

  // Order statuses
  static const String statusPending = 'pending';
  static const String statusConfirmed = 'confirmed';
  static const String statusShipped = 'shipped';
  static const String statusDelivered = 'delivered';
  static const String statusCancelled = 'cancelled';

  // Pagination
  static const int pageSize = 20;
}
