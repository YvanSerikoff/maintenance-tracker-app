import 'package:flutter/material.dart';
import 'package:maintenance_app/services/offline_manager.dart';

class OfflineIndicator extends StatefulWidget {
  @override
  _OfflineIndicatorState createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  final OfflineManager _offlineManager = OfflineManager();
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _isOnline = _offlineManager.isOnline;

    _offlineManager.onConnectivityChanged = (isOnline) {
      // CORRECTION : Vérifier si le widget est encore monté avant setState
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    };
  }

  @override
  void dispose() {
    _offlineManager.onConnectivityChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade700,
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            'Mode hors ligne - Les modifications seront synchronisées',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}