import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signature/signature.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';

class FirmaCliente extends StatefulWidget {
  const FirmaCliente({Key? key}) : super(key: key);

  @override
  State<FirmaCliente> createState() => _FirmaClienteState();
}

class _FirmaClienteState extends State<FirmaCliente> {
  final user = FirebaseAuth.instance.currentUser!;

  var logger = Logger();

  final _correoCliente = TextEditingController();
  final _numTicket = TextEditingController();
  final _nombreCliente = TextEditingController();
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  List<ReservaISTP> tuLista = [];
  ReservaISTP? _selectedTicket;

  void resetFields() {
    setState(() {
      _controller.clear();
    });
  }

  Future<String> convertSignatureToBase64() async {
    final signatureImage = await _controller.toPngBytes();
    final resizedImage = img.copyResize(
      img.decodeImage(signatureImage!)!,
      width: 600,
      height: 400,
    );
    return base64Encode(img.encodePng(resizedImage));
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
              const CircularProgressIndicator(),
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
              'Firma Cargada',
              style: TextStyle(color: Colors.black, fontSize: 22),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
          content: const Text(
            'PDF generado con éxito',
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
    final encodedImage = await convertSignatureToBase64();
    final url = Uri.parse(
        'https://script.google.com/macros/s/AKfycbw6LBaegyigQSTwKprr52wmyosCC-CRqImwPaifmuXRoKcrA-Fh8eHBcmS5YtCgZ7UPGw/exec');
    final body = {
      'nombre_tecnico': user.displayName ?? 'Desconocido',
      'email_tecnico': user.email ?? '',
      "ticket": _numTicket.text,
      'correo_cliente': _correoCliente.text,
      'nombre_cliente': _nombreCliente.text,
      'firma_base64': encodedImage,
    };

    final response = await http.post(url, body: body);

    logger.i(response.statusCode);

    if (response.statusCode == 302) {
      Navigator.of(context, rootNavigator: true).pop();
      cargado();
    } else {
      // Manejar otros casos si es necesario
    }
  }

  Future<void> getReservas(String tecnico) async {
    final String apiUrl =
        'https://teknia.app/api/reservas_istp/firma_pendiente/$tecnico/';
    print(apiUrl);
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          tuLista = [
            ReservaISTP(id: 0, ticket: ''),
            ...data.map((item) => ReservaISTP.fromJson(item)).toList()
          ];
        });
      } else {
        logger.e('Error: ${response.statusCode}');
      }
    } catch (error) {
      logger.i('Error: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    getReservas(user.email ?? '');
  }

  @override
  Widget build(BuildContext context) {
    String displayName = user.displayName ?? 'Desconocido';
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                  4), // Ajusta el valor del radio según tus preferencias
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Container(
                    color: Colors.white,
                    child: Image.asset(
                      'lib/images/ar_inicio.png',
                      height: 40,
                    ),
                  ),
                  const SizedBox(),
                  const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Text(
                      'A S I A  R O B O T I C A',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                        " ${user.email ?? ''}",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nombreCliente,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
                    labelText: 'Nombre completo del cliente',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelStyle: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _correoCliente,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
                    labelText: 'Correo electrónico del cliente',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelStyle: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<ReservaISTP>(
                  value: _selectedTicket,
                  onChanged: (value) {
                    setState(() {
                      _selectedTicket = value;
                      _numTicket.text = value!.ticket;
                    });
                  },
                  items: tuLista.map((ticket) {
                    return DropdownMenuItem<ReservaISTP>(
                      value: ticket,
                      child: Text(ticket.ticket),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    labelText: 'Número de ticket',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelStyle: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('lib/images/firma3.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color.fromARGB(255, 151, 151, 151),
                        width: 1.0,
                      ),
                    ),
                    child: Signature(
                      controller: _controller,
                      height: 300,
                      backgroundColor: const Color.fromARGB(0, 224, 221, 221),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _controller.clear();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor:
                            const Color.fromARGB(255, 255, 255, 255),
                        backgroundColor:
                            const Color.fromARGB(235, 125, 186, 255),
                      ),
                      child: const Text('Limpiar firma'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (_controller.isNotEmpty) {
                          enviarDatos();
                          mostrarDialogCargando(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor:
                            const Color.fromARGB(255, 255, 255, 255),
                        backgroundColor:
                            const Color.fromARGB(235, 255, 125, 125),
                      ),
                      child: const Text('Enviar'),
                    ),
                  ],
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

class ReservaISTP {
  final int id;
  final String ticket;

  ReservaISTP({
    required this.id,
    required this.ticket,
  });

  factory ReservaISTP.fromJson(Map<String, dynamic> json) {
    return ReservaISTP(
      id: json['id'] as int,
      ticket: json['ticket'] as String,
    );
  }
}
