import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import 'drawer_widget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'prescription_list.dart';
import 'package:intl/intl.dart';





class PatientDetailPage extends StatelessWidget {
  final dynamic data;


  PatientDetailPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final patientId = data['patient_id'];
    final patientFirstName = data['patient_first_name'];
    final patientLastName = data['patient_last_name'];
    final patientPhoneNumber = data['patient_phone_number'];
    final patientAddress = data['patient_address'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Dossier médical du patient'),
        backgroundColor: Color(0xFF32DFFF),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Color(0xFF32DFFF),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListTile(
              title: Text('Prénom'),
              subtitle: Text(patientFirstName),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Color(0xFF32DFFF),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListTile(
              title: Text('Nom'),
              subtitle: Text(patientLastName),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Color(0xFF32DFFF),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListTile(
              title: Text('Numéro de contact'),
              subtitle: Text(patientPhoneNumber),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Color(0xFF32DFFF),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListTile(
              title: Text('Adresse'),
              subtitle: Text(patientAddress),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Color(0xFF32DFFF),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListTile(
              title: Text('Motif'),
              subtitle: Text(data['motif']),
            ),
          ),

        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrescriptionList(patientId: patientId),
                ),
              );
            },
            backgroundColor: Color(0xFF32DFFF),
            child: Icon(Icons.visibility, color: Colors.white),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPrescriptionPage(patientId: patientId),
                ),
              );
            },
            backgroundColor: Color(0xFF32DFFF),
            child: Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class AddPrescriptionPage extends StatefulWidget {
  final int patientId;

  AddPrescriptionPage({required this.patientId});

  @override
  _AddPrescriptionPageState createState() => _AddPrescriptionPageState();
}

class _AddPrescriptionPageState extends State<AddPrescriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  List<Map<String, dynamic>> _medicineData = [];
  List<Map<String, dynamic>> _testData = [];
  String _extraInformation = '';

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Construire le prescriptionData à partir des variables d'état
      final prescriptionData = {
        'prescription_test': _testData,
        'prescription_medicines': _medicineData,
        'extra_information': _extraInformation,
      };

      // Vérifier si le patient existe
      final patientExists = await checkPatientExists(widget.patientId);
      if (!patientExists) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Erreur'),
            content: Text('Le patient n\'existe pas.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Créer la prescription
      final prescriptionCreated =
      await createPrescription(widget.patientId, prescriptionData);
      if (!prescriptionCreated) {
        return showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Erreur'),
            content: Text(
                'Une erreur s\'est produite lors de la création de la prescription.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }

      // Afficher un message de succès
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Succès'),
          content: Text('La prescription a été créée avec succès.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
        title: Text('Ajouter une prescription'),
        backgroundColor: Color(0xFF32DFFF),
      ),
      drawer: DrawerWidget(),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Champs pour les médicaments
              ...buildMedicineFields(),

              // Champs pour les tests
              ...buildTestFields(),

              // Champ pour les informations supplémentaires
              Card(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Color(0xFF32DFFF),
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                      left: 16.0), // Décalage du contenu du Card vers la droite
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText:
                      'Avis', // Pas de décalage pour le labelText
                      labelStyle: TextStyle(
                          color: Colors
                              .grey[600]), // Couleur du labelText
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Veuillez entrer des informations supplémentaires';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _extraInformation = value!;
                    },
                  ),
                ),
              ),

              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  foregroundColor:
                  Colors.white, backgroundColor: Color(0xFF32DFFF), // Couleur de la police
                ),
                child: Text('Soumettre'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> buildMedicineFields() {
    return [
    // Champs pour les médicaments
    ...(_medicineData.map((medicineData) => Column(
    crossAxisAlignment: CrossAxisAlignment
        .end, // Alignement à droite
    children: [
    Card(
    shape: RoundedRectangleBorder(
    side: BorderSide(
    color: Color(0xFF32DFFF),
    width: 2.0,
    ),
    borderRadius: BorderRadius.circular(8.0),
    ),
    child: TextFormField(
    initialValue: medicineData['medicine_name'] ?? '',
    decoration: InputDecoration(
    labelText: 'Nom du médicament',
    contentPadding:
    EdgeInsets.symmetric(horizontal: 16.0), // Décalage du curseur
    ),
    validator: (value) {
    if (value!.isEmpty) {
    return 'Veuillez entrer le nom du médicament';
    }
    return null;
    },
    onSaved: (value) {
    medicineData['medicine_name'] = value!;
    },
    ),
    ),
    Card(
    shape: RoundedRectangleBorder(
    side: BorderSide(
    color: Color(0xFF32DFFF),
    width: 2.0,
    ),
    borderRadius: BorderRadius.circular(8.0),
    ),
    child: TextFormField(
    initialValue: medicineData['quantity'] ?? '',
    decoration: InputDecoration(
    labelText: 'Quantité',
    contentPadding:
    EdgeInsets.symmetric(horizontal: 16.0), // Décalage du curseur
    ),
    validator: (value) {
    if (value!.isEmpty) {
    return 'Veuillez entrer la quantité';
    }
    return null;
    },
    onSaved: (value) {
    medicineData['quantity'] = value!;
    },
    ),
    ),
    Card(
    shape: RoundedRectangleBorder(
    side: BorderSide(
    color: Color(0xFF32DFFF),
    width: 2.0,
    ),
    borderRadius: BorderRadius.circular(8.0),
    ),
    child: TextFormField(
    controller: _startDateController,
    decoration: InputDecoration(
    labelText: 'Date de début (jj/mm/aaaa)',
    contentPadding:
    EdgeInsets.symmetric(horizontal: 16.0),
    ),
    validator: (value) {
    if (value!.isEmpty) {
    return 'Veuillez entrer la date de début';
    }
    return null;
    },
    onTap: () async {
    DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: Locale('fr', 'FR'),
    );

    if (pickedDate != null) {
      String formattedDate =
      DateFormat('dd/MM/yyyy').format(pickedDate);
      _startDateController.text = formattedDate;
      medicineData['start_day'] = formattedDate;
    }
    },
    ),
    ),
      Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Color(0xFF32DFFF),
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: TextFormField(
          controller: _endDateController,
          decoration: InputDecoration(
            labelText: 'Date de fin (jj/mm/aaaa)',
            contentPadding:
            EdgeInsets.symmetric(horizontal: 16.0),
          ),
          validator: (value) {
            if (value!.isEmpty) {
              return 'Veuillez entrer la date de fin';
            }
            return null;
          },
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              locale: Locale('fr', 'FR'),
            );

            if (pickedDate != null) {
              String formattedDate =
              DateFormat('dd/MM/yyyy').format(pickedDate);
              _endDateController.text = formattedDate;
              medicineData['end_day'] = formattedDate;
            }
          },
        ),
      ),
      Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Color(0xFF32DFFF),
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: TextFormField(
          initialValue: medicineData['frequency'] ?? '',
          decoration: InputDecoration(
            labelText: 'Fréquence',
            contentPadding:
            EdgeInsets.symmetric(horizontal: 16.0), // Décalage du curseur
          ),
          validator: (value) {
            if (value!.isEmpty) {
              return 'Veuillez entrer la fréquence';
            }
            return null;
          },
          onSaved: (value) {
            medicineData['frequency'] = value!;
          },
        ),
      ),
      Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Color(0xFF32DFFF),
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: TextFormField(
          initialValue: medicineData['dosage'] ?? '',
          decoration: InputDecoration(
            labelText: 'Dosage',
            contentPadding:
            EdgeInsets.symmetric(horizontal: 16.0), // Décalage du curseur
          ),
          validator: (value) {
            if (value!.isEmpty) {
              return 'Veuillez entrer le dossage';
            }
            return null;
          },
          onSaved: (value) {
            medicineData['dosage'] = value!;
          },
        ),
      ),
      Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Color(0xFF32DFFF),
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: TextFormField(
          initialValue: medicineData['instruction'] ?? '',
          decoration: InputDecoration(
            labelText: 'Instructions',
            contentPadding:
            EdgeInsets.symmetric(horizontal: 16.0), // Décalage du curseur
          ),
          validator: (value) {
            if (value!.isEmpty) {
              return 'Veuillez entrer les instructions';
            }
            return null;
          },
          onSaved: (value) {
            medicineData['instruction'] = value!;
          },
        ),
      ),
    ],
    ))).toList(),
      ElevatedButton(
        onPressed: () {
          setState(() {
            _medicineData.add({});
          });
        },
        style: ElevatedButton.styleFrom(
          foregroundColor:
          Colors.white, backgroundColor: Color(0xFF32DFFF), // Couleur de la police
        ),
        child: Text('Ajouter un médicament'),
      ),
    ];
  }

  List<Widget> buildTestFields() {
    return [
      // Champs pour les tests
      ...(_testData.map((testData) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Color(0xFF32DFFF),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: TextFormField(
              initialValue: testData['test_name'] ?? '',
              decoration: InputDecoration(
                labelText: 'Nom du test',
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Veuillez entrer le nom du test';
                }
                return null;
              },
              onSaved: (value) {
                testData['test_name'] = value!;
              },
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Color(0xFF32DFFF),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: TextFormField(
              initialValue: testData['test_description'] ?? '',
              decoration: InputDecoration(
                labelText: 'Description',
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Veuillez entrer la date du test';
                }
                return null;
              },
              onSaved: (value) {
                testData['test_description'] = value!;
              },
            ),
          ),
        ],
      ))).toList(),
      ElevatedButton(
        onPressed: () {
          setState(() {
            _testData.add({});
          });
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Color(0xFF32DFFF),
        ),
        child: Text('Ajouter un test'),
      ),
    ];
  }
}


Future<bool> checkPatientExists(int patientId) async {
  final storage = FlutterSecureStorage();
  final authToken = await storage.read(key: 'token');

  if (authToken == null) {
    // Le jeton n'est pas stocké, gérez cette erreur comme vous le souhaitez
    return false;
  }

  //final url = Uri.parse('http://10.0.2.2:8000/api/patients/$patientId/');
  final url = Uri.parse('https://sgmlille.pythonanywhere.com/api/patients/$patientId/');
  final headers = {
    'Authorization': 'Token $authToken',
  };

  try {
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}

Future<bool> createPrescription(int patientId, Map<String, dynamic> prescriptionData) async {
  final storage = FlutterSecureStorage();
  final authToken = await storage.read(key: 'token');

  if (authToken == null) {
    // Le jeton n'est pas stocké, gérez cette erreur comme vous le souhaitez
    return false;
  }

  //final url = Uri.parse('http://10.0.2.2:8000/api/prescriptions/create/$patientId/');
  final url = Uri.parse('https://sgmlille.pythonanywhere.com/api/prescriptions/create/$patientId/');
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Token $authToken',
  };
  final body = jsonEncode(prescriptionData);

  try {
    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 201) {
      return true;
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}