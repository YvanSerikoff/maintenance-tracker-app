// Flutter Widget - Dashboard CMMS
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';



// Modèles de données
class MaintenanceRequest {
  final int id;
  final String name;
  final String description;
  final String? equipmentName;
  final String? model3dViewerUrl;
  final String maintenanceType;
  final String priority;

  MaintenanceRequest({
    required this.id,
    required this.name,
    required this.description,
    this.equipmentName,
    this.model3dViewerUrl,
    required this.maintenanceType,
    required this.priority,
  });

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequest(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      equipmentName: json['equipment_id']?['name'],
      model3dViewerUrl: json['equipment_id']?['model_3d_viewer_url'],
      maintenanceType: json['maintenance_type'] ?? '',
      priority: json['priority'] ?? '',
    );
  }
}

class Equipment {
  final int id;
  final String name;
  final String? location;
  final String? model3dViewerUrl;
  final bool has3dModel;

  Equipment({
    required this.id,
    required this.name,
    this.location,
    this.model3dViewerUrl,
    required this.has3dModel,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      model3dViewerUrl: json['model3d_id']?['viewer_url'],
      has3dModel: json['model3d_id'] != null,
    );
  }
}

// Widget principal du dashboard
class CMMSDashboard extends StatefulWidget {
  final String baseUrl;
  final String username;
  final String password;

  const CMMSDashboard({
    Key? key,
    required this.baseUrl,
    required this.username,
    required this.password,
  }) : super(key: key);

  @override
  _CMMSDashboardState createState() => _CMMSDashboardState();
}

class _CMMSDashboardState extends State<CMMSDashboard> {
  bool isLoading = true;
  Map<String, dynamic>? dashboardData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  String encodeBasicAuth(String username, String password) {
    String credentials = '$username:$password';
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    return stringToBase64.encode(credentials);
  }

  Future<void> loadDashboard() async {
    try {
      String authHeader = 'Basic ${encodeBasicAuth(widget.username, widget.password)}';
      
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/api/flutter/maintenance/dashboard'),
        headers: {
          'Authorization': authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            dashboardData = data['data'];
            isLoading = false;
            errorMessage = null;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Erreur inconnue';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Erreur HTTP: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur de connexion: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CMMS Dashboard'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = null;
              });
              loadDashboard();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Erreur',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 8),
                      Text(errorMessage!),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });
                          loadDashboard();
                        },
                        child: Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : buildDashboardContent(),
    );
  }

  Widget buildDashboardContent() {
    if (dashboardData == null) return SizedBox();

    return RefreshIndicator(
      onRefresh: loadDashboard,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations utilisateur
            buildUserInfo(),
            SizedBox(height: 20),
            
            // Statistiques rapides
            buildQuickStats(),
            SizedBox(height: 20),
            
            // Demandes récentes
            buildRecentRequests(),
            SizedBox(height: 20),
            
            // Équipements avec modèles 3D
            buildEquipmentWith3D(),
            SizedBox(height: 20),
            
            // Maintenance préventive
            buildPreventiveMaintenance(),
          ],
        ),
      ),
    );
  }

  Widget buildUserInfo() {
    final userInfo = dashboardData!['user_info'];
    final personInfo = userInfo['person_info'];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade700,
              child: Text(
                userInfo['name'].toString().substring(0, 1).toUpperCase(),
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userInfo['name'],
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (personInfo != null) ...[
                    Text(
                      personInfo['role'] ?? 'Rôle non défini',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (personInfo['available'])
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Disponible',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildQuickStats() {
    final summary = dashboardData!['summary'];
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Demandes actives',
            summary['total_active_requests'].toString(),
            Icons.build,
            Colors.orange,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Terminées',
            summary['completed_requests'].toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Modèles 3D',
            summary['equipment_with_3d'].toString(),
            Icons.view_in_ar,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRecentRequests() {
    final requests = dashboardData!['requests']['recent'] as List;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Demandes récentes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 12),
            if (requests.isEmpty)
              Text('Aucune demande récente')
            else
              ...requests.take(5).map((req) => ListTile(
                leading: Icon(
                  req['maintenance_type'] == 'preventive' 
                      ? Icons.schedule 
                      : Icons.build,
                  color: req['priority'] == 'high' 
                      ? Colors.red
                      : req['priority'] == 'medium'
                          ? Colors.orange
                          : Colors.green,
                ),
                title: Text(req['name']),
                subtitle: Text(req['description'] ?? ''),
                trailing: req['equipment_id']?['model_3d_viewer_url'] != null
                    ? IconButton(
                        icon: Icon(Icons.view_in_ar),
                        onPressed: () {
                          // Ouvrir le viewer 3D
                          _openModel3DViewer(
                            req['equipment_id']['model_3d_viewer_url'],
                          );
                        },
                      )
                    : null,
              )).toList(),
          ],
        ),
      ),
    );
  }

  Widget buildEquipmentWith3D() {
    final equipment = dashboardData!['equipment']['with_3d_models'] as List;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Équipements avec modèles 3D',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 12),
            if (equipment.isEmpty)
              Text('Aucun équipement avec modèle 3D')
            else
              ...equipment.map((eq) => ListTile(
                leading: Icon(Icons.precision_manufacturing, color: Colors.blue),
                title: Text(eq['name']),
                subtitle: Text(eq['location'] ?? 'Emplacement non défini'),
                trailing: IconButton(
                  icon: Icon(Icons.view_in_ar),
                  onPressed: () {
                    _openModel3DViewer(eq['model3d_id']['viewer_url']);
                  },
                ),
              )).toList(),
          ],
        ),
      ),
    );
  }

  Widget buildPreventiveMaintenance() {
    final preventive = dashboardData!['preventive_maintenance'] as List;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maintenance préventive',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 12),
            if (preventive.isEmpty)
              Text('Aucune maintenance préventive planifiée')
            else
              ...preventive.take(3).map((req) => ListTile(
                leading: Icon(Icons.schedule, color: Colors.purple),
                title: Text(req['name']),
                subtitle: Text(
                  req['schedule_date'] != null
                      ? 'Planifiée le ${req['schedule_date']}'
                      : 'Date non définie',
                ),
                trailing: req['equipment_id']?['model_3d_viewer_url'] != null
                    ? IconButton(
                        icon: Icon(Icons.view_in_ar),
                        onPressed: () {
                          _openModel3DViewer(
                            req['equipment_id']['model_3d_viewer_url'],
                          );
                        },
                      )
                    : null,
              )).toList(),
          ],
        ),
      ),
    );
  }

  void _openModel3DViewer(String url) {
    // Ici vous pouvez ouvrir l'URL dans un navigateur web
    // ou dans un WebView intégré à l'application
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modèle 3D'),
        content: Text('URL du viewer 3D:\n$url'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

// Exemple d'utilisation dans main.dart
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CMMS Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CMMSDashboard(
        baseUrl: 'http://191.168.1.71:8069',
        username: 'gordon.delangue',
        password: 'odoo123',
      ),
    );
  }
}