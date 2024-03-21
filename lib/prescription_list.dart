import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:core';
import 'package:intl/date_symbol_data_local.dart';
import 'drawer_widget.dart';

class PrescriptionList extends StatefulWidget {
  final int patientId;

  const PrescriptionList({required this.patientId});

  @override
  _PrescriptionListState createState() => _PrescriptionListState();
}

class _PrescriptionListState extends State<PrescriptionList> {
  List<dynamic> prescriptions = [];

  @override
  void initState() {
    super.initState();
    fetchPrescriptions();
  }

  Future<void> fetchPrescriptions() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token != null) {
      final response = await http.get(
        //Uri.parse('http://10.0.2.2:8000/api/patient/profile/${widget.patientId}/'),
        Uri.parse('https://sgmlille.pythonanywhere.com/api/patient/profile/${widget.patientId}/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        List<dynamic> tempPrescriptions = [];

        for (var prescriptionJson in jsonResponse['prescription']) {
          if (prescriptionJson['patient']['patient_id'] == widget.patientId) {
            tempPrescriptions.add(prescriptionJson);
          }
        }

        if (tempPrescriptions.isEmpty) {
          // Pas de prescription pour ce patient
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Aucune prescription'),
              content: Text('Aucune prescription n\'a été trouvée pour ce patient.'),
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
        } else {
          setState(() {
            prescriptions = tempPrescriptions;
          });
        }
      }
    }
  }

  String formatDate(String date) {
    final parsedDate = DateTime.parse(date);
    final formattedDate =
        "${parsedDate.day.toString().padLeft(2, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.year.toString()}";
    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Les Prescriptions'),
        backgroundColor: Color(0xFF32DFFF),
      ),
      drawer: DrawerWidget(),
      body: Container(
        color: Colors.white,
        child: ListView.builder(
          itemCount: prescriptions.length,
          itemBuilder: (context, index) {
            final prescription = prescriptions[index];
            final prescriptionId = prescription['prescription_id'];
            final createDate = prescription['create_date'];
            final prescriptionMedicines = prescription['prescription_medicines'];
            final prescriptionTests = prescription['prescription_test'];
            final extraInformation = prescription['extra_information'];

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PrescriptionDetails(
                      prescription: prescription,
                      prescriptionMedicines: prescriptionMedicines,
                      prescriptionTests: prescriptionTests.cast<Map<String, dynamic>>(), // Conversion de la liste
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF32DFFF)),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prescription: $prescriptionId',
                      style: TextStyle(color: Colors.black),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Date: ${formatDate(createDate)}',
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class PrescriptionDetails extends StatefulWidget {
  final Map<String, dynamic> prescription;
  final List<dynamic> prescriptionMedicines;
  final List<dynamic> prescriptionTests;

  const PrescriptionDetails({
    required this.prescription,
    required this.prescriptionMedicines,
    required this.prescriptionTests,
  });

  @override
  _PrescriptionDetailsState createState() => _PrescriptionDetailsState();
}

class _PrescriptionDetailsState extends State<PrescriptionDetails> {
  DateTime? selectedEndDate;
  final Map<int, DateTime?> updatedEndDates = {};

  Future<DateTime?> _selectEndDate(BuildContext context, int index, int medicineId) async {
    await initializeDateFormatting('fr', null);

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: Locale('fr', 'FR'),
    );

    if (selectedDate != null) {
      setState(() {
        selectedEndDate = selectedDate;
        updatedEndDates[medicineId] = selectedDate;
      });
    }

    return selectedDate;
  }

  Future<void> _submitUpdatedEndDates() async {
    final prefs = await SharedPreferences.getInstance();
    //final authToken = prefs.getString('auth_token');
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      // Le jeton n'est pas stocké, gérez cette erreur comme vous le souhaitez
      return;
    }

    if (token != null) {
      for (var entry in updatedEndDates.entries) {
        final medicineId = entry.key;
        final updatedEndDate = entry.value;

        if (updatedEndDate != null) {
          final prescriptionId = widget.prescription['prescription_id'];
          final updatedEndDateString = updatedEndDate.toIso8601String().split('T')[0];
          final response = await http.put(
            //Uri.parse('http://10.0.2.2:8000/api/prescriptions/$prescriptionId/medicines/$medicineId/end_date/'),
            Uri.parse('https://sgmlille.pythonanywhere.com/api/prescriptions/$prescriptionId/medicines/$medicineId/end_date/'),
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'end_day': updatedEndDateString,
            }),
          );

          if (response.statusCode == 200) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Succès'),
                content: Text('Modifications de la date de fin enregistrées.'),
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
          } else {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Erreur'),
                content: Text('Une erreur s\'est produite lors de la mise à jour de la date de fin.'),
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
      }
    }
  }

  Widget buildTextContainer(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFF32DFFF)),
        borderRadius: BorderRadius.circular(5),
        color: Colors.white,
      ),
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.prescription['doctor'];
    final patient = widget.prescription['patient'];
    final createDate = widget.prescription['create_date'];
    final extraInformation = widget.prescription['extra_information'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Prescription'),
        backgroundColor: Color(0xFF32DFFF),

      ),
      body: Container(
        color: Colors.white,
        margin: EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF32DFFF)),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    Text(
                      'Docteur: ${doctor['first_name']} ${doctor['last_name']}',
                      style: TextStyle(color: Colors.black),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Patient: ${patient['first_name']} ${patient['last_name']}',
                      style: TextStyle(color: Colors.black),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Date de la prescription: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(createDate))}',
                      style: TextStyle(color: Colors.black),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF32DFFF)),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    Text(
                      'Avis: $extraInformation',
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF32DFFF)),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prescription Médicament:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.prescriptionMedicines.length,
                      itemBuilder: (context, index) {
                        final medicine = widget.prescriptionMedicines[index];
                        final medicineName = medicine['medicine_name'];
                        final quantity = medicine['quantity'];
                        final dosage = medicine['dosage'];
                        final startDay = medicine['start_day'];
                        final endDay = medicine['end_day'];
                        final frequency = medicine['frequency'];
                        final instruction = medicine['instruction'];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Color(0xFF32DFFF)),
                                  borderRadius: BorderRadius.circular(5),
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Médicament: $medicineName',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Color(0xFF32DFFF)),
                                  borderRadius: BorderRadius.circular(5),
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Quantité: $quantity',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Color(0xFF32DFFF)),
                                  borderRadius: BorderRadius.circular(5),
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Dosage: $dosage',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Color(0xFF32DFFF)),
                                  borderRadius: BorderRadius.circular(5),
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Date de début: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(startDay))}',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Color(0xFF32DFFF)),
                                  borderRadius: BorderRadius.circular(5),
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.all(8),
                                child: GestureDetector(
                                  onTap: () async {
                                    final selectedDate = await _selectEndDate(context, index, medicine['medicine_id']);
                                    if (selectedDate != null) {
                                      final selectedEndDate = selectedDate.toString();
                                      setState(() {
                                        widget.prescriptionMedicines[index]['end_day'] = selectedEndDate;
                                      });
                                    }
                                  },
                                  child: Text(
                                    'Date de fin: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(endDay))}',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Color(0xFF32DFFF)),
                                  borderRadius: BorderRadius.circular(5),
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Fréquence: $frequency',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Color(0xFF32DFFF)),
                                  borderRadius: BorderRadius.circular(5),
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Instructions: $instruction',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF32DFFF)),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prescription Tests:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.prescriptionTests.length,
                      itemBuilder: (context, index) {
                        final test = widget.prescriptionTests[index];
                        final testName = test['test_name'];
                        final testDescription = test['test_description'];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Color(0xFF32DFFF)),
                                  borderRadius: BorderRadius.circular(5),
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Test: $testName',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Description: $testDescription',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _submitUpdatedEndDates,
        backgroundColor: Color(0xFF32DFFF),
        child: Icon(Icons.save, color: Colors.white),
      ),
    );
  }
}