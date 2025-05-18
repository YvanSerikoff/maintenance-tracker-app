import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maintenance_app/services/odoo_service.dart';

class AuthService with ChangeNotifier {
  // The Odoo service instance
  OdooService? _odooService;
  OdooService? get odooService => _odooService;
  
  // User information
  int? _userId;
  String? _userName;
  String? _userEmail;
  
  // Secure storage for sensitive data
  final _secureStorage = const FlutterSecureStorage();
  
  // Getters for user information
  int? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  
  // Authentication status
  bool get isAuthenticated => _odooService != null && _odooService!.sessionId != null;
  
  // Constructor
  AuthService() {
    // Initialize if needed
  }
  
  /// Login with username and password
  Future<bool> login({
    required String username,
    required String password,
    required String serverUrl,
    required String database,
    bool rememberMe = false,
  }) async {
    try {
      // Create a new Odoo service instance
      final odooService = OdooService(
        baseUrl: serverUrl,
        database: database,
      );
      
      // Attempt authentication
      final success = await odooService.authenticate(username, password);
      
      if (success) {
        // Store the Odoo service
        _odooService = odooService;
        
        // Get and store user information
        await _fetchUserInfo();
        
        // Save credentials if remember me is enabled
        if (rememberMe) {
          await _saveCredentials(
            username: username,
            password: password,
            serverUrl: serverUrl,
            database: database,
          );
        }
        
        // Save the server and database regardless
        await _saveServerSettings(serverUrl, database);
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }
  
  /// Try to automatically log in using stored credentials
  Future<bool> tryAutoLogin() async {
    try {
      // Check if we have stored credentials
      final hasCredentials = await _secureStorage.containsKey(key: 'username');
      
      if (!hasCredentials) {
        return false;
      }
      
      // Get the credentials and server settings
      final username = await _secureStorage.read(key: 'username');
      final password = await _secureStorage.read(key: 'password');
      final prefs = await SharedPreferences.getInstance();
      final serverUrl = prefs.getString('server_url') ?? '';
      final database = prefs.getString('database') ?? '';
      
      if (username == null || password == null || serverUrl.isEmpty || database.isEmpty) {
        return false;
      }
      
      // Attempt login with stored credentials
      return await login(
        username: username,
        password: password,
        serverUrl: serverUrl,
        database: database,
        rememberMe: true,
      );
    } catch (e) {
      print('Auto-login error: $e');
      return false;
    }
  }
  
  /// Fetch user information after successful login
  Future<void> _fetchUserInfo() async {
    if (_odooService == null || _odooService!.uid == null) {
      return;
    }
    
    try {
      // Call the user info endpoint
      final response = await _odooService!.callKw(
        model: 'res.users',
        method: 'read',
        args: [
          [_odooService!.uid],
          ['name', 'email', 'login']
        ],
      );
      
      if (response is List && response.isNotEmpty) {
        final userInfo = response[0];
        _userId = _odooService!.uid;
        _userName = userInfo['name'];
        _userEmail = userInfo['email'] ?? '';
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
  }
  
  /// Save credentials securely for auto-login
  Future<void> _saveCredentials({
    required String username,
    required String password,
    required String serverUrl,
    required String database,
  }) async {
    try {
      await _secureStorage.write(key: 'username', value: username);
      await _secureStorage.write(key: 'password', value: password);
      await _saveServerSettings(serverUrl, database);
    } catch (e) {
      print('Error saving credentials: $e');
    }
  }
  
  /// Save non-sensitive server settings
  Future<void> _saveServerSettings(String serverUrl, String database) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_url', serverUrl);
      await prefs.setString('database', database);
    } catch (e) {
      print('Error saving server settings: $e');
    }
  }
  
  /// Clear credentials and log out
  Future<void> logout() async {
    try {
      // Clear the Odoo session if possible
      if (_odooService != null && _odooService!.sessionId != null) {
        try {
          await _odooService!.logout();
        } catch (e) {
          print('Error logging out from Odoo: $e');
        }
      }
      
      // Reset the service and user information
      _odooService = null;
      _userId = null;
      _userName = null;
      _userEmail = null;
      
      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
    }
  }
  
  /// Clear stored credentials (for "forget me" functionality)
  Future<void> clearStoredCredentials() async {
    try {
      await _secureStorage.delete(key: 'username');
      await _secureStorage.delete(key: 'password');
      
      // Optionally, you can also clear server settings
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.remove('server_url');
      // await prefs.remove('database');
    } catch (e) {
      print('Error clearing credentials: $e');
    }
  }
}