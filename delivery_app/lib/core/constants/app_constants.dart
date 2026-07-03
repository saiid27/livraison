class AppConstants {
  static const String appName = 'mayahsar';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://livraison-o0ns.onrender.com/api',
  );
  static const String tokenKey = 'auth_token';
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';
  static const String approvalStatusKey = 'approval_status';
  static const String supportPhone = '43760128';
  static const String supportWhatsAppPhone = '22243760128';

  static const String roleClient = 'client';
  static const String roleLivreur = 'livreur';
  static const String roleCarCaptain = 'car_captain';
  static const String roleMerchant = 'merchant';
  static const String roleAdmin = 'admin';
}
