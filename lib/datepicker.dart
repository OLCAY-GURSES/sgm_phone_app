import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePicker extends StatefulWidget {
  @override
  _DatePickerState createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  String endDay = '';

  Future<void> _selectEndDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(endDay),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        endDay = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Modifier la date'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          _selectEndDate(context); // Appeler la méthode pour ouvrir le picker de date
                          Navigator.pop(context); // Fermer la boîte de dialogue après la sélection de la date
                        },
                        child: SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Fin de traitement: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(endDay))}',
                                ),
                                Icon(Icons.edit), // Remplacez l'icône par celle de votre choix
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: SizedBox(
            height: 8,
          ),
        ),
      ],
    );
  }
}