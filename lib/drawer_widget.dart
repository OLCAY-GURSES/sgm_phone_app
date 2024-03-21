import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'patient_detail_page.dart';


class DrawerWidget extends StatefulWidget {
  @override
  _DrawerWidgetState createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  bool isLoading = false;
  bool isRefreshing = false;
  int? unreadNotificationCount;

  @override
  void initState() {
    super.initState();
    fetchUnreadNotificationCount();
  }

  Future<void> fetchUnreadNotificationCount() async {
    setState(() {
      isLoading = true;
    });

    final _storage = FlutterSecureStorage();
    String? token = await _storage.read(key: 'token');

    if (token != null) {
      final response = await http.get(
        Uri.parse('https://sgmlille.pythonanywhere.com/api/doctor/dashboard/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          unreadNotificationCount = jsonResponse['unread_notification_count'];
          isLoading = false;
          isRefreshing = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  Future<void> refreshData() async {
    setState(() {
      isRefreshing = true;
    });
    await fetchUnreadNotificationCount();
    await refreshPatientList();
  }

  Future<void> refreshPatientList() async {
    Navigator.pushReplacementNamed(context, '/doctor-dashboard');
  }

  Future<void> logout(BuildContext context) async {
    final _storage = FlutterSecureStorage();
    await _storage.delete(key: 'token');
    Navigator.pushReplacementNamed(context, '/');
  }

  void navigateToDoctorDashboard(BuildContext context) {
    Navigator.pushNamed(context, '/doctor-dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF32DFFF),
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Tableau de bord du médecin'),
            onTap: () => navigateToDoctorDashboard(context),
          ),
          ListTile(
            leading: RotatedBox(
              quarterTurns: isRefreshing ? 1 : 0,
              child: Icon(Icons.refresh),
            ),
            title: Text('Notifications'),
            trailing: isLoading
                ? CircularProgressIndicator()
                : unreadNotificationCount != null && unreadNotificationCount! > 0
                ? Text(
              '$unreadNotificationCount',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
            onTap: () {
              refreshData();
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Déconnexion'),
            onTap: () => logout(context),
          ),
          // Ajoutez d'autres éléments de menu ici si nécessaire
        ],
      ),
    );
  }
}