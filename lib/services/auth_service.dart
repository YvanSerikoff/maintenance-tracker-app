import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maintenance_app/services/flutter_basic_auth.dart';
import 'package:maintenance_app/services/offline_manager.dart';

import 'offline_storage_service.dart';

class AuthService with ChangeNotifier {
  // L'instance du service API CMMS utilisant Basic Auth
  CMMSApiService? _apiService;
  CMMSApiService? get apiService => _apiService;

  // Informations utilisateur
  String? _userName;
  String? _userEmail;
  bool _isOfflineMode = false;

  // Stockage sécurisé pour les données sensibles
  final _secureStorage = const FlutterSecureStorage();
  final OfflineManager _offlineManager = OfflineManager();

  // Getters pour les infos utilisateur
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  bool get isOfflineMode => _isOfflineMode;

  // Statut d'authentification
  bool get isAuthenticated => _apiService != null || _isOfflineMode;

  AuthService();

  get user async => _apiService?.getUser();

  /// Connexion avec username et password via Basic Auth (avec support offline)
  Future<bool> login({
    required String username,
    required String password,
    required String serverUrl,
    String? database,
    bool rememberMe = false,
    bool forceOffline = false,
  }) async {
    // Si mode offline forcé ou pas de connexion
    if (forceOffline || !_offlineManager.isOnline) {
      return await _loginOffline(username, password, serverUrl, database);
    }

    try {
      // Tentative de connexion online
      final apiService = CMMSApiService(
        baseUrl: serverUrl,
        username: username,
        password: password,
      );

      final dashboard = await apiService.getDashboard();
      final user = await apiService.getUser();
      if (dashboard != null && dashboard['success'] == true) {
        _apiService = apiService;
        _userName = username;
        _userEmail = user?['data']['user']['email'] ?? '';
        print('Login successful: $_userEmail');
        _isOfflineMode = false;

        if (rememberMe) {
          await _saveCredentials(
            username: username,
            password: password,
            serverUrl: serverUrl,
            database: database ?? '',
          );
        }
        await _saveServerSettings(serverUrl, database ?? '');
        await _saveLastSuccessfulLogin(username, password, serverUrl, database);

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Online login failed, trying offline: $e');
      // Si la connexion online échoue, essayer offline
      return await _loginOffline(username, password, serverUrl, database);
    }
  }

  /// Connexion en mode offline avec validation des dernières credentials
  Future<bool> _loginOffline(String username, String password, String serverUrl, String? database) async {
    try {
      // Vérifier si on a des credentials stockées
      final savedUsername = await _secureStorage.read(key: 'last_username');
      final savedPassword = await _secureStorage.read(key: 'last_password');
      final savedServerUrl = await _secureStorage.read(key: 'last_server_url');

      // Valider que les credentials correspondent aux dernières utilisées avec succès
      if (savedUsername == username &&
          savedPassword == password &&
          savedServerUrl == serverUrl) {

        // Créer un service API "offline" (sans vraiment se connecter)
        _apiService = CMMSApiService(
          baseUrl: serverUrl,
          username: username,
          password: password,
        );

        // Dans _loginOffline (après ligne 108)
        _userName = username;
        _userEmail = null;
        _isOfflineMode = true;

        // Vérifier si des données sont disponibles en cache
        final offlineStorage = OfflineStorageService();
        final cachedTasks = await offlineStorage.getCachedTasks();
        if (cachedTasks.isEmpty) {
          print('Aucune donnée en cache - première connexion offline');
          // Optionnel : créer des données d'exemple
        }

        notifyListeners();
        return true;
      } else {
        throw Exception('Invalid offline credentials. Please connect online first.');
      }
    } catch (e) {
      print('Offline login failed: $e');
      return false;
    }
  }

  /// Sauvegarder les dernières credentials utilisées avec succès
  Future<void> _saveLastSuccessfulLogin(String username, String password, String serverUrl, String? database) async {
    try {
      await _secureStorage.write(key: 'last_username', value: username);
      await _secureStorage.write(key: 'last_password', value: password);
      await _secureStorage.write(key: 'last_server_url', value: serverUrl);
      if (database != null) {
        await _secureStorage.write(key: 'last_database', value: database);
      }
    } catch (e) {
      print('Error saving last successful login: $e');
    }
  }

  /// Connexion automatique avec les identifiants stockés
  Future<bool> tryAutoLogin() async {
    try {
      final hasCredentials = await _secureStorage.containsKey(key: 'username');
      if (!hasCredentials) return false;

      final username = await _secureStorage.read(key: 'username');
      final password = await _secureStorage.read(key: 'password');
      final prefs = await SharedPreferences.getInstance();
      final serverUrl = prefs.getString('server_url') ?? '';
      final database = prefs.getString('database') ?? '';

      if (username == null || password == null || serverUrl.isEmpty) {
        return false;
      }

      return await login(
        username: username,
        password: password,
        serverUrl: serverUrl,
        database: database,
        rememberMe: true,
      );
    } catch (e) {
      return false;
    }
  }

  /// Vérifier si une connexion offline est possible
  Future<bool> canLoginOffline() async {
    try {
      final savedUsername = await _secureStorage.read(key: 'last_username');
      final savedPassword = await _secureStorage.read(key: 'last_password');
      final savedServerUrl = await _secureStorage.read(key: 'last_server_url');

      return savedUsername != null && savedPassword != null && savedServerUrl != null;
    } catch (e) {
      return false;
    }
  }

  /// Sauvegarder les identifiants de connexion
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

  /// Sauvegarder les paramètres serveur
  Future<void> _saveServerSettings(String serverUrl, String database) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_url', serverUrl);
      await prefs.setString('database', database);
    } catch (e) {
      print('Error saving server settings: $e');
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      _apiService = null;
      _userName = null;
      _userEmail = null;
      _isOfflineMode = false;
      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  /// Effacer les identifiants stockés
  Future<void> clearStoredCredentials() async {
    try {
      await _secureStorage.delete(key: 'username');
      await _secureStorage.delete(key: 'password');
      await _secureStorage.delete(key: 'last_username');
      await _secureStorage.delete(key: 'last_password');
      await _secureStorage.delete(key: 'last_server_url');
      await _secureStorage.delete(key: 'last_database');
    } catch (e) {
      print('Error clearing credentials: $e');
    }
  }
}