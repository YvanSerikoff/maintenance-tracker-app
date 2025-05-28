import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import '../services/ar_service.dart';

class ARViewerScreen extends StatefulWidget {
  final String modelUrl;
  final String partName;
  final String? partDescription;

  const ARViewerScreen({
    Key? key,
    required this.modelUrl,
    required this.partName,
    this.partDescription,
  }) : super(key: key);

  @override
  ARViewerScreenState createState() => ARViewerScreenState();
}

class ARViewerScreenState extends State<ARViewerScreen> {
  late ARService arService;
  bool isARInitialized = false;

  @override
  void initState() {
    super.initState();
    arService = ARService();
  }

  @override
  void dispose() {
    arService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR - ${widget.partName}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => _showPartInfo(),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          if (!isARInitialized)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Initialisation de l\'AR...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildControls(),
          ),
        ],
      ),
    );
  }

  void _onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager,
      ) async {
    await arService.onARViewCreated(
      arSessionManager,
      arObjectManager,
      arAnchorManager,
      arLocationManager,
    );

    setState(() {
      isARInitialized = true;
    });

    // Charger automatiquement le modèle 3D
    await arService.loadModel3D(widget.modelUrl, widget.partName);
  }

  Widget _buildControls() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.partName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.partDescription != null) ...[
            SizedBox(height: 8),
            Text(
              widget.partDescription!,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.refresh,
                label: 'Réinitialiser',
                onPressed: () => _resetModel(),
              ),
              _buildControlButton(
                icon: Icons.camera_alt,
                label: 'Capturer',
                onPressed: () => _captureScreenshot(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            padding: EdgeInsets.all(12),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _resetModel() async {
    // Réinitialiser et recharger le modèle
    await arService.loadModel3D(widget.modelUrl, widget.partName);
  }

  void _captureScreenshot() {
    // Implémenter la capture d'écran AR
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Capture d\'écran sauvegardée')),
    );
  }

  void _showPartInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.partName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modèle 3D : ${widget.modelUrl}'),
            if (widget.partDescription != null) ...[
              SizedBox(height: 8),
              Text('Description : ${widget.partDescription}'),
            ],
          ],
        ),
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