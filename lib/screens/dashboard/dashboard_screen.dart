import 'package:flutter/material.dart';
import 'package:maintenance_app/config/constants.dart';
import 'package:provider/provider.dart';
import 'package:maintenance_app/services/auth_service.dart';
import 'package:maintenance_app/services/offline_manager.dart';
import 'package:maintenance_app/models/maintenance_task.dart';
import 'package:maintenance_app/screens/tasks/task_list_screen.dart';
import 'package:maintenance_app/screens/profile_screen.dart';
import 'package:maintenance_app/screens/auth/login_screen.dart';
import 'package:maintenance_app/widgets/offline_indicator.dart';
import '../tasks/task_detail_screen.dart';
import 'package:maintenance_app/widgets/task_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  List<MaintenanceTask> _tasks = [];
  int _pendingCount = 0;
  int _inProgressCount = 0;
  int _completedCount = 0;
  int _rebuttalCount = 0;
  final OfflineManager _offlineManager = OfflineManager();

  @override
  void initState() {
    super.initState();
    _initializeOfflineManager();
    _loadDashboardData();
  }

  Future<void> _initializeOfflineManager() async {
    await _offlineManager.init();

    _offlineManager.onSyncCompleted = () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synchronisation finished'),
            backgroundColor: Colors.green,
          ),
        );
      }
    };
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // ✅ Utiliser OfflineManager au lieu d'appeler directement l'API
      final tasks = await _offlineManager.getTasks(authService);

      setState(() {
        _tasks = tasks.cast<MaintenanceTask>();

        _pendingCount = _tasks.where((task) => task.status == AppConstants.STATUS_PENDING).length;
        _inProgressCount = _tasks.where((task) => task.status == AppConstants.STATUS_IN_PROGRESS).length;
        _completedCount = _tasks.where((task) => task.status == AppConstants.STATUS_COMPLETED).length;
        _rebuttalCount = _tasks.where((task) => task.status == AppConstants.STATUS_CANCELLED).length;
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Disconnect'),
          content: Text('Do you really want to disconnect?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                      (route) => false,
                );
              },
              child: Text('Disconnect', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _statusLabel(int status) {
    switch (status) {
      case AppConstants.STATUS_PENDING:
        return 'Pending';
      case AppConstants.STATUS_IN_PROGRESS:
        return 'In Progress';
      case AppConstants.STATUS_COMPLETED:
        return 'Completed';
      case AppConstants.STATUS_CANCELLED:
        return 'Rebuttal';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userName = authService.userName ?? 'Technician';
    final isOffline = authService.isOfflineMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfileScreen()),
            ),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Disconnect',
          ),
        ],
      ),

      body: Column(
        children: [
          // Indicateur offline
          OfflineIndicator(),

          // Contenu principal
          Expanded(
            child: _isLoading
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
                      // Welcome Card - Version améliorée
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade600, Colors.blue.shade800],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  userName[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello,',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    userName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        isOffline ? Icons.cloud_off : Icons.cloud_done,
                                        color: Colors.white.withOpacity(0.8),
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        isOffline ? 'Offline mode' : 'Connected',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Task Status Summary - Version améliorée
                      Text(
                        'Tasks Summary',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Remplacer la GridView par deux rangées
                      SizedBox(height: 16),

// Première rangée de statistiques
                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactStatusCard(
                              'Pending',
                              _pendingCount,
                              Colors.orange,
                              Icons.hourglass_empty,
                                  () => _navigateToTaskList(AppConstants.STATUS_PENDING),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildCompactStatusCard(
                              'In Progress',
                              _inProgressCount,
                              Colors.blue,
                              Icons.engineering,
                                  () => _navigateToTaskList(AppConstants.STATUS_IN_PROGRESS),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

// Deuxième rangée de statistiques
                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactStatusCard(
                              'Completed',
                              _completedCount,
                              Colors.green,
                              Icons.check_circle,
                                  () => _navigateToTaskList(AppConstants.STATUS_COMPLETED),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildCompactStatusCard(
                              'Rebuttal',
                              _rebuttalCount,
                              Colors.red,
                              Icons.error_outline,
                                  () => _navigateToTaskList(AppConstants.STATUS_CANCELLED),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Recent Tasks - Version améliorée
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Tasks',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _navigateToTaskList(0),
                            icon: Icon(Icons.arrow_forward, size: 16),
                            label: Text('See All'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Recent Tasks List - Version améliorée
                      _tasks.isEmpty
                          ? Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 12),
                            Text(
                              isOffline
                                  ? 'No tasks available in offline mode'
                                  : 'No tasks assigned yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isOffline) ...[
                              SizedBox(height: 4),
                              Text(
                                'Connect to the internet to sync tasks.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      )
                          : Column(
                        children: _tasks.take(5).map((task) => TaskCard(task: task, onTap: () => _navigateToTaskDetail(task))).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation améliorée
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey.shade600,
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
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            _navigateToTaskList(0);
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

  Widget _buildModernTaskCard(MaintenanceTask task) {
    Color statusColor;
    IconData statusIcon;

    switch (task.status) {
      case AppConstants.STATUS_PENDING:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case AppConstants.STATUS_IN_PROGRESS:
        statusColor = Colors.blue;
        statusIcon = Icons.engineering;
        break;
      case AppConstants.STATUS_COMPLETED:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case AppConstants.STATUS_CANCELLED:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    Color priorityColor = _getPriorityColor(task.priority);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          task.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  task.location,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  _formatDate(task.scheduledDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      SizedBox(width: 4),
                      Text(
                        _statusLabel(task.status),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Priority ${task.priority}',
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: () => _navigateToTaskDetail(task),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _navigateToTaskList(int status) async {
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
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  Widget _buildCompactStatusCard(
      String title,
      int count,
      Color color,
      IconData icon,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

