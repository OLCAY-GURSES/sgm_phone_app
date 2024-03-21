import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class LoginPage extends StatelessWidget {
  final storage = FlutterSecureStorage();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> login(BuildContext context) async {
    final String username = usernameController.text;
    final String password = passwordController.text;

    final response = await http.post(
      //Uri.parse('http://10.0.2.2:8000/api/api-token-auth/'),
      Uri.parse('https://sgmlille.pythonanywhere.com/api/api-token-auth/'),
      body: {

        'username': username,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final token = responseData['token'];
      final isDoctor = responseData['is_doctor'];
      final doctorId = responseData['doctor_id']; // Récupérer l'ID du docteur

      await storage.write(key: 'token', value: token);
      await storage.write(key: 'doctor_id', value: doctorId.toString()); // Stocker l'ID du docteur

      await storage.write(key: 'token', value: token);
      //print(token);
      //print('Hello');
      print(doctorId);

      if (isDoctor) {
        // Rediriger vers la page des docteurs
        Navigator.pushReplacementNamed(context, '/doctor-dashboard');
      } else {
        // Afficher un message d'erreur pour les autres utilisateurs
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Accès non autorisé'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Affichez un SnackBar avec le message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec de la connexion : verifier votre email ou votre mot de passe'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Supprime le bouton de retour
      ),
      body: Column(
        children: [
          SizedBox(height: 20.0),
          Container(
            alignment: Alignment.topCenter,
            child: Image.asset(
              'lib/media/img.png',
              width: 200,
              height: 200,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Se connecter',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 16.0),
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: 'Nom d\'utilisateur',
                        labelStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF32DFFF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF32DFFF)),
                        ),
                      ),
                      style: TextStyle(color: Colors.black),
                    ),
                    SizedBox(height: 16.0),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        labelStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF32DFFF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF32DFFF)),
                        ),
                      ),
                      obscureText: true,
                      style: TextStyle(color: Colors.black),
                    ),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () => login(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF32DFFF),
                      ),
                      child: Text('Connexion', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

  }
}