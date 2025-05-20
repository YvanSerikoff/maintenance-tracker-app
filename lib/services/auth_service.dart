import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maintenance_app/services/flutter_basic_auth.dart';

class AuthService with ChangeNotifier {
  // L'instance du service API CMMS utilisant Basic Auth
  CMMSApiService? _apiService;
  CMMSApiService? get apiService => _apiService;

  // Informations utilisateur
  String? _userName;
  String? _userEmail;

  // Stockage sécurisé pour les données sensibles
  final _secureStorage = const FlutterSecureStorage();

  // Getters pour les infos utilisateur
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  // Statut d'authentification
  bool get isAuthenticated => _apiService != null;

  AuthService();

  get user async =>
    _apiService?.getUser();

  /// Connexion avec username et password via Basic Auth
  Future<bool> login({
    required String username,
    required String password,
    required String serverUrl,
    String? database, // ignoré pour Basic Auth
    bool rememberMe = false,
  }) async {
    try {
      // Créer une nouvelle instance du service API
      final apiService = CMMSApiService(
        baseUrl: serverUrl,
        username: username,
        password: password,
      );

      // Vérifier l'authentification en appelant une API protégée (dashboard)
      final dashboard = await apiService.getDashboard();
      if (dashboard != null && dashboard['success'] == true) {
        _apiService = apiService;

        // Récupérer les infos utilisateur si possible (exemple: username/email)
        _userName = username;
        _userEmail = null; // À adapter si l'API retourne l'email

        if (rememberMe) {
          await _saveCredentials(
            username: username,
            password: password,
            serverUrl: serverUrl,
            database: database ?? '',
          );
        }
        await _saveServerSettings(serverUrl, database ?? '');

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
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
      // Optionnel : effacer aussi les settings serveur
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.remove('server_url');
      // await prefs.remove('database');
    } catch (e) {
      print('Error clearing credentials: $e');
    }
  }
}
