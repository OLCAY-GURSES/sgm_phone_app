import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'drawer_widget.dart';
import 'patient_detail_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PatientListPage extends StatefulWidget {
  @override
  _PatientListPageState createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  List<dynamic> todayAppointments = []; // List of today's appointments

  @override
  void initState() {
    super.initState();
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    try {
      final _storage = FlutterSecureStorage();
      String? token = await _storage.read(key: 'token');

      if (token != null) {
        final response = await http.get(
          //Uri.parse('http://10.0.2.2:8000/api/doctor/dashboard/'),
          Uri.parse('https://sgmlille.pythonanywhere.com/api/doctor/dashboard/'),
          headers: {'Authorization': 'Token $token'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['today_appointments'] != null && data['today_appointments'] is List) {
            setState(() {
              todayAppointments = data['today_appointments'];
            });
          } else {
            // Gérer le cas où la liste des rendez-vous est manquante ou invalide
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Aucun rendez-vous'),
                content: Text('Vous n\'avez pas de rendez-vous aujourd\'hui.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else if (response.statusCode == 401) {
          // Gérer les erreurs d'autorisation
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Erreur d\'autorisation'),
              content: Text('Vous n\'êtes pas autorisé à accéder à cette ressource'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Gérer les autres erreurs
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Erreur'),
              content: Text('Une erreur s\'est produite: ${response.statusCode} - ${response.reasonPhrase}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        // Gérer le cas où le jeton d'authentification est manquant
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Erreur'),
            content: Text('Le jeton d\'authentification est manquant'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Gérer les exceptions générales
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erreur'),
          content: Text('Une erreur s\'est produite: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Espace Docteur'),
        backgroundColor: Color(0xFF32DFFF),
      ),
      drawer: DrawerWidget(),
      body: todayAppointments.isNotEmpty
          ? ListView.builder(
        itemCount: todayAppointments.length,
        itemBuilder: (context, index) {
          final appointment = todayAppointments[index];
          final patientLastName = appointment['patient_last_name'];
          final patientFirstName = appointment['patient_first_name'];
          final patientName = '$patientLastName $patientFirstName';

          return Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Color(0xFF32DFFF),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListTile(
              onTap: () {
                // Action when the patient name is tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientDetailPage(data: appointment),
                  ),
                );
              },
              title: Text(
                patientName,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black),
              ),
            ),
          );
        },
      )
          : Center(
        child: Text('Vous n\'avez pas de rendez-vous aujourd\'hui.'),
      ),
    );
  }
}