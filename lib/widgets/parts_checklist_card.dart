import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ar_service.dart';
import '../services/parts_api_service.dart';

class PartsChecklistCard extends StatefulWidget {
  final List<Map<String, dynamic>>? parts;
  final Function(List<Map<String, dynamic>>)? onPartsUpdated;
  final String? modelPath;
  final int taskId;
  final PartsApiService? partsApiService;

  const PartsChecklistCard({
    Key? key,
    this.parts,
    this.onPartsUpdated,
    this.modelPath,
    required this.taskId,
    this.partsApiService,
  }) : super(key: key);

  @override
  PartsChecklistCardState createState() => PartsChecklistCardState();
}

class PartsChecklistCardState extends State<PartsChecklistCard>
    with TickerProviderStateMixin {
  late List<Map<String, dynamic>> _parts;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  late AnimationController _listAnimationController;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();

    // Initialiser la liste des pièces
    _parts = widget.parts != null
        ? List<Map<String, dynamic>>.from(widget.parts!)
        : [];

    // Animation pour la barre de progression
    _progressAnimationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: _getProgress(),
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));

    // Animation pour la liste
    _listAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _progressAnimationController.forward();
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  double _getProgress() {
    if (_parts.isEmpty) return 0.0;
    final checkedCount = _parts.where((part) => part['done'] == true).length;
    return checkedCount / _parts.length;
  }

  int _getCheckedCount() {
    return _parts.where((part) => part['done'] == true).length;
  }

  // ✨ CORRECTION : Gérer les int? correctement
  Future<void> _togglePartStatus(int partIndex, int partId, bool isDone) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
      // Mise à jour optimiste de l'UI
      _parts[partIndex]['done'] = isDone;
    });

    // Animer la barre de progression
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: _getProgress(),
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));
    _progressAnimationController.reset();
    _progressAnimationController.forward();

    // Mettre à jour via l'API
    bool success = false;
    if (widget.partsApiService != null) {
      success = await widget.partsApiService!.updatePartStatus(
          widget.taskId,
          partId,
          isDone
      );
    }

    if (success) {
      // Succès : notifier le parent
      if (widget.onPartsUpdated != null) {
        widget.onPartsUpdated!(_parts);
      }

      _showSuccessSnackBar(
          isDone ? 'Part marked as completed ✓' : 'Part marked as pending'
      );
    } else {
      // Échec : revenir à l'état précédent
      setState(() {
        _parts[partIndex]['done'] = !isDone;
      });

      // Réanimer la barre de progression
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: _getProgress(),
      ).animate(CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeInOut,
      ));
      _progressAnimationController.reset();
      _progressAnimationController.forward();

      _showErrorSnackBar('Failed to update part status. Please try again.');
    }

    setState(() {
      _isUpdating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_parts.isEmpty) {
      return _buildEmptyState();
    }

    final checkedCount = _getCheckedCount();
    final totalCount = _parts.length;
    final isAllChecked = checkedCount == totalCount;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(checkedCount, totalCount, isAllChecked),
            SizedBox(height: 16),
            _buildProgressBar(),
            SizedBox(height: 16),
            _buildPartsList(),
            if (_isUpdating) ...[
              SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Updating...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Parts Checklist',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade500),
                  SizedBox(width: 8),
                  Text(
                    'No parts have been found for this task.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int checkedCount, int totalCount, bool isAllChecked) {
    return Row(
      children: [
        Icon(
          isAllChecked ? Icons.check_circle : Icons.checklist,
          color: isAllChecked ? Colors.green : Colors.blue,
        ),
        SizedBox(width: 8),
        Text(
          'Parts Checklist',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.grey.shade800,
          ),
        ),
        Spacer(),
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isAllChecked ? Colors.green.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isAllChecked ? Colors.green.shade200 : Colors.blue.shade200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAllChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: isAllChecked ? Colors.green.shade700 : Colors.blue.shade700,
              ),
              SizedBox(width: 4),
              Text(
                '$checkedCount/$totalCount',
                style: TextStyle(
                  color: isAllChecked ? Colors.green.shade700 : Colors.blue.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: _progressAnimation.value,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _progressAnimation.value == 1.0 ? Colors.green : Colors.blue,
              ),
              minHeight: 8,
            );
          },
        ),
        SizedBox(height: 4),
        Text(
          '${(_getProgress() * 100).toInt()}% completed',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPartsList() {
    return AnimatedBuilder(
      animation: _listAnimationController,
      builder: (context, child) {
        return Column(
          children: _parts.asMap().entries.map((entry) {
            final index = entry.key;
            final part = entry.value;

            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _listAnimationController,
                curve: Interval(
                  index * 0.1,
                  1.0,
                  curve: Curves.easeOut,
                ),
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _listAnimationController,
                    curve: Interval(
                      index * 0.1,
                      1.0,
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
                child: _buildPartItem(part, index),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPartItem(Map<String, dynamic> part, int index) {
    // ✨ CORRECTION : Conversion sécurisée et vérification
    final partIdRaw = part['id'];
    int partId = 0;

    if (partIdRaw is int) {
      partId = partIdRaw;
    } else if (partIdRaw is String) {
      partId = int.tryParse(partIdRaw) ?? 0;
    }

    // Si l'ID n'est pas valide, on ignore cette pièce
    if (partId <= 0) return SizedBox.shrink();

    final isChecked = part['done'] == true;
    final partName = _getPartName(part);
    final description = _getPartDescription(part);
    final interventionType = _getInterventionType(part);
    final submodelViewerUrl = _getSubmodelViewerUrl(part);

    final sequenceRaw = part['sequence'];
    int sequence = 0;
    if (sequenceRaw is int) {
      sequence = sequenceRaw;
    } else if (sequenceRaw is String) {
      sequence = int.tryParse(sequenceRaw) ?? 0;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isChecked ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isChecked ? Colors.green.shade200 : Colors.grey.shade200,
          width: isChecked ? 2 : 1,
        ),
        boxShadow: isChecked
            ? [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                child: Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: isChecked,
                    onChanged: _isUpdating
                        ? null
                        : (bool? value) {
                      if (value != null) {
                        _togglePartStatus(index, partId, value);
                      }
                    },
                    activeColor: Colors.green,
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              if (sequence > 0) SizedBox(width: 8),
              Icon(
                _getPartTypeIcon(interventionType ?? ''),
                color: _getInterventionTypeColor(interventionType ?? ''),
                size: 24,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey.shade800,
                        decoration: isChecked ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.green,
                      ),
                    ),
                    if (interventionType != null && interventionType.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getInterventionTypeColor(interventionType),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          interventionType,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          if (description != null && description.isNotEmpty) ...[
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ),
          ],

          SizedBox(height: 8),
          Row(
            children: [
              if (submodelViewerUrl != null && submodelViewerUrl.isNotEmpty)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchUrl(submodelViewerUrl),
                    icon: Icon(Icons.view_in_ar, size: 16),
                    label: Text('3D Model', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ),
              if (submodelViewerUrl != null && submodelViewerUrl.isNotEmpty)
                SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchAR(context, part),
                  icon: Icon(Icons.camera, size: 16),
                  label: Text('AR View', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Méthodes utilitaires (reprises du PartsDropdownCard original)
  String _getPartName(Map<String, dynamic> part) {
    return part['part_name']?.toString() ?? 'Unnamed Part';
  }

  String? _getSubmodelViewerUrl(Map<String, dynamic> part) {
    if (part['submodel'] is Map && part['submodel']['viewer_url'] != null) {
      return part['submodel']['viewer_url'].toString();
    }
    return null;
  }

  String? _getPartDescription(Map<String, dynamic> part) {
    return part['description']?.toString().isNotEmpty == true
        ? part['description'].toString()
        : null;
  }

  String? _getInterventionType(Map<String, dynamic> part) {
    return part['intervention_type_display']?.toString() ??
        part['intervention_type']?.toString();
  }

  IconData _getPartTypeIcon(String interventionType) {
    switch (interventionType.toLowerCase()) {
      case 'remplacement':
      case 'replacement':
        return Icons.autorenew;
      case 'maintenance':
        return Icons.build_circle;
      case 'réparation':
      case 'repair':
        return Icons.engineering;
      case 'inspection':
        return Icons.search;
      case 'nettoyage':
      case 'cleaning':
        return Icons.cleaning_services;
      case 'lubrification':
      case 'lubrication':
        return Icons.oil_barrel;
      default:
        return Icons.build;
    }
  }

  Color _getInterventionTypeColor(String interventionType) {
    switch (interventionType.toLowerCase()) {
      case 'remplacement':
      case 'replacement':
        return Colors.red;
      case 'maintenance':
        return Colors.blue;
      case 'réparation':
      case 'repair':
        return Colors.orange;
      case 'inspection':
        return Colors.green;
      case 'nettoyage':
      case 'cleaning':
        return Colors.cyan;
      case 'lubrification':
      case 'lubrication':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showErrorSnackBar('Unable to open the URL: $url');
      }
    } catch (e) {
      _showErrorSnackBar('Error while opening the URL: ${e.toString()}');
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

void _launchAR(BuildContext context, Map<String, dynamic> part) async {
  try {
    String? modelPath;
    if (part['submodel'] is Map && part['submodel']['gltf_url'] != null) {
      modelPath = part['submodel']['gltf_url'].toString();
    }
    await ArService.launchArViewer(modelPath ?? 'models/damaged_helmet.glb');
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Impossible d\'ouvrir la vue AR : $e')),
    );
  }
}