import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ARService {
  ArCoreController? arCoreController;
  List<ArCoreNode> nodes = [];

  Future<void> onArCoreViewCreated(ArCoreController controller) async {
    arCoreController = controller;
    arCoreController!.onNodeTap = (name) => onTapHandler(name);
    arCoreController!.onPlaneTap = _handleOnPlaneTap;
  }

  void _handleOnPlaneTap(List<ArCoreHitTestResult> hits) {
    final hit = hits.first;
    _addModel3D(hit);
  }

  void _addModel3D(ArCoreHitTestResult hit) {
    final node = ArCoreNode(
      shape: ArCoreSphere(
        materials: [
          ArCoreMaterial(
            color: Colors.blue,
            metallic: 0.0,
            roughness: 0.5,
          ),
        ],
        radius: 0.1,
      ),
      position: hit.pose.translation + vector.Vector3(0.0, 0.1, 0.0),
    );
    arCoreController!.addArCoreNode(node);
    nodes.add(node);
  }

  Future<void> loadModel3D(String modelUrl, String partName) async {
    // Pour les modèles 3D, vous devrez utiliser ArCoreReferenceNode
    // avec des modèles .sfb (format Sceneform)
    final node = ArCoreReferenceNode(
      name: partName,
      objectUrl: modelUrl, // Doit être un fichier .sfb
      position: vector.Vector3(0, 0, -1),
      scale: vector.Vector3(0.2, 0.2, 0.2),
    );

    if (arCoreController != null) {
      arCoreController!.addArCoreNodeWithAnchor(node);
      nodes.add(node);
    }
  }

  void onTapHandler(String nodeName) {
    print('Nœud touché: $nodeName');
  }

  void dispose() {
    arCoreController?.dispose();
  }
}