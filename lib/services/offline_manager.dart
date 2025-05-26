import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:maintenance_app/models/maintenance_task.dart';
import 'package:maintenance_app/services/offline_storage_service.dart';
import 'package:maintenance_app/services/auth_service.dart';

class OfflineManager {
  static final OfflineManager _instance = OfflineManager._internal();
  factory OfflineManager() => _instance;
  OfflineManager._internal();

  final OfflineStorageService _storage = OfflineStorageService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
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
    final connectivityResults = await Connectivity().checkConnectivity();
    _updateConnectivityStatus(connectivityResults);
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectivityStatus(results);
    });
  }

  // Debounce sur la connectivité
  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    _connectivityDebounceTimer?.cancel();
    _connectivityDebounceTimer = Timer(Duration(seconds: 2), () {
      final wasOffline = !_isOnline;
      _isOnline = results.any((result) => result != ConnectivityResult.none);

      if (wasOffline && _isOnline) {
        _syncWithServer();
      }

      onConnectivityChanged?.call(_isOnline);
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

  // Example: Récupérer les tâches (avec fallback offline)
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
    // (code exemple inchangé)
    // ...
    return [];
  }

  // Synchronisation avec protection contre appels concurrents et cooldown
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
      final Map<String, dynamic> data = item['data'];

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
}