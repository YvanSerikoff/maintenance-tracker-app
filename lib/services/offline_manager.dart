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
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription; // Correction ici
  bool _isOnline = true;
  Timer? _syncTimer;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  // Callbacks pour notifier l'UI des changements
  Function(bool)? onConnectivityChanged;
  Function()? onSyncCompleted;
  Function(String)? onSyncError;

  Future<void> init() async {
    await _storage.init();
    await _checkInitialConnectivity(); // Vérifier la connectivité initiale
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

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final wasOffline = !_isOnline;

    // Considérer comme online si au moins une connexion est disponible
    _isOnline = results.any((result) => result != ConnectivityResult.none);

    if (wasOffline && _isOnline) {
      // Connexion restaurée, lancer la synchronisation
      _syncWithServer();
    }

    onConnectivityChanged?.call(_isOnline);
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(Duration(minutes: 2), (timer) {
      if (_isOnline) {
        _syncWithServer();
      }
    });
  }

  // Récupérer les tâches (avec fallback offline)
  Future<List<MaintenanceTask>> getTasks(AuthService authService, {String? status}) async {
    // Vérifier si on est vraiment en mode online ET pas en mode offline forcé
    if (_isOnline && authService.apiService != null && !authService.isOfflineMode) {
      try {
        // Essayer de récupérer depuis l'API avec timeout
        final response = await authService.apiService!.getMaintenanceRequests(
          status: status,
        ).timeout(Duration(seconds: 5)); // Ajouter timeout

        if (response != null && response['success'] == true) {
          final List<dynamic> data = response['data']['requests'] ?? [];
          final tasks = data.map((json) => MaintenanceTask.fromJson(json)).toList();

          // Sauvegarder en cache
          await _storage.saveTasks(tasks);
          return tasks;
        }
      } catch (e) {
        print('Error fetching from API, falling back to cache: $e');
      }
    }

    // Fallback vers le cache local (mode offline ou échec API)
    final cachedTasks = await _storage.getCachedTasks();

    // Si pas de cache et première utilisation, retourner données mock/exemple
    if (cachedTasks.isEmpty) {
      return await _createSampleTasks();
    }

    // Filtrer par statut si nécessaire
    if (status != null) {
      final statusInt = _convertStatusToInt(status);
      return cachedTasks.where((task) => task.status == statusInt).toList();
    }

    return cachedTasks;
  }

  // Ajouter cette méthode dans OfflineManager
  Future<List<MaintenanceTask>> _createSampleTasks() async {
    final sampleTasks = [
      MaintenanceTask(
        id: 1,
        name: "Maintenance préventive - Pompe A",
        description: "Vérification et maintenance de la pompe principale",
        scheduledDate: DateTime.now().add(Duration(days: 1)),
        status: 1, // Pending
        priority: 2, // Medium
        technicianId: 1,
        equipmentId: 101,
        location: "Salle des machines",
        attachments: [],
        createdAt: DateTime.now().subtract(Duration(days: 2)),
        lastUpdated: DateTime.now(),
      ),
      MaintenanceTask(
        id: 2,
        name: "Réparation - Compresseur B",
        description: "Réparation du compresseur suite à panne",
        scheduledDate: DateTime.now(),
        status: 2, // In Progress
        priority: 3, // High
        technicianId: 2,
        equipmentId: 102,
        location: "Atelier principal",
        attachments: [],
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        lastUpdated: DateTime.now(),
      ),
      // Ajouter d'autres tâches d'exemple...
    ];

    // Sauvegarder ces tâches en cache pour la prochaine fois
    await _storage.saveTasks(sampleTasks);
    return sampleTasks;
  }

  // Mettre à jour le statut d'une tâche (avec gestion offline)
  Future<bool> updateTaskStatus(int taskId, int newStatus, AuthService authService) async {
    if (_isOnline && authService.apiService != null) {
      try {
        final response = await authService.apiService!.updateMaintenanceRequest(
          taskId,
          {'stage_id': newStatus},
        );

        if (response != null && response['success'] == true) {
          // Mettre à jour le cache local
          await _updateTaskInCache(taskId, {'status': newStatus});
          return true;
        }
      } catch (e) {
        print('Error updating task online, saving for later sync: $e');
      }
    }

    // Mode offline : sauvegarder pour synchronisation ultérieure
    await _storage.addToSyncQueue('update_status', {
      'taskId': taskId,
      'status': newStatus,
    });

    await _storage.markTaskAsModified(taskId, {'status': newStatus});
    await _updateTaskInCache(taskId, {'status': newStatus});

    return true; // Retourner true car l'action sera synchronisée plus tard
  }

  Future<void> _updateTaskInCache(int taskId, Map<String, dynamic> updates) async {
    final tasks = await _storage.getCachedTasks();
    final taskIndex = tasks.indexWhere((task) => task.id == taskId);

    if (taskIndex != -1) {
      // Créer une nouvelle tâche avec les modifications
      final task = tasks[taskIndex];
      final updatedTask = MaintenanceTask(
        id: task.id,
        name: task.name,
        description: task.description,
        scheduledDate: task.scheduledDate,
        status: updates['status'] ?? task.status,
        priority: task.priority,
        technicianId: task.technicianId,
        equipmentId: task.equipmentId,
        location: task.location,
        attachments: task.attachments,
        createdAt: task.createdAt,
        lastUpdated: DateTime.now(),
      );

      tasks[taskIndex] = updatedTask;
      await _storage.saveTasks(tasks);
    }
  }

  // Synchronisation avec le serveur
  Future<void> _syncWithServer() async {
    if (!_isOnline) return;

    try {
      final syncQueue = await _storage.getSyncQueue();

      for (final item in syncQueue) {
        await _processSyncItem(item);
      }

      await _storage.clearModifiedTasks();
      onSyncCompleted?.call();
    } catch (e) {
      onSyncError?.call(e.toString());
    }
  }

  Future<void> _processSyncItem(Map<String, dynamic> item) async {
    try {
      final String action = item['action'];
      final Map<String, dynamic> data = item['data'];

      switch (action) {
        case 'update_status':
        // Ici vous pouvez implémenter la logique de synchronisation spécifique
        // Pour l'instant, on simule une synchronisation réussie
          await Future.delayed(Duration(milliseconds: 500));
          break;

      // Ajouter d'autres types d'actions si nécessaire
        default:
          print('Unknown sync action: $action');
      }

      // Si réussi, supprimer de la queue
      await _storage.removeFromSyncQueue(item['id']);
    } catch (e) {
      // En cas d'échec, on pourrait incrémenter retryCount
      print('Failed to sync item ${item['id']}: $e');
    }
  }

  int _convertStatusToInt(String status) {
    // Convertir le statut string en int selon votre logique
    switch (status.toLowerCase()) {
      case 'pending': return 1;
      case 'in_progress': return 2;
      case 'completed': return 3;
      case 'rebuttal': return 4;
      default: return 0;
    }
  }

  // Méthodes utilitaires pour l'UI
  Future<bool> isOfflineMode() async {
    return await _storage.isOfflineMode();
  }

  Future<int> getPendingSyncCount() async {
    final queue = await _storage.getSyncQueue();
    return queue.length;
  }

  // Forcer une synchronisation manuelle
  Future<void> forcSync() async {
    if (_isOnline) {
      await _syncWithServer();
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
  }
}