import 'package:flutter/material.dart';
import 'package:maintenance_app/services/flutter_basic_auth.dart';
import 'package:maintenance_app/services/offline_manager.dart';
import 'package:provider/provider.dart';
import 'package:maintenance_app/config/theme.dart';
import 'package:maintenance_app/services/auth_service.dart';
import 'package:maintenance_app/screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le gestionnaire offline
  await OfflineManager().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider<CMMSApiService>(
            create: (_) => CMMSApiService(
                baseUrl: 'http://192.168.1.71:8069',
                username: 'admin',
                password: 'admin'
            )
        ),
        // Ajouter le OfflineManager comme provider pour un accès global
        Provider<OfflineManager>(create: (_) => OfflineManager()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maintenance Tracker',
      theme: appTheme,
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
      // Ajouter un builder global pour gérer les erreurs de connectivité
      builder: (context, child) {
        return Consumer<OfflineManager>(
          builder: (context, offlineManager, _) {
            return Scaffold(
              body: child,
              // Optionnel : ajouter une bannière globale pour le statut offline
              bottomSheet: !offlineManager.isOnline ? _buildOfflineBanner() : null,
            );
          },
        );
      },
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade700,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mode hors ligne - Les données seront synchronisées automatiquement',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}