import 'package:flutter/material.dart';
import 'package:maintenance_app/services/ar_service.dart';

class ArViewerPage extends StatefulWidget {
  @override
  _ArViewerPageState createState() => _ArViewerPageState();
}

class _ArViewerPageState extends State<ArViewerPage> {
  bool _arSupported = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkArSupport();
  }

  Future<void> _checkArSupport() async {
    final supported = await ArService.checkArSupport();
    setState(() {
      _arSupported = supported;
      _loading = false;
    });
  }

  Future<void> _launchArViewer() async {
    if (_arSupported) {
      try {
        await ArService.launchArViewer('assets/models/damaged_helmet.glb');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to launch AR viewer: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AR is not supported on this device')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR Model Viewer'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: _loading
            ? CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _arSupported ? Icons.view_in_ar : Icons.error,
              size: 100,
              color: _arSupported ? Colors.green : Colors.red,
            ),
            SizedBox(height: 20),
            Text(
              _arSupported
                  ? 'AR is supported on this device'
                  : 'AR is not supported on this device',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _arSupported ? _launchArViewer : null,
              icon: Icon(Icons.view_in_ar),
              label: Text('Launch AR Viewer'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}