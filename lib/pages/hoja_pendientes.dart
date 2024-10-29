import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity/connectivity.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HojaPendientes extends StatefulWidget {
  const HojaPendientes({Key? key}) : super(key: key);

  @override
  State<HojaPendientes> createState() => _HojaPendientesState();
}

class _HojaPendientesState extends State<HojaPendientes> {
  final user = FirebaseAuth.instance.currentUser!;

  final _formKey = GlobalKey<FormState>();

  List data = [];
  // Initial Selected Value
  String? dropdownValue = '------------ ticket ------------';
  // List of items in our dropdown menu
  Set<String> tickets = {};
  //Bandera solo una vez
  bool primeraVez = false;
  bool paginaSiCargo = false;
  bool guardandoDatos = false;

  bool _hasInternet = true;

  late DateTime? selectedDate;
  final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
  final TextEditingController dateController = TextEditingController();

  final TextEditingController _tituloPendienteController =
      TextEditingController();

  String idTicket = "";

  final TextEditingController _pendientesController = TextEditingController();

  String _selectedArea = ''; // Valor inicial seleccionado

  final List<String> _area = [
    '',
    'Soporte Telefónico',
    'Soporte Presencial',
    'Garantías',
    'Ventas de Refacciones y Servicios',
  ];

  void cargado() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Center(
            child: Text(
              'Pendiente Cargado',
              style: TextStyle(color: Colors.black, fontSize: 22),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
          content: const Text(
            'Se subió a ZOHO con éxito',
            style: TextStyle(color: Colors.black87, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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

  void _submitForm() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _hasInternet = (connectivityResult != ConnectivityResult.none);
    });

    if (!_hasInternet) {
      Fluttertoast.showToast(
        msg: 'No hay conexión a Internet',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
    }

    if (_formKey.currentState!.validate() && _hasInternet) {
      // Formulario válido, realiza la acción deseada
      _formKey.currentState!.save();
      setState(() {
        guardandoDatos = true;
      });
      final formattedDate = dateFormatter.format(selectedDate!);

      String tituloPendiente = _tituloPendienteController.text;

      String pendientes = _pendientesController.text;

      print('Fecha: $formattedDate');
      print('Titulo: $tituloPendiente');
      print('ID Ticket: $idTicket');
      print('Área: $_selectedArea');
      print('Pendientes: $pendientes');

      // Crear el mapa con los datos
      final jsonData = {
        'nombre_tecnico': user.displayName,
        'email_tecnico': user.email,
        'fecha_pendientes': '${formattedDate}T23:00:00.000Z',
        "ticket": '$dropdownValue',
        'titulo_pendientes': tituloPendiente,
        'ticketId': idTicket,
        'area': _selectedArea,
        'pendientes': pendientes,
      };

      // Convertir el mapa a una cadena JSON
      final jsonString = json.encode(jsonData);

      print(jsonString);

      // Codificar la cadena JSON en Base64
      final bytes = utf8.encode(jsonString);
      final base64String = base64.encode(bytes);

      print(base64String);

      String url =
          'https://script.google.com/macros/s/AKfycbw6LBaegyigQSTwKprr52wmyosCC-CRqImwPaifmuXRoKcrA-Fh8eHBcmS5YtCgZ7UPGw/exec';
      String api = '$url?task=$base64String';

      final response = await http.get(Uri.parse(api));
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];

        if (contentType != null && contentType.contains('application/json')) {
          final jsonResponse = json.decode(response.body);
          print(jsonResponse);
          if (jsonResponse["result"] == "success") {
            // ignore: use_build_context_synchronously
            cargado();
            setState(() {
              guardandoDatos = false;
            });
          }
        } else {
          print('Invalid JSON response');
        }
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    }
  }

  Future<List<List<String>>> fetchData() async {
    final response = await http.get(Uri.parse(
        'https://script.google.com/macros/s/AKfycbw6LBaegyigQSTwKprr52wmyosCC-CRqImwPaifmuXRoKcrA-Fh8eHBcmS5YtCgZ7UPGw/exec?solicitud=open_tickets_id'));
    final data = json.decode(response.body) as List<dynamic>;
    final dataArray = data.map<List<String>>((item) {
      final ticket = item['ticket']?.toString() ?? '';
      tickets.add(ticket);
      final idTicket = item['id'] as String? ?? '';
      return [ticket, idTicket];
    }).toList();

    return dataArray;
  }

  void updateRazonSocial(String ticket) {
    if (ticket != '------------ ticket ------------') {
      print(ticket);
      final ticketData = data.firstWhere(
        (item) => item[0] == ticket,
        orElse: () => [
          '',
          '',
        ],
      );
      print(ticketData[1]);
      idTicket = ticketData.length > 1 ? ticketData[1] : '';
    } else {
      _tituloPendienteController.text = "";
    }
    setState(() {});
  }

  Future<void> signOutWithGoogle() async {
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
  }

  Future logOut() async {
    FirebaseAuth.instance.signOut();
    await signOutWithGoogle();
  }

  @override
  void initState() {
    super.initState();
    // Inicializar los valores de los controladores de texto aquí
    _tituloPendienteController.text = "";
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
      body: FutureBuilder<List<List<String>>>(
        future: fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              primeraVez == false) {
            primeraVez = true;
            paginaSiCargo = false; //reinicia la variable
            return Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: Image.asset('lib/images/logo_cargando.gif'),
              ),
            );
          } else if (snapshot.hasError && paginaSiCargo == false) {
            return Center(
              child: Text('Ocurrió un error: ${snapshot.error}'),
            );
          } else if (guardandoDatos == true) {
            return Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: Image.asset('lib/images/logo_cargando.gif'),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      // Acción al hacer clic en la equis para cerrar
                      setState(() {
                        guardandoDatos = false;
                      });
                    },
                  ),
                ),
              ],
            );
          } else {
            paginaSiCargo = true;
            data = snapshot.data!;
            return SingleChildScrollView(
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
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: dropdownValue,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                labelText:
                                    'Ticket', // Agregamos la etiqueta "Ticket"
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (String? newValue) {
                                setState(() {
                                  dropdownValue = newValue;
                                  updateRazonSocial(
                                      newValue!); // Agrega esta línea para actualizar la razón social
                                });
                              },
                              items: tickets
                                  .toList()
                                  .map<DropdownMenuItem<String>>(
                                    (String value) => DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Título del Pendiente',
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                labelStyle: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                ),
                              ),
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Por favor, ingrese el titulo';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _tituloPendienteController.text = value!;
                              },
                              controller:
                                  _tituloPendienteController, // Agrega esta línea
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: dateController,
                              readOnly: true,
                              onTap: () {
                                showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now()
                                      .add(const Duration(days: 1)),
                                  firstDate: DateTime.now()
                                      .add(const Duration(days: 1)),
                                  lastDate: DateTime(2100),
                                ).then((selectedDate) {
                                  if (selectedDate != null) {
                                    setState(() {
                                      this.selectedDate = DateTime(
                                        selectedDate.year,
                                        selectedDate.month,
                                        selectedDate.day,
                                      );
                                      dateController.text =
                                          dateFormatter.format(selectedDate);
                                    });
                                  }
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Fecha del Pendiente',
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                labelStyle: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                ),
                                // Agrega cualquier otra configuración de estilo que desees
                              ),
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              value: _selectedArea,
                              decoration: const InputDecoration(
                                labelText: 'Área Asignada',
                                border: OutlineInputBorder(),
                              ),
                              items: _area.map((String area) {
                                return DropdownMenuItem<String>(
                                  value: area,
                                  child: Text(area),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  _selectedArea = newValue;
                                }
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              maxLines: null,
                              decoration: InputDecoration(
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color.fromARGB(255, 138, 138, 138),
                                  ),
                                ),
                                disabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color.fromARGB(255, 138, 138, 138),
                                  ),
                                ),
                                labelText: 'Pendientes del Servicio',
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                labelStyle: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors
                                    .black, // Establece el color del texto deshabilitado
                              ),
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Por favor, ingrese el pendiente';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _pendientesController.text = value!;
                              },
                              controller: _pendientesController,
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            ElevatedButton(
                              onPressed: _submitForm,
                              child: const Text('Enviar'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
