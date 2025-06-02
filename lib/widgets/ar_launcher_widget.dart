import 'package:flutter/material.dart';
import '../services/ar_platform_service.dart';
import '../models/equipment.dart';

class ARLauncherWidget extends StatefulWidget {
  final Equipment equipment;
  final Map<String, dynamic>? part;

  const ARLauncherWidget({
    Key? key,
    required this.equipment,
    this.part,
  }) : super(key: key);

  @override
  State<ARLauncherWidget> createState() => _ARLauncherWidgetState();
}

class _ARLauncherWidgetState extends State<ARLauncherWidget> {
  bool _isARSupported = false;
  bool _isLoading = true;
  String? _localModelPath;

  @override
  void initState() {
    super.initState();
    _checkARSupport();
  }

  Future<void> _checkARSupport() async {
    final isSupported = await ARPlatformService.isARCoreSupported();
    setState(() {
      _isARSupported = isSupported;
      _isLoading = false;
    });

    // Précharger le modèle 3D si disponible
    if (isSupported && widget.equipment.model3dViewerUrl != null) {
      _preloadModel();
    }
  }

  Future<void> _preloadModel() async {
    if (widget.equipment.model3dViewerUrl == null) return;

    try {
      final localPath = await ARPlatformService.downloadModel(
          widget.equipment.model3dViewerUrl!
      );

      setState(() {
        _localModelPath = localPath;
      });
    } catch (e) {
      print('Erreur préchargement modèle: $e');
    }
  }

  Future<void> _launchAR() async {
    if (!_isARSupported) {
      _showARNotSupportedDialog();
      return;
    }

    try {
      final success = await ARPlatformService.startARSession(
        equipmentId: widget.equipment.id.toString(),
        equipmentName: widget.equipment.name,
        model3dUrl: widget.equipment.model3dViewerUrl,
        model3dPath: _localModelPath,
      );

      if (!success) {
        _showErrorDialog('Impossible de démarrer la session AR');
      }
    } catch (e) {
      _showErrorDialog('Erreur: $e');
    }
  }

  void _showARNotSupportedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('AR non supportée'),
        content: Text(
            'Votre appareil ne supporte pas ARCore. '
                'Veuillez installer ARCore depuis le Google Play Store ou '
                'utiliser un appareil compatible.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Vérification AR...'),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.view_in_ar,
                  color: _isARSupported ? Colors.purple : Colors.grey,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Réalité Augmentée',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_localModelPath != null)
                  Icon(Icons.download_done, color: Colors.green, size: 16),
              ],
            ),

            SizedBox(height: 12),

            Text(
              'Visualisez ${widget.equipment.name} en réalité augmentée',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            if (widget.part != null) ...[
              SizedBox(height: 8),
              Text(
                'Pièce: ${widget.part!['part_name'] ?? 'N/A'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],

            SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isARSupported ? _launchAR : null,
                icon: Icon(Icons.play_arrow),
                label: Text(_isARSupported ? 'Lancer AR' : 'AR non supportée'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isARSupported ? Colors.purple : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            if (!_isARSupported) ...[
              SizedBox(height: 8),
              Text(
                'ARCore requis pour utiliser cette fonctionnalité',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}