import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maintenance_app/services/auth_service.dart';
import 'package:maintenance_app/services/offline_manager.dart';
import 'package:maintenance_app/screens/dashboard/dashboard_screen.dart';
import 'package:maintenance_app/utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController(
      text: 'admin'
  );
  final TextEditingController _passwordController = TextEditingController(
      text: 'admin'
  );
  final TextEditingController _serverController = TextEditingController(
      text: 'http://192.168.1.71:8069'
  );
  final TextEditingController _databaseController = TextEditingController(
      text: 'odoo_cmms'
  );

  bool _isLoading = false;
  bool _rememberMe = false;
  bool _showServerSettings = false;
  bool _isOnline = true;
  bool _canLoginOffline = false;

  @override
  void initState() {
    super.initState();
    _initializeOfflineStatus();

    // Check if there's a saved session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.tryAutoLogin().then((success) {
        if (success) {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => DashboardScreen())
          );
        }
      });
    });
  }

  Future<void> _initializeOfflineStatus() async {
    final offlineManager = OfflineManager();
    final authService = Provider.of<AuthService>(context, listen: false);

    setState(() {
      _isOnline = offlineManager.isOnline;
    });

    final canOffline = await authService.canLoginOffline();
    setState(() {
      _canLoginOffline = canOffline;
    });

    // Écouter les changements de connectivité
    offlineManager.onConnectivityChanged = (isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    };
  }

  void _toggleServerSettings() {
    setState(() {
      _showServerSettings = !_showServerSettings;
    });
  }

  Future<void> _login({bool forceOffline = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.login(
        username: _usernameController.text,
        password: _passwordController.text,
        serverUrl: _serverController.text,
        database: _databaseController.text,
        rememberMe: _rememberMe,
        forceOffline: forceOffline,
      );

      if (success) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => DashboardScreen())
        );
      } else {
        String errorMessage = 'Login failed. Please check your credentials.';
        if (!_isOnline && !forceOffline) {
          errorMessage = 'No internet connection. Try offline mode or check your connection.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 40),

                  // Indicateur de statut de connexion
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isOnline ? Colors.green.shade50 : Colors.orange.shade50,
                      border: Border.all(
                        color: _isOnline ? Colors.green : Colors.orange,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isOnline ? Icons.cloud_done : Icons.cloud_off,
                          color: _isOnline ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _isOnline ? 'Connexion disponible' : 'Mode hors ligne',
                          style: TextStyle(
                            color: _isOnline ? Colors.green.shade700 : Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // App Logo
                  Center(
                    child: Icon(
                      Icons.build_circle,
                      size: 120,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: 40),

                  // App Title
                  Text(
                    'Maintenance Tracker',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  SizedBox(height: 8),

                  Text(
                    'Sign in to your account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 40),

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: validateRequired,
                  ),
                  SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: validateRequired,
                  ),
                  SizedBox(height: 8),

                  // Remember Me Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value!;
                          });
                        },
                      ),
                      Text('Remember me'),
                      Spacer(),
                      TextButton(
                        onPressed: _toggleServerSettings,
                        child: Text(_showServerSettings ? 'Hide Server Settings' : 'Server Settings'),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Server Settings
                  AnimatedCrossFade(
                    duration: Duration(milliseconds: 300),
                    crossFadeState: _showServerSettings
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Container(height: 0),
                    secondChild: Column(
                      children: [
                        TextFormField(
                          controller: _serverController,
                          decoration: InputDecoration(
                            labelText: 'Server URL',
                            border: OutlineInputBorder(),
                          ),
                          validator: validateUrl,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _databaseController,
                          decoration: InputDecoration(
                            labelText: 'Database',
                            border: OutlineInputBorder(),
                          ),
                          validator: validateRequired,
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _login(),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('LOGIN', style: TextStyle(fontSize: 16)),
                    ),
                  ),

                  // Bouton de connexion offline (si disponible et pas connecté)
                  if (!_isOnline && _canLoginOffline) ...[
                    SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _isLoading ? null : () => _login(forceOffline: true),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_off, size: 18),
                            SizedBox(width: 8),
                            Text('LOGIN OFFLINE', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (!_isOnline && !_canLoginOffline) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 24),
                          SizedBox(height: 8),
                          Text(
                            'Mode offline non disponible',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Connectez-vous une première fois en ligne pour utiliser le mode offline.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}