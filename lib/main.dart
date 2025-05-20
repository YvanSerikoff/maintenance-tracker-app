import 'package:flutter/material.dart';
import 'package:maintenance_app/services/flutter_basic_auth.dart';
import 'package:provider/provider.dart';
import 'package:maintenance_app/config/theme.dart';
import 'package:maintenance_app/services/auth_service.dart';
import 'package:maintenance_app/screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider<CMMSApiService>(create: (_) => CMMSApiService(baseUrl: 'http://192.168.1.71:8069', username: 'admin', password: 'admin')),
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
    );
  }
}