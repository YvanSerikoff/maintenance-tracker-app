import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:maintenance_app/models/maintenance_task.dart';
import 'package:maintenance_app/models/equipment.dart';
import 'package:maintenance_app/services/auth_service.dart';
import 'package:maintenance_app/utils/date_formatter.dart';
import 'package:maintenance_app/config/constants.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/flutter_basic_auth.dart';

class TaskDetailScreen extends StatefulWidget {
  final MaintenanceTask task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  TaskDetailScreenState createState() => TaskDetailScreenState();
}

class TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isSaving = false;
  Equipment? _equipment;
  int? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.task.status;
    // Utilise WidgetsBinding pour accéder au context après l'init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = authService.apiService;
      if (apiService != null) {
        fetchEquipment(widget.task.id, apiService);
      } else {
        print('Erreur : AuthService non initialisé');
      }
    });
  }

  void fetchEquipment(int requestId, CMMSApiService apiService) async {
    try {
      final response = await apiService.getEquipmentByRequest(requestId);
      if (response != null && response['success'] == true) {
        setState(() {
          _equipment = Equipment.fromJson(response['data']['equipment_id']);
        });
        print('Équipement récupéré : ${_equipment?.category}');
      } else {
        print('Erreur API : ${response != null ? response['message'] : 'Réponse nulle'}');
      }
    } catch (e) {
      print('Erreur lors de l\'appel API : $e');
    }
  }

  Future<void> _updateTaskStatus(int newStatus) async {
    if (newStatus == widget.task.status) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = authService.apiService;

      if (apiService == null) {
        throw Exception('Not authenticated');
      }

      final Map<String, dynamic> updateData = {
        'stage_id': newStatus
      };

      final response = await apiService.updateMaintenanceRequest(
        widget.task.id,
        updateData,
      );

      if (response != null && response['success'] == true) {
        setState(() {
          _selectedStatus = newStatus;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut de la tâche mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorMessage = response != null ?
        (response['message'] ?? 'Échec de la mise à jour du statut') :
        'Échec de la mise à jour du statut';
        throw Exception(errorMessage);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour : ${e.toString()}'),
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
    final statusColor = _getStatusColor(_selectedStatus ?? widget.task.status);
    final statusIcon = _getStatusIcon(_selectedStatus ?? widget.task.status);
    return Scaffold(
      appBar: AppBar(
        title: Text('Détail de la tâche'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header visuel
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor.withOpacity(0.8), statusColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.2),
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
                        child: Icon(statusIcon, color: Colors.white, size: 32),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.task.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.white70, size: 16),
                              SizedBox(width: 4),
                              Text(widget.task.location, style: TextStyle(color: Colors.white70, fontSize: 12)),
                              SizedBox(width: 12),
                              Icon(Icons.access_time, color: Colors.white70, size: 16),
                              SizedBox(width: 4),
                              Text(_formatDate(widget.task.scheduledDate), style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              // Statut
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Statut', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey.shade800)),
                      SizedBox(height: 16),
                      _isSaving
                          ? Center(child: CircularProgressIndicator())
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatusButton(AppConstants.STATUS_PENDING, 'En attente', Colors.orange),
                          _buildStatusButton(AppConstants.STATUS_IN_PROGRESS, 'En cours', Colors.blue),
                          _buildStatusButton(AppConstants.STATUS_COMPLETED, 'Terminée', Colors.green),
                          _buildStatusButton(AppConstants.STATUS_CANCELLED, 'Mise de côté', Colors.redAccent),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Priorité
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: _getPriorityColor(widget.task.priority)),
                      SizedBox(width: 8),
                      Text('Priorité : ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_getPriorityLabel(widget.task.priority), style: TextStyle(color: _getPriorityColor(widget.task.priority))),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Description
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey.shade800)),
                      SizedBox(height: 8),
                      widget.task.description.isEmpty
                          ? Text('Aucune description')
                          : Html(data: widget.task.description),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Equipement
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Équipement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey.shade800)),
                      SizedBox(height: 8),
                      _equipment == null
                          ? Text('Information non disponible')
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_equipment!.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Catégorie : ${_equipment!.category}'),
                          SizedBox(height: 4),
                          Text('Localisation : ${_equipment!.location}'),
                          if (_equipment!.model3dViewerUrl != null) ...[
                            SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final url = _equipment!.model3dViewerUrl!;
                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Impossible d\'ouvrir le lien')),
                                  );
                                }
                              },
                              icon: Icon(Icons.view_in_ar),
                              label: Text('Voir le modèle 3D'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              // Bouton principal
              ElevatedButton.icon(
                onPressed: () {
                  _showAddNoteDialog();
                },
                icon: Icon(Icons.note_add),
                label: Text('Ajouter un compte-rendu'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case AppConstants.STATUS_PENDING:
        return Colors.orange;
      case AppConstants.STATUS_IN_PROGRESS:
        return Colors.blue;
      case AppConstants.STATUS_COMPLETED:
        return Colors.green;
      case AppConstants.STATUS_CANCELLED:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case AppConstants.STATUS_PENDING:
        return Icons.hourglass_empty;
      case AppConstants.STATUS_IN_PROGRESS:
        return Icons.engineering;
      case AppConstants.STATUS_COMPLETED:
        return Icons.check_circle;
      case AppConstants.STATUS_CANCELLED:
        return Icons.error_outline;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 0:
        return 'Faible';
      case 1:
        return 'Normale';
      case 2:
        return 'Haute';
      case 3:
        return 'Urgente';
      default:
        return 'Inconnue';
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
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

  Widget _buildStatusButton(int status, String label, Color color) {
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
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Work Log'),
        content: TextField(
          controller: noteController,
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
              if (noteController.text.isNotEmpty) {
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

  void _showModel3DViewerDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('3D Model Viewer'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('URL: $url'),
              SizedBox(height: 16),
              Text('Note: To view the 3D model, please open the link in a web browser.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

