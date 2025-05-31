import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import '../services/ar_service.dart';

class ARViewerScreen extends StatefulWidget {
  final String modelUrl;
  final String partName;
  final String? partDescription;

  const ARViewerScreen({
    super.key,
    required this.modelUrl,
    required this.partName,
    this.partDescription,
  });

  @override
  ARViewerScreenState createState() => ARViewerScreenState();
}

class ARViewerScreenState extends State<ARViewerScreen> {
  late ARService arService;

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
      body: ArCoreView(
        onArCoreViewCreated: arService.onArCoreViewCreated,
        enableTapRecognizer: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          arService.loadModel3D(widget.modelUrl, widget.partName);
        },
        backgroundColor: Colors.purple,
        child: Icon(Icons.add),
      ),
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
            SizedBox(height: 16),
            Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text('1. Pointez votre caméra vers une surface plane'),
            Text('2. Touchez la surface pour placer le modèle'),
            Text('3. Utilisez le bouton + pour ajouter d\'autres modèles'),
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