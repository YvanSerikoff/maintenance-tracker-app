import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maintenance_app/models/maintenance_task.dart';
import 'package:maintenance_app/models/equipment.dart';
import 'package:maintenance_app/services/auth_service.dart';
import 'package:maintenance_app/utils/date_formatter.dart';

class TaskDetailScreen extends StatefulWidget {
  final MaintenanceTask task;

  TaskDetailScreen({required this.task});

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isLoadingEquipment = true;
  bool _isSaving = false;
  Equipment? _equipment;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.task.status;
    _loadEquipmentDetails();
  }

  Future<void> _loadEquipmentDetails() async {
    setState(() {
      _isLoadingEquipment = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final odooService = authService.odooService;
      
      if (odooService == null) {
        throw Exception('Not authenticated');
      }

      final equipment = await odooService.getEquipment(widget.task.equipmentId);
      setState(() {
        _equipment = equipment;
        _isLoadingEquipment = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading equipment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoadingEquipment = false;
      });
    }
  }

  Future<void> _updateTaskStatus(String newStatus) async {
    if (newStatus == widget.task.status) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final odooService = authService.odooService;
      
      if (odooService == null) {
        throw Exception('Not authenticated');
      }

      final success = await odooService.updateTaskStatus(widget.task.id, newStatus);
      
      if (success) {
        setState(() {
          _selectedStatus = newStatus;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to update task status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Header
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildPriorityIndicator(widget.task.priority),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.task.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildInfoRow(Icons.calendar_today, 'Scheduled Date:', formatDateFull(widget.task.scheduledDate)),
                      _buildInfoRow(Icons.location_on, 'Location:', widget.task.location),
                      _buildInfoRow(Icons.update, 'Last Updated:', formatDateFull(widget.task.lastUpdated)),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Task Status
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 16),
                      _isSaving
                          ? Center(child: CircularProgressIndicator())
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatusButton('pending', 'Pending', Colors.orange),
                                _buildStatusButton('in_progress', 'In Progress', Colors.blue),
                                _buildStatusButton('completed', 'Completed', Colors.green),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Task Description
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.task.description.isEmpty
                            ? 'No description provided'
                            : widget.task.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Equipment Information
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Equipment',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 16),
                      _isLoadingEquipment
                          ? Center(
                              child: CircularProgressIndicator(),
                            )
                          : _equipment == null
                              ? Text('Equipment information not available')
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: _equipment!.imageUrl.isNotEmpty
                                              ? Image.network(_equipment!.imageUrl)
                                              : Icon(Icons.build, size: 40),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _equipment!.name,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text('Serial: ${_equipment!.serialNumber}'),
                                              SizedBox(height: 4),
                                              Text('Category: ${_equipment!.category}'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Text('Location: ${_equipment!.location}'),
                                    SizedBox(height: 4),
                                    Text('Installation Date: ${formatDate(_equipment!.installationDate)}'),
                                  ],
                                ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Add Note or Work Log button
              ElevatedButton.icon(
                onPressed: () {
                  // Implement note/work log functionality
                  _showAddNoteDialog();
                },
                icon: Icon(Icons.note_add),
                label: Text('Add Work Log'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityIndicator(int priority) {
    String priorityText;
    Color priorityColor;
    
    switch (priority) {
      case 0:
        priorityText = 'Low';
        priorityColor = Colors.green;
        break;
      case 1:
        priorityText = 'Normal';
        priorityColor = Colors.blue;
        break;
      case 2:
        priorityText = 'High';
        priorityColor = Colors.orange;
        break;
      case 3:
        priorityText = 'Urgent';
        priorityColor = Colors.red;
        break;
      default:
        priorityText = 'Unknown';
        priorityColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: priorityColor),
      ),
      child: Text(
        'Priority: $priorityText',
        style: TextStyle(
          color: priorityColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusButton(String status, String label, Color color) {
    bool isSelected = _selectedStatus == status;
    
    return InkWell(
      onTap: () => _updateTaskStatus(status),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showAddNoteDialog() {
    final TextEditingController _noteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Work Log'),
        content: TextField(
          controller: _noteController,
          decoration: InputDecoration(
            hintText: 'Enter work done details',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement adding work log to Odoo
              if (_noteController.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Work log added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text('SAVE'),
          ),
        ],
      ),
    );
  }
}