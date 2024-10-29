import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ValeBonoPage extends StatefulWidget {
  const ValeBonoPage({Key? key}) : super(key: key);

  @override
  State<ValeBonoPage> createState() => _ValeBonoPageState();
}

class _ValeBonoPageState extends State<ValeBonoPage> {
  final user = FirebaseAuth.instance.currentUser!;

  final _numTicket = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  final DateFormat dateFormatter = DateFormat('yyyy/MM/dd');

  String _selectedTipoServicio = ''; // Valor inicial seleccionado

  final List<String> _tiposServicio = [
    '',
    'Garantía',
    'Servicio Pagado',
    'Instalación y Capacitación',
    'Por Definir',
    'Expo',
    'Capacitación',
    'Visita a Sucursal',
    'Visita a Cliente',
    'Trabajo Especial',
  ];

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      setState(() {
        startDate = selectedDate;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      setState(() {
        endDate = selectedDate;
      });
    }
  }

  void mostrarDialogCargando(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Text('Cargando'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16.0),
              Text('Enviando datos...'),
            ],
          ),
        );
      },
    );
  }

  void cargado() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Center(
            child: Text(
              'Vale Bono',
              style: TextStyle(color: Colors.black, fontSize: 22),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
          content: const Text(
            'Vale Bono generado con éxito',
            style: TextStyle(color: Colors.black87, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: const Text(
                'Aceptar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  void errorMensaje() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Center(
            child: Text(
              'Error',
              style: TextStyle(color: Colors.black, fontSize: 22),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
          content: const Text(
            'Error al generar el Vale Bono',
            style: TextStyle(color: Colors.black87, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: const Text(
                'Aceptar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  void enviarDatos() async {
    // Convertir la firma a base64 de forma concurrente
    print('correo ${user.email!}');
    print('usuario ${user.displayName}');
    print(_numTicket.text);

    String formattedDate =
        startDate != null ? dateFormatter.format(startDate!) : 'N/A';

    String formattedDate2 =
        endDate != null ? dateFormatter.format(endDate!) : 'N/A';

    // Crear el mapa con los datos
    final jsonData = {
      'nombre_tecnico': user.displayName,
      'email_tecnico': user.email,
      'ticket': _numTicket.text,
      'fecha_inicio': formattedDate,
      'fecha_final': formattedDate2,
      'tipo_servicio': _selectedTipoServicio,
    };

    print(jsonData);

    // Convertir el mapa a una cadena JSON
    final jsonString = json.encode(jsonData);

    print(jsonString);

    // Codificar la cadena JSON en Base64
    final bytes = utf8.encode(jsonString);
    final base64String = base64.encode(bytes);

    print(base64String);

    String url =
        'https://script.google.com/macros/s/AKfycbw6LBaegyigQSTwKprr52wmyosCC-CRqImwPaifmuXRoKcrA-Fh8eHBcmS5YtCgZ7UPGw/exec';
    String api = '$url?vale=$base64String';

    final response = await http.get(Uri.parse(api));
    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];

      if (contentType != null && contentType.contains('application/json')) {
        final jsonResponse = json.decode(response.body);
        print(jsonResponse);
        if (jsonResponse["result"] == "success") {
          // ignore: use_build_context_synchronously
          Navigator.of(context, rootNavigator: true).pop();
          cargado();
        } else {
          // ignore: use_build_context_synchronously
          Navigator.of(context, rootNavigator: true).pop();
          errorMensaje();
        }
      } else {
        print('Invalid JSON response');
      }
    } else {
      print('Request failed with status: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayName = user.displayName ?? 'Desconocido';
    return Scaffold(
      appBar: AppBar(
        title: ClipRRect(
          borderRadius: BorderRadius.circular(
              4), // Ajusta el valor del radio según tus preferencias
          child: Row(
            children: [
              Container(
                color: Colors.white,
                child: Image.asset(
                  'lib/images/ar_inicio.png',
                  height: 38,
                ),
              ),
              const SizedBox(width: 10),
              const Text('Inicio'),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Text(
                        "Usuario AR: ",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        " $displayName",
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Text(
                        "Correo AR:  ",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        " ${user.email!}",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _selectStartDate(context),
                  child: TextFormField(
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Fecha de inicio',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: startDate != null
                          ? dateFormatter.format(startDate!)
                          : '',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _selectEndDate(context),
                  child: TextFormField(
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Fecha de finalización',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text:
                          endDate != null ? dateFormatter.format(endDate!) : '',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _numTicket,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[0-9]+$')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Número de ticket',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedTipoServicio,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Servicio',
                    border: OutlineInputBorder(),
                  ),
                  items: _tiposServicio.map((String tipoServicio) {
                    return DropdownMenuItem<String>(
                      value: tipoServicio,
                      child: Text(tipoServicio),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _selectedTipoServicio = newValue;
                    }
                  },
                ),
                const SizedBox(height: 14),
                FloatingActionButton.extended(
                  label: const Text('Enviar'),
                  icon: const Icon(Icons.check),
                  onPressed: () {
                    enviarDatos();
                    mostrarDialogCargando(context);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
