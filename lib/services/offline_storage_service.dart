import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintenance_app/models/maintenance_task.dart';

class OfflineStorageService {
  static const String _tasksBoxName = 'maintenance_tasks';
  static const String _metadataBoxName = 'metadata';
  static const String _syncQueueBoxName = 'sync_queue';

  late Box<String> _tasksBox;
  late Box<String> _metadataBox;
  late Box<String> _syncQueueBox;

  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  Future<void> init() async {
    await Hive.initFlutter();
    _tasksBox = await Hive.openBox<String>(_tasksBoxName);
    _metadataBox = await Hive.openBox<String>(_metadataBoxName);
    _syncQueueBox = await Hive.openBox<String>(_syncQueueBoxName);
  }

  // Sauvegarder les tâches en local
  Future<void> saveTasks(List<MaintenanceTask> tasks) async {
    final Map<String, dynamic> tasksData = {
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'lastSync': DateTime.now().toIso8601String(),
    };

    await _tasksBox.put('current_tasks', jsonEncode(tasksData));
    await _metadataBox.put('last_sync_timestamp', DateTime.now().toIso8601String());
  }

  // Récupérer les tâches depuis le cache local
  Future<List<MaintenanceTask>> getCachedTasks() async {
    try {
      final tasksJson = _tasksBox.get('current_tasks');
      if (tasksJson == null) return [];

      final Map<String, dynamic> tasksData = jsonDecode(tasksJson);
      final List<dynamic> tasksList = tasksData['tasks'] ?? [];

      return tasksList.map((json) => MaintenanceTask.fromJson(json)).toList();
    } catch (e) {
      print('Error loading cached tasks: $e');
      return [];
    }
  }

  // Ajouter une action à la queue de synchronisation
  Future<void> addToSyncQueue(String action, Map<String, dynamic> data) async {
    final syncItem = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'action': action, // 'update_status', 'create_task', etc.
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'retryCount': 0,
    };

    await _syncQueueBox.put(syncItem['id']!, jsonEncode(syncItem));
  }

  // Récupérer les éléments en attente de synchronisation
  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    try {
      final List<Map<String, dynamic>> queue = [];

      for (String key in _syncQueueBox.keys) {
        final itemJson = _syncQueueBox.get(key);
        if (itemJson != null) {
          queue.add(jsonDecode(itemJson));
        }
      }

      // Trier par timestamp
      queue.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
      return queue;
    } catch (e) {
      print('Error loading sync queue: $e');
      return [];
    }
  }

  // Supprimer un élément de la queue après synchronisation réussie
  Future<void> removeFromSyncQueue(String id) async {
    await _syncQueueBox.delete(id);
  }

  // Vérifier si nous sommes en mode offline
  Future<bool> isOfflineMode() async {
    final lastSync = _metadataBox.get('last_sync_timestamp');
    if (lastSync == null) return true;

    final lastSyncTime = DateTime.parse(lastSync);
    final timeDifference = DateTime.now().difference(lastSyncTime);

    // Considérer offline si pas de sync depuis plus de 5 minutes
    return timeDifference.inMinutes > 5;
  }

  // Marquer une tâche comme modifiée localement
  Future<void> markTaskAsModified(int taskId, Map<String, dynamic> changes) async {
    final modifiedTasks = await getModifiedTasks();
    modifiedTasks[taskId.toString()] = {
      'changes': changes,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _metadataBox.put('modified_tasks', jsonEncode(modifiedTasks));
  }

  // Récupérer les tâches modifiées localement
  Future<Map<String, dynamic>> getModifiedTasks() async {
    try {
      final modifiedJson = _metadataBox.get('modified_tasks');
      if (modifiedJson == null) return {};
      return Map<String, dynamic>.from(jsonDecode(modifiedJson));
    } catch (e) {
      return {};
    }
  }

  // Nettoyer les tâches modifiées après synchronisation
  Future<void> clearModifiedTasks() async {
    await _metadataBox.delete('modified_tasks');
  }

  // ✨ NOUVELLE MÉTHODE : Sauvegarder une tâche complète
  Future<void> cacheCompleteTask(MaintenanceTask task) async {
    try {
      final taskData = {
        'task': task.toJson(),
        'cached_at': DateTime.now().toIso8601String(),
      };

      await _tasksBox.put('complete_task_${task.id}', jsonEncode(taskData));
    } catch (e) {
      print('Error caching complete task: $e');
    }
  }

  // ✨ NOUVELLE MÉTHODE : Récupérer une tâche complète depuis le cache
  Future<MaintenanceTask?> getCachedTaskById(int taskId) async {
    try {
      final taskJson = _tasksBox.get('complete_task_$taskId');
      if (taskJson == null) return null;

      final Map<String, dynamic> taskData = jsonDecode(taskJson);
      return MaintenanceTask.fromJson(taskData['task']);
    } catch (e) {
      print('Error loading cached task: $e');
      return null;
    }
  }

  // ✨ NOUVELLE MÉTHODE : Vérifier si les données d'une tâche sont en cache
  Future<bool> hasCompleteTaskData(int taskId) async {
    try {
      final taskJson = _tasksBox.get('complete_task_$taskId');
      return taskJson != null;
    } catch (e) {
      return false;
    }
  }

  // ✨ NOUVELLE MÉTHODE : Nettoyer les anciennes données en cache
  Future<void> cleanOldCachedTasks({Duration maxAge = const Duration(days: 7)}) async {
    try {
      final now = DateTime.now();
      final keysToDelete = <String>[];

      for (final key in _tasksBox.keys) {
        if (key.toString().startsWith('complete_task_')) {
          final taskJson = _tasksBox.get(key);
          if (taskJson != null) {
            final taskData = jsonDecode(taskJson);
            final cachedAt = DateTime.tryParse(taskData['cached_at']);

            if (cachedAt != null && now.difference(cachedAt) > maxAge) {
              keysToDelete.add(key.toString());
            }
          }
        }
      }

      for (final key in keysToDelete) {
        await _tasksBox.delete(key);
      }

      print('Cleaned ${keysToDelete.length} old cached tasks');
    } catch (e) {
      print('Error cleaning old cached tasks: $e');
    }
  }
}