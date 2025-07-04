import 'package:flutter/material.dart';
import 'package:maintenance_app/screens/tasks/task_list_screen.dart';
import 'package:maintenance_app/services/flutter_basic_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maintenance_app/services/auth_service.dart';
import 'package:maintenance_app/config/constants.dart';
import 'package:maintenance_app/screens/auth/login_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:maintenance_app/widgets/app_bottom_nav_bar.dart';

import '../models/user.dart';
import 'dashboard/dashboard_screen.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isTablet = screenWidth > 700;
    final horizontalPadding = isSmallScreen ? 8.0 : (isTablet ? 32.0 : 16.0);
    final cardPadding = isSmallScreen ? 10.0 : 20.0;
    final avatarRadius = isSmallScreen ? 30.0 : 40.0;
    final nameFontSize = isSmallScreen ? 16.0 : 20.0;
    final emailFontSize = isSmallScreen ? 12.0 : 14.0;
    final sectionTitleFontSize = isSmallScreen ? 15.0 : 18.0;
    final buttonFontSize = isSmallScreen ? 14.0 : 16.0;
    final buttonHeight = isSmallScreen ? 40.0 : 50.0;
    final copyrightFontSize = isSmallScreen ? 10.0 : 12.0;
    final updateFontSize = isSmallScreen ? 10.0 : 12.0;
    final authService = Provider.of<AuthService>(context);
    final userName = authService.userName ?? 'User';
    final userEmail = authService.userEmail ?? 'No email provided';
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(fontSize: isSmallScreen ? 16 : 20)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte profil modernisée
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(cardPadding),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            userName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: avatarRadius,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          userName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: nameFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: emailFontSize,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Technician',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  // Section Paramètres
                  Text('Parameters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: sectionTitleFontSize, color: Colors.grey.shade800)),
                  SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 16)),
                    elevation: 2,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text('Dark theme'),
                          subtitle: Text('Activate dark mode'),
                          value: _isDarkMode,
                          secondary: Icon(Icons.brightness_4),
                          onChanged: (value) {
                            setState(() {
                              _isDarkMode = value;
                            });
                            _saveSettings();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Reboot the app to apply changes'),
                              ),
                            );
                          },
                        ),
                        Divider(),
                        SwitchListTile(
                          title: Text('Notifications'),
                          subtitle: Text('Activate push notifications'),
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
                          subtitle: Text('English (en)'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Language parameters are not yet implemented'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  // Section Compte
                  Text('Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: sectionTitleFontSize, color: Colors.grey.shade800)),
                  SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 16)),
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.security),
                          title: Text('Change Password'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Changing password is not yet implemented'),
                              ),
                            );
                          },
                        ),
                        Divider(),
                        ListTile(
                          leading: Icon(Icons.delete_forever),
                          title: Text('Erase Stored Credentials'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _clearStoredCredentials,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  // Section Support
                  Text('Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: sectionTitleFontSize, color: Colors.grey.shade800)),
                  SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 16)),
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.help),
                          title: Text('Centre d\'aide'),
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
                                Text('Maintenance Tracker allows you to manage your maintenance tasks efficiently.'),
                                SizedBox(height: 16),
                                Text('© ${DateTime.now().year} Your Company Name'),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  // Bouton de déconnexion
                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: Icon(Icons.logout),
                    label: Text('Disconnect', style: TextStyle(fontSize: buttonFontSize)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, buttonHeight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12)),
                      textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: buttonFontSize),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  Center(
                    child: Text(
                      '© ${DateTime.now().year} Maintenance Tracker App',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: copyrightFontSize,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Last updated : 2025-05-18',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: updateFontSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 2),
    );
  }
}
