class AppConstants {
  // Server defaults
  static const String DEFAULT_SERVER_URL = 'http://192.168.1.71:8069';
  static const String DEFAULT_DATABASE = 'odoo_cmms';
  
  // API endpoints
  static const String API_AUTHENTICATE = '/api/flutter/user/login';
  static const String API_DESTROY_SESSION = '/web/session/destroy';
  static const String API_CALL_KW = '/web/dataset/call_kw';
  
  // Secure storage keys
  static const String KEY_USERNAME = 'username';
  static const String KEY_PASSWORD = 'password';
  
  // Shared preferences keys
  static const String KEY_SERVER_URL = 'server_url';
  static const String KEY_DATABASE = 'database';
  static const String KEY_REMEMBER_ME = 'remember_me';
  static const String KEY_DARK_MODE = 'dark_mode';

  // Maintenance status codes
  static const String STATUS_PENDING = 'pending';
  static const String STATUS_IN_PROGRESS = 'in_progress';
  static const String STATUS_COMPLETED = 'completed';
  static const String STATUS_CANCELLED = 'cancelled';

  static const Map<String, int> statusToStageId = {
    'pending': 1,
    'in_progress': 2,
    'completed': 3,
    'rebut': 4,
  };
}