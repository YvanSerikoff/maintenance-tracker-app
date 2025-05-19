import 'package:flutter/material.dart';
import 'package:maintenance_app/config/constants.dart';
import 'package:provider/provider.dart';
import 'package:maintenance_app/services/auth_service.dart';
import 'package:maintenance_app/models/maintenance_task.dart';
import 'package:maintenance_app/screens/tasks/task_list_screen.dart';
import 'package:maintenance_app/screens/profile_screen.dart';
import 'package:maintenance_app/screens/auth/login_screen.dart';
import 'package:maintenance_app/config/constants.dart';

import '../tasks/task_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  List<MaintenanceTask> _tasks = [];
  int _pendingCount = 0;
  int _inProgressCount = 0;
  int _completedCount = 0;
  int _rebuttalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = authService.apiService;
      
      if (apiService == null) {
        throw Exception('Not authenticated');
      }

      final response = await apiService.getMaintenanceRequests();
      if (response == null || response['success'] != true) {
        // Affiche le message d'erreur de l'API si disponible
        final apiMessage = response != null && response['message'] != null
            ? response['message']
            : 'Failed to fetch tasks';
        throw Exception(apiMessage);
      }
      final List<dynamic> data = response['data']['requests'] ?? [];
      final tasks = data.map((json) => MaintenanceTask.fromJson(json)).toList();

      setState(() {
        _tasks = tasks.cast<MaintenanceTask>();

        _pendingCount = _tasks.where((task) => task.status == '1').length;
        _inProgressCount = _tasks.where((task) => task.status == '2').length;
        _completedCount = _tasks.where((task) => task.status == '3').length;
        print('nom : ${_tasks[0].status}');
        _rebuttalCount = _tasks.where((task) => task.status == '4').length;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading dashboard: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userName = authService.userName ?? 'Technician';

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  userName[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back,',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    Text(
                                      userName,
                                      style: Theme.of(context).textTheme.displayMedium,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.person),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ProfileScreen()),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 24),
                      
                      // Task Status Summary
                      Text(
                        'Task Overview',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      SizedBox(height: 16),

                      Row(
                        children: [
                          _buildStatusCard(
                            context,
                            'Pending',
                            _pendingCount,
                            Colors.orange,
                            Icons.hourglass_empty,
                                () => _navigateToTaskList('pending'),
                            'Tâches en attente',
                          ),
                          SizedBox(width: 16),
                          _buildStatusCard(
                            context,
                            'In Progress',
                            _inProgressCount,
                            Colors.blue,
                            Icons.engineering,
                                () => _navigateToTaskList('in_progress'),
                            'Tâches en cours',
                          ),
                          SizedBox(width: 16),
                          _buildStatusCard(
                            context,
                            'Completed',
                            _completedCount,
                            Colors.green,
                            Icons.check_circle,
                                () => _navigateToTaskList('completed'),
                            'Tâches terminées',
                          ),
                          SizedBox(width: 16),
                          _buildStatusCard(
                              context,
                              'Rebuttal',
                              _rebuttalCount,
                              Colors.redAccent,
                              Icons.error,
                                  () => _navigateToTaskList('rebuttal'),
                              'Mis sur le côté')
                        ],
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Recent Tasks
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Tasks',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          TextButton(
                            onPressed: () => _navigateToTaskList(''),
                            child: Text('View All'),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      
                      // Recent Tasks List
                      _tasks.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Text(
                                  'No tasks assigned to you.',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _tasks.length > 5 ? 5 : _tasks.length,
                              itemBuilder: (context, index) {
                                final task = _tasks[index];
                                return _buildTaskCard(context, task);
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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
          if (index == 1) {
            _navigateToTaskList('');
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

  Widget _buildStatusCard(
      BuildContext context,
      String title,
      int count,
      Color color,
      IconData icon,
      VoidCallback onTap,
      String contextText, // Nouveau paramètre
      ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          color: color.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(icon, color: color, size: 32),
                SizedBox(height: 8),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  contextText, // Affichage du contexte
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, MaintenanceTask task) {
    Color statusColor;
    switch (task.status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(),
          child: Text(
            task.priority.toString(),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
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
        trailing: Chip(
          label: Text(
            _capitalizeFirst(task.status.replaceAll('_', ' ')),
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          backgroundColor: statusColor,
          padding: EdgeInsets.all(0),
        ),
        onTap: () {
          _navigateToTaskDetail(task);
        },
      ),
    );
  }

  void _navigateToTaskList(String status) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskListScreen(status: status),
      ),
    );
    _loadDashboardData(); // Rafraîchit après retour
  }

  void _navigateToTaskDetail(MaintenanceTask task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(task: task),
      ),
    );
    _loadDashboardData(); // Rafraîchit après retour
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
