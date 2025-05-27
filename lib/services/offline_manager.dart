import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:maintenance_app/models/maintenance_task.dart';
import 'package:maintenance_app/services/offline_storage_service.dart';
import 'package:maintenance_app/services/auth_service.dart';
import 'package:flutter/foundation.dart';

import 'flutter_basic_auth.dart'; // Pour kIsWeb

class OfflineManager {
  static final OfflineManager _instance = OfflineManager._internal();
  factory OfflineManager() => _instance;
  OfflineManager._internal();

  final OfflineStorageService _storage = OfflineStorageService();
  StreamSubscription? _connectivitySubscription; // Complètement générique
  bool _isOnline = true;
  Timer? _syncTimer;

  // Ajout: protection contre sync concurrente
  bool _isSyncing = false;
  // Ajout: cooldown pour éviter les sync trop fréquentes
  DateTime? _lastSyncTime;
  static const Duration _syncCooldown = Duration(minutes: 1);

  // Ajout: debounce sur la connectivité
  Timer? _connectivityDebounceTimer;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  Function(bool)? onConnectivityChanged;
  Function()? onSyncCompleted;
  Function(String)? onSyncError;

  Future<void> init() async {
    await _storage.init();
    await _checkInitialConnectivity();
    _startConnectivityMonitoring();
    _startPeriodicSync();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      if (kIsWeb) {
        // Sur le web, utiliser une approche différente
        _handleWebConnectivity();
      } else {
        final connectivityResults = await Connectivity().checkConnectivity();
        final convertedResults = _convertToConnectivityResultList(connectivityResults);
        _updateConnectivityStatus(convertedResults);
      }
    } catch (e) {
      print('Error checking initial connectivity: $e');
      // Fallback: supposer qu'on est online sur le web
      _updateConnectivityStatus([ConnectivityResult.wifi]);
    }
  }

  void _startConnectivityMonitoring() {
    try {
      if (kIsWeb) {
        // Approche spécifique pour le web (Chrome inclus)
        _startWebConnectivityMonitoring();
      } else {
        // Approche mobile standard
        _startMobileConnectivityMonitoring();
      }
    } catch (e) {
      print('Error starting connectivity monitoring: $e');
      // Fallback: mode online par défaut
      _updateConnectivityStatus([ConnectivityResult.wifi]);
    }
  }

  // Méthode spécifique pour le web (évite les problèmes Chrome)
  void _startWebConnectivityMonitoring() {
    try {
      // Pour le web, on utilise une approche plus simple
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
            (dynamic results) {
          try {
            // Sur le web, traiter différemment
            bool isConnected = true;

            if (results != null) {
              if (results is List && results.isNotEmpty) {
                // Vérifier si au moins un élément n'est pas 'none'
                isConnected = results.any((item) =>
                item.toString() != 'ConnectivityResult.none' &&
                    item.toString() != 'none'
                );
              } else if (results.toString() == 'ConnectivityResult.none' ||
                  results.toString() == 'none') {
                isConnected = false;
              }
            }

            print('Web connectivity changed: $results -> isConnected: $isConnected');

            _updateConnectivityStatusSimple(isConnected);
          } catch (e) {
            print('Error processing web connectivity change: $e');
            // En cas d'erreur, supposer qu'on est online
            _updateConnectivityStatusSimple(true);
          }
        },
        onError: (error) {
          print('Web connectivity stream error: $error');
          // En cas d'erreur du stream, supposer qu'on est online
          _updateConnectivityStatusSimple(true);
        },
      );
    } catch (e) {
      print('Error starting web connectivity monitoring: $e');
    }
  }

  // Méthode pour mobile (approche standard)
  void _startMobileConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          (dynamic results) {
        try {
          final convertedResults = _convertToConnectivityResultList(results);
          _updateConnectivityStatus(convertedResults);
        } catch (e) {
          print('Error processing mobile connectivity change: $e');
          _updateConnectivityStatus([ConnectivityResult.none]);
        }
      },
      onError: (error) {
        print('Mobile connectivity stream error: $error');
        _updateConnectivityStatus([ConnectivityResult.none]);
      },
    );
  }

  // Méthode simplifiée pour le web
  void _updateConnectivityStatusSimple(bool isConnected) {
    _connectivityDebounceTimer?.cancel();
    _connectivityDebounceTimer = Timer(Duration(seconds: 2), () {
      try {
        final wasOffline = !_isOnline;
        _isOnline = isConnected;

        print('Web connectivity status updated: $_isOnline');

        if (wasOffline && _isOnline) {
          print('Web connection restored, triggering sync...');
          _syncWithServer();
        }

        onConnectivityChanged?.call(_isOnline);
      } catch (e) {
        print('Error updating web connectivity status: $e');
      }
    });
  }

  // Méthode spécifique pour détection web
  void _handleWebConnectivity() {
    try {
      // Sur le web, on peut aussi utiliser les API natives du navigateur
      if (kIsWeb) {
        // Essayer d'abord avec connectivity_plus de façon simple
        Connectivity().checkConnectivity().then((result) {
          bool isConnected = true;
          if (result.toString().contains('none')) {
            isConnected = false;
          }
          _updateConnectivityStatusSimple(isConnected);
        }).catchError((e) {
          print('Web connectivity check failed: $e');
          // Fallback: supposer qu'on est connecté
          _updateConnectivityStatusSimple(true);
        });
      }
    } catch (e) {
      print('Error handling web connectivity: $e');
      _updateConnectivityStatusSimple(true);
    }
  }

  // NOUVELLE MÉTHODE: Conversion sécurisée pour mobile uniquement
  List<ConnectivityResult> _convertToConnectivityResultList(dynamic results) {
    try {
      if (results is List<ConnectivityResult>) {
        return results;
      }

      if (results is ConnectivityResult) {
        return [results];
      }

      if (results is List) {
        return results.map((item) => _convertSingleResult(item)).toList();
      }

      if (results is String) {
        return [_convertStringToResult(results)];
      }

      print('Unknown connectivity result type: ${results.runtimeType}');
      return [ConnectivityResult.other];

    } catch (e) {
      print('Error converting connectivity results: $e');
      return [ConnectivityResult.other];
    }
  }

  ConnectivityResult _convertSingleResult(dynamic item) {
    if (item is ConnectivityResult) {
      return item;
    }
    if (item is String) {
      return _convertStringToResult(item);
    }
    return ConnectivityResult.other;
  }

  ConnectivityResult _convertStringToResult(String value) {
    switch (value.toLowerCase()) {
      case 'wifi':
        return ConnectivityResult.wifi;
      case 'mobile':
        return ConnectivityResult.mobile;
      case 'ethernet':
        return ConnectivityResult.ethernet;
      case 'none':
        return ConnectivityResult.none;
      case 'bluetooth':
        return ConnectivityResult.bluetooth;
      case 'vpn':
        return ConnectivityResult.vpn;
      case 'other':
        return ConnectivityResult.other;
      default:
        print('Unknown connectivity string: $value');
        return ConnectivityResult.other;
    }
  }

  // Debounce sur la connectivité (pour mobile)
  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    _connectivityDebounceTimer?.cancel();
    _connectivityDebounceTimer = Timer(Duration(seconds: 2), () {
      try {
        final wasOffline = !_isOnline;
        _isOnline = results.any((result) => result != ConnectivityResult.none);

        print('Mobile connectivity status updated: $_isOnline (results: $results)');

        if (wasOffline && _isOnline) {
          print('Mobile connection restored, triggering sync...');
          _syncWithServer();
        }

        onConnectivityChanged?.call(_isOnline);
      } catch (e) {
        print('Error updating mobile connectivity status: $e');
      }
    });
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(Duration(minutes: 5), (timer) async {
      if (_isOnline && !_isSyncing) {
        final pendingCount = await getPendingSyncCount();
        if (pendingCount > 0) {
          _syncWithServer();
        }
      }
    });
  }

  // Le reste des méthodes reste identique...
  Future<List<MaintenanceTask>> getTasks(AuthService authService, {String? status}) async {
    if (_isOnline && authService.apiService != null && !authService.isOfflineMode) {
      try {
        final response = await authService.apiService!.getMaintenanceRequests(
          status: status,
        ).timeout(Duration(seconds: 5));

        if (response != null && response['success'] == true) {
          final List<dynamic> data = response['data']['requests'] ?? [];
          final tasks = data.map((json) => MaintenanceTask.fromJson(json)).toList();
          await _storage.saveTasks(tasks);
          return tasks;
        }
      } catch (e) {
        print('Error fetching from API, falling back to cache: $e');
      }
    }

    final cachedTasks = await _storage.getCachedTasks();
    if (cachedTasks.isEmpty) {
      return await _createSampleTasks();
    }

    if (status != null) {
      final statusInt = _convertStatusToInt(status);
      return cachedTasks.where((task) => task.status == statusInt).toList();
    }
    return cachedTasks;
  }

  Future<List<MaintenanceTask>> _createSampleTasks() async {
    return [];
  }

  Future<void> _syncWithServer() async {
    if (!_isOnline || _isSyncing) return;
    if (_lastSyncTime != null && DateTime.now().difference(_lastSyncTime!) < _syncCooldown) {
      return;
    }
    _isSyncing = true;
    _lastSyncTime = DateTime.now();
    try {
      final syncQueue = await _storage.getSyncQueue();

      for (final item in syncQueue) {
        await _processSyncItem(item);
      }

      await _storage.clearModifiedTasks();
      onSyncCompleted?.call();
    } catch (e) {
      onSyncError?.call(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processSyncItem(Map<String, dynamic> item) async {
    try {
      final String action = item['action'];

      switch (action) {
        case 'update_status':
          await Future.delayed(Duration(milliseconds: 500));
          break;
        default:
          print('Unknown sync action: $action');
      }

      await _storage.removeFromSyncQueue(item['id']);
    } catch (e) {
      print('Failed to sync item ${item['id']}: $e');
    }
  }

  int _convertStatusToInt(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 1;
      case 'in_progress': return 2;
      case 'completed': return 3;
      case 'rebuttal': return 4;
      default: return 0;
    }
  }

  Future<bool> isOfflineMode() async {
    return await _storage.isOfflineMode();
  }

  Future<int> getPendingSyncCount() async {
    final queue = await _storage.getSyncQueue();
    return queue.length;
  }

  Future<void> forcSync() async {
    if (_isOnline) {
      await _syncWithServer();
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _connectivityDebounceTimer?.cancel();
  }

  Future<MaintenanceTask?> getCompleteTask(AuthService authService, int taskId) async {
    try {
      // 1. Essayer de récupérer depuis le cache local
      final cachedTask = await _storage.getCachedTaskById(taskId);
      if (isOffline || authService.isOfflineMode) {
        // Mode hors ligne : retourner les données en cache
        return cachedTask;
      }

      // 2. Mode en ligne : récupérer les données fraîches
      if (authService.apiService != null) {
        final completeTaskData = await _fetchCompleteTaskData(authService.apiService!, taskId);

        if (completeTaskData != null) {
          // Mettre à jour le cache avec les données complètes
          await _storage.cacheCompleteTask(completeTaskData);
          return completeTaskData;
        }
      }

      // 3. Fallback : données en cache
      return cachedTask;
    } catch (e) {
      print('Error getting complete task: $e');
      // En cas d'erreur, retourner les données en cache si disponibles
      return await _storage.getCachedTaskById(taskId);
    }
  }

  Future<MaintenanceTask?> _fetchCompleteTaskData(CMMSApiService apiService, int taskId) async {
    try {
      // Récupérer les données de base de la tâche
      final taskResponse = await apiService.getMaintenanceRequest(taskId);
      if (taskResponse == null || taskResponse['success'] != true) {
        return null;
      }

      // Le JSON complet est dans taskResponse['data']
      Map<String, dynamic> taskData = Map<String, dynamic>.from(taskResponse['data']);

      return MaintenanceTask.fromJson(taskData);
    } catch (e) {
      print('Error fetching complete task data: $e');
      return null;
    }
  }

  Future<void> preloadAllTaskData(AuthService authService) async {
    if (isOffline || authService.apiService == null) return;

    try {
      // Récupérer la liste des tâches
      final tasks = await getTasks(authService);

      // Pré-charger les données complètes pour chaque tâche
      for (final task in tasks) {
        await _fetchCompleteTaskData(authService.apiService!, task.id);

        // Petite pause pour éviter de surcharger l'API
        await Future.delayed(Duration(milliseconds: 100));
      }

      print('Preloaded complete data for ${tasks.length} tasks');
    } catch (e) {
      print('Error preloading task data: $e');
    }
  }

  addToSyncQueue(String s, Map<String, Object> map) {
    // Ajout d'une tâche à la file d'attente de synchronisation
    _storage.addToSyncQueue(s, map);
  }
}

