import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maintenance_app/services/auth_service.dart';
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

  @override
  void initState() {
    super.initState();
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

  void _toggleServerSettings() {
    setState(() {
      _showServerSettings = !_showServerSettings;
    });
  }

  Future<void> _login() async {
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
      );

      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DashboardScreen())
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed. Please check your credentials.'),
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 24),
                    // Logo modernisé
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(16),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 90,
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    // Titre
                    Text(
                      'Maintenance Tracker',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Connect to your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 32),
                    // Carte de connexion
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 6,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Champ utilisateur
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
                            // Champ mot de passe
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
                            SizedBox(height: 12),
                            // Checkbox + bouton paramètres serveur
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
                                Text('Remember Me', style: TextStyle(color: Colors.black87)),
                                Spacer(),
                                TextButton(
                                  onPressed: _toggleServerSettings,
                                  child: Text(_showServerSettings ? 'Hide' : 'Parameter'),
                                ),
                              ],
                            ),
                            // Paramètres serveur
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
                            SizedBox(height: 16),
                            // Bouton connexion
                            ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text('CONNEXION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    // Copyright
                    Center(
                      child: Text(
                        '© ${DateTime.now().year} Maintenance Tracker',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

