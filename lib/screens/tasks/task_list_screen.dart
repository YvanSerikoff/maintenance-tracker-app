import 'package:flutter/material.dart';
import 'package:maintenance_app/screens/dashboard/dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:maintenance_app/services/auth_service.dart';
import 'package:maintenance_app/models/maintenance_task.dart';
import 'package:maintenance_app/screens/tasks/task_detail_screen.dart';
import 'package:maintenance_app/config/constants.dart';

import '../profile_screen.dart';

class TaskListScreen extends StatefulWidget {
  final int status;

  const TaskListScreen({super.key, this.status = 0});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  bool _isLoading = true;
  List<MaintenanceTask> _tasks = [];
  int _activeFilter = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.status;
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = authService.apiService;

      if (apiService == null) {
        throw Exception('Not authenticated');
      }

      final response = await apiService.getMaintenanceRequests(
        status: _activeFilter != 0
            ? _convertStatusToApi(_activeFilter.toString())
            : null,
      );

      if (response == null || response['success'] != true) {
        throw Exception('Failed to fetch tasks');
      }
      final List<dynamic> data = response['data']['requests'] ?? [];
      final tasks = data.map((json) => MaintenanceTask.fromJson(json)).toList();

      setState(() {
        _tasks = tasks.cast<MaintenanceTask>();
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading tasks: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fonction pour convertir les statuts de l'interface en valeurs d'ID pour l'API
  String? _convertStatusToApi(String status) {
    switch (status) {
      case 'pending':
        return '1'; // ID pour "Nouvelle demande"
      case 'in_progress':
        return '2'; // ID pour "En cours"
      case 'completed':
        return '3'; // ID pour "Réparé"
      case 'rebut':
        return '4'; // ID pour "Rebut"
      default:
        return null;
    }
  }

  void _setFilter(int filter) {
    setState(() {
      _activeFilter = filter;
    });
    _loadTasks();
  }

  void _searchTasks(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<MaintenanceTask> get _filteredTasks {
    List<MaintenanceTask> filtered = _tasks;
    if (_activeFilter != 0) {
      filtered = filtered.where((task) => task.status == _activeFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        return task.name.toLowerCase().contains(_searchQuery) ||
            task.description.toLowerCase().contains(_searchQuery) ||
            task.location.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search tasks',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: _searchTasks,
                  ),
                ),
                SizedBox(width: 8),
                PopupMenuButton<int>(
                  icon: Icon(Icons.filter_list),
                  onSelected: _setFilter,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 0,
                      child: Text('All Tasks'),
                    ),
                    PopupMenuItem(
                      value: 1,
                      child: Text('Pending'),
                    ),
                    PopupMenuItem(
                      value: 2,
                      child: Text('In Progress'),
                    ),
                    PopupMenuItem(
                      value: 3,
                      child: Text('Completed'),
                    ),
                    PopupMenuItem(
                      value: 4,
                      child: Text('Rebut'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Task List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredTasks.isEmpty
                ? Center(
              child: Text(
                'No tasks found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadTasks,
              child: ListView.builder(
                padding: EdgeInsets.all(8.0),
                itemCount: _filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = _filteredTasks[index];
                  return _buildTaskCard(context, task);
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DashboardScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfileScreen()),
            );
          }
        },
      ),
    );
  }

  String _getTitle() {
    switch (_activeFilter) {
      case 1:
        return 'Pending Tasks';
      case 2:
        return 'In Progress Tasks';
      case 3:
        return 'Completed Tasks';
      case 4:
        return 'Rebut Tasks';
      default:
        return 'All Tasks';
    }
  }

  Widget _buildTaskCard(BuildContext context, MaintenanceTask task) {
    Color statusColor;
    IconData statusIcon;
    switch (task.status) {
      case 1:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 2:
        statusColor = Colors.blue;
        statusIcon = Icons.engineering;
        break;
      case 3:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 4:
        statusColor = Colors.redAccent;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    // Couleur de priorité (urgence)
    Color priorityColor;
    switch (task.priority) {
      case 1:
        priorityColor = Colors.yellow;
        break;
      case 2:
        priorityColor = Colors.orange;
        break;
      case 3:
        priorityColor = Colors.red;
        break;
      default:
        priorityColor = Colors.green;
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withAlpha(50),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          task.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Location: ${task.location}'),
            SizedBox(height: 2),
            Text(
              'Scheduled: ${_formatDate(task.scheduledDate)}',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(
                _statusLabel(task.status),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              backgroundColor: statusColor,
              padding: EdgeInsets.all(0),
            ),
            SizedBox(width: 4),
            Chip(
              label: Text(
                'Urgence ${task.priority}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              backgroundColor: priorityColor,
              padding: EdgeInsets.all(0),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(task: task),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _statusLabel(int status) {
    switch (status) {
      case 1:
        return 'Pending';
      case 2:
        return 'In Progress';
      case 3:
        return 'Completed';
      case 4:
        return 'Rebut';
      default:
        return 'Unknown';
    }
  }


}