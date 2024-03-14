import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DrawerWidget extends StatefulWidget {
  @override
  _DrawerWidgetState createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  Future<void> logout(BuildContext context) async {
    final _storage = FlutterSecureStorage();
    await _storage.delete(key: 'token');
    // Naviguer vers la page d'accueil après la déconnexion
    Navigator.pushReplacementNamed(context, '/');
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