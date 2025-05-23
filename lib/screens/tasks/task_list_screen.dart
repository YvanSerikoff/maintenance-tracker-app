import 'package:flutter/material.dart';
import 'package:maintenance_app/screens/dashboard/dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:maintenance_app/services/auth_service.dart';
import 'package:maintenance_app/services/offline_manager.dart';
import 'package:maintenance_app/models/maintenance_task.dart';
import 'package:maintenance_app/screens/tasks/task_detail_screen.dart';
import 'package:maintenance_app/config/constants.dart';
import 'package:maintenance_app/widgets/offline_indicator.dart';

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
  final OfflineManager _offlineManager = OfflineManager();

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.status;
    _initializeOfflineManager();
    _loadTasks();
  }

  Future<void> _initializeOfflineManager() async {
    await _offlineManager.init();

    _offlineManager.onSyncCompleted = () {
      if (mounted) {
        _loadTasks(); // Recharger après synchronisation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synchronisation terminée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    };
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final tasks = await _offlineManager.getTasks(
        authService,
        status: _activeFilter != 0 ? _convertStatusToApi(_activeFilter.toString()) : null,
      );

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

  @override
  Widget build(BuildContext context) {
    List<MaintenanceTask> filteredTasks = _tasks.where((task) {
      bool matchesSearch = task.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchQuery.toLowerCase());

      if (_activeFilter == 0) return matchesSearch;
      return matchesSearch && task.status == _activeFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfileScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicateur offline
          OfflineIndicator(),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Status Filters
          Container(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('All', 0),
                _buildFilterChip('Pending', AppConstants.STATUS_PENDING),
                _buildFilterChip('In Progress', AppConstants.STATUS_IN_PROGRESS),
                _buildFilterChip('Completed', AppConstants.STATUS_COMPLETED),
                _buildFilterChip('Rebuttal', AppConstants.STATUS_CANCELLED),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Tasks List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredTasks.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tasks found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadTasks,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  return _buildTaskCard(filteredTasks[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int status) {
    bool isSelected = _activeFilter == status;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _activeFilter = selected ? status : 0;
          });
          _loadTasks();
        },
        selectedColor: Colors.blue.shade100,
        checkmarkColor: Colors.blue.shade700,
      ),
    );
  }

  Widget _buildTaskCard(MaintenanceTask task) {
    Color statusColor;
    String statusText;

    switch (task.status) {
      case AppConstants.STATUS_PENDING:
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case AppConstants.STATUS_IN_PROGRESS:
        statusColor = Colors.blue;
        statusText = 'In Progress';
        break;
      case AppConstants.STATUS_COMPLETED:
        statusColor = Colors.green;
        statusText = 'Completed';
        break;
      case AppConstants.STATUS_CANCELLED:
        statusColor = Colors.red;
        statusText = 'Rebuttal';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 12,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        title: Text(
          task.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  '${task.scheduledDate.day}/${task.scheduledDate.month}/${task.scheduledDate.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(width: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right),
        onTap: () => _navigateToTaskDetail(task),
      ),
    );
  }

  void _navigateToTaskDetail(MaintenanceTask task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(task: task),
      ),
    );
    _loadTasks(); // Refresh après retour
  }

  String _convertStatusToApi(String status) {
    // Implementation de votre logique de conversion
    return status;
  }
}