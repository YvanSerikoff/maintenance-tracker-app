import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ARService {
  static const String AR_VIEW_TYPE = 'ar_view';

  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];

  Future<void> onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager,
      ) async {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    // Configuration de la session AR
    this.arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: "assets/triangle.png",
      showWorldOrigin: false,
      handlePans: true,
      handleRotation: true,
    );

    this.arObjectManager!.onInitialize();
  }

  Future<void> loadModel3D(String modelUrl, String partName) async {
    try {
      // Créer un nœud AR pour le modèle 3D
      var newNode = ARNode(
        type: NodeType.webGLB,
        uri: modelUrl,
        scale: vector.Vector3(0.2, 0.2, 0.2),
        position: vector.Vector3(0.0, 0.0, -0.5),
        rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0),
      );

      bool? didAddNode = await arObjectManager?.addNode(newNode);
      if (didAddNode == true) {
        nodes.add(newNode);
        print('Modèle 3D ajouté : $partName');
      }
    } catch (e) {
      print('Erreur lors du chargement du modèle 3D : $e');
    }
  }

  void dispose() {
    arSessionManager?.dispose();
  }
}