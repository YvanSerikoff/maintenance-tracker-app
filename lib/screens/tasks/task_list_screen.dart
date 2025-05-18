import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maintenance_app/services/auth_service.dart';
import 'package:maintenance_app/models/maintenance_task.dart';
import 'package:maintenance_app/screens/tasks/task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  final String status;

  TaskListScreen({this.status = ''});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  bool _isLoading = true;
  List<MaintenanceTask> _tasks = [];
  String _activeFilter = '';
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
      final odooService = authService.odooService;
      
      if (odooService == null) {
        throw Exception('Not authenticated');
      }

      final tasks = await odooService.getTasks(status: _activeFilter);
      
      setState(() {
        _tasks = tasks;
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

  void _setFilter(String filter) {
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
    if (_searchQuery.isEmpty) {
      return _tasks;
    }
    
    return _tasks.where((task) {
      return task.name.toLowerCase().contains(_searchQuery) || 
             task.description.toLowerCase().contains(_searchQuery) ||
             task.location.toLowerCase().contains(_searchQuery);
    }).toList();
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
                PopupMenuButton<String>(
                  icon: Icon(Icons.filter_list),
                  onSelected: _setFilter,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: '',
                      child: Text('All Tasks'),
                    ),
                    PopupMenuItem(
                      value: 'pending',
                      child: Text('Pending'),
                    ),
                    PopupMenuItem(
                      value: 'in_progress',
                      child: Text('In Progress'),
                    ),
                    PopupMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
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
    );
  }

  String _getTitle() {
    switch (_activeFilter) {
      case 'pending':
        return 'Pending Tasks';
      case 'in_progress':
        return 'In Progress Tasks';
      case 'completed':
        return 'Completed Tasks';
      default:
        return 'All Tasks';
    }
  }

  Widget _buildTaskCard(BuildContext context, MaintenanceTask task) {
    Color statusColor;
    IconData statusIcon;
    
    switch (task.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusIcon = Icons.engineering;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
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
            Text(
              task.description.length > 70 
                ? task.description.substring(0, 70) + '...'
                : task.description,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  task.location,
                  style: TextStyle(fontSize: 12),
                ),
                Spacer(),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  _formatDate(task.scheduledDate),
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            _capitalizeFirst(task.status.replaceAll('_', ' ')),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(task: task),
            ),
          ).then((_) => _loadTasks());
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
}