import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maintenance_app/services/auth_service.dart';
import 'package:maintenance_app/config/constants.dart';
import 'package:maintenance_app/screens/auth/login_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkMode = false;
  bool _isNotificationsEnabled = true;
  bool _isLoading = false;
  String _appVersion = '';
  String _buildNumber = '';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppInfo();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool(AppConstants.KEY_DARK_MODE) ?? false;
      _isNotificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }
  
  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      print('Error loading app info: $e');
      setState(() {
        _appVersion = '1.0.0';
        _buildNumber = '1';
      });
    }
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.KEY_DARK_MODE, _isDarkMode);
    await prefs.setBool('notifications_enabled', _isNotificationsEnabled);
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearStoredCredentials() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.clearStoredCredentials();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stored credentials cleared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing credentials: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openSupportWebsite() async {
    Uri uri = Uri.parse('https://support.your-company.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open support website'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendSupportEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@your-company.com',
      query: 'subject=Maintenance App Support Request&body=App Version: $_appVersion (Build $_buildNumber)\n\n',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open email client'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userName = authService.userName ?? 'User';
    final userEmail = authService.userEmail ?? 'No email provided';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              userName[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            userName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          SizedBox(height: 8),
                          Text(
                            userEmail,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Technician',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  // Navigate to edit profile screen
                                  // For now, just show a snackbar
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Edit profile coming soon!'),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.edit),
                                label: Text('Edit Profile'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  
                  // Settings Cards
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text('Dark Mode'),
                          subtitle: Text('Enable dark theme'),
                          value: _isDarkMode,
                          secondary: Icon(Icons.brightness_4),
                          onChanged: (value) {
                            setState(() {
                              _isDarkMode = value;
                            });
                            _saveSettings();
                            
                            // Show message that restart is required
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Restart app to apply theme changes'),
                              ),
                            );
                          },
                        ),
                        Divider(),
                        SwitchListTile(
                          title: Text('Notifications'),
                          subtitle: Text('Enable push notifications'),
                          value: _isNotificationsEnabled,
                          secondary: Icon(Icons.notifications),
                          onChanged: (value) {
                            setState(() {
                              _isNotificationsEnabled = value;
                            });
                            _saveSettings();
                          },
                        ),
                        Divider(),
                        ListTile(
                          leading: Icon(Icons.language),
                          title: Text('Language'),
                          subtitle: Text('English'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // Navigate to language selection
                            // For now, just show a snackbar
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Language settings coming soon!'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  
                  // Account Cards
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.security),
                          title: Text('Change Password'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // Navigate to change password screen
                            // For now, just show a snackbar
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Change password coming soon!'),
                              ),
                            );
                          },
                        ),
                        Divider(),
                        ListTile(
                          leading: Icon(Icons.delete_forever),
                          title: Text('Clear Stored Credentials'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _clearStoredCredentials,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  Text(
                    'Support',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  
                  // Support Cards
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.help),
                          title: Text('Help Center'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _openSupportWebsite,
                        ),
                        Divider(),
                        ListTile(
                          leading: Icon(Icons.email),
                          title: Text('Contact Support'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _sendSupportEmail,
                        ),
                        Divider(),
                        ListTile(
                          leading: Icon(Icons.info),
                          title: Text('About'),
                          subtitle: Text('Version $_appVersion (Build $_buildNumber)'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'Maintenance Tracker',
                              applicationVersion: 'Version $_appVersion (Build $_buildNumber)',
                              applicationIcon: Image.asset('assets/images/logo.png', height: 50),
                              children: [
                                SizedBox(height: 16),
                                Text('Maintenance Tracker allows technicians to manage and complete maintenance tasks efficiently.'),
                                SizedBox(height: 16),
                                Text('© ${DateTime.now().year} Your Company Name'),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Logout Button
                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: Icon(Icons.logout),
                    label: Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Copyright text
                  Center(
                    child: Text(
                      '© ${DateTime.now().year} Maintenance Tracker App',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Last updated: 2025-05-18',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}