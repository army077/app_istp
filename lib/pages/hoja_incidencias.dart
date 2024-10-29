import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class IncidenciasPage extends StatefulWidget {
  const IncidenciasPage({Key? key}) : super(key: key);

  @override
  State<IncidenciasPage> createState() => _IncidenciasState();
}

class _IncidenciasState extends State<IncidenciasPage> {
  final user = FirebaseAuth.instance.currentUser!;

  final _formKey = GlobalKey<FormState>();
  String? _numeroTicket;
  String? _origenIncidencia;
  String? _tiposIncidencia;
  String? _ampliacionServicio;
  String? _priority;
  String? _tipoGarantia;
  final TextEditingController _horaExtrasController = TextEditingController();
  String? _diagnostico;
  String? _acciones;

  @override
  void dispose() {
    _horaExtrasController.dispose();
    super.dispose();
  }

  Future<void> _guardarIncidencia() async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // No permite cerrar la alerta haciendo clic fuera de ella
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmación'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Está seguro que desea registrar la incidencia'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra la alerta
              },
            ),
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra la alerta
                _submitForm();
              },
            ),
          ],
        );
      },
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Aquí puedes manejar el envío del formulario
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incidencia reportada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
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
                  const SizedBox(width: 8),
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
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'NOTA: ',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold, // Texto "Importante" en negrita
                          color: Colors.grey,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Este reporte NO se envia por correo al cliente (es solo para uso interno)',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Explicar la situación actual'),
                  maxLines: 6,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa la situación actual';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _diagnostico = value!;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Acciones a llevar a cabo'),
                  maxLines: 6,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa la descripción de las acciones';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _acciones = value!;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(7.0),
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Ticket',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa el número de ticket';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _numeroTicket = value!;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: DropdownButtonFormField<String>(
                  value: _origenIncidencia,
                  onChanged: (value) {
                    setState(() {
                      _origenIncidencia = value!;
                    });
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'Técnico',
                      child: Text('Técnico'),
                    ),
                    DropdownMenuItem(
                      value: 'Máquina',
                      child: Text('Máquina'),
                    ),
                    DropdownMenuItem(
                      value: 'Operador (Cliente)',
                      child: Text('Operador (Cliente)'),
                    ),
                    DropdownMenuItem(
                      value: 'Pieza',
                      child: Text('Pieza'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Origen de la Incidencia',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: DropdownButtonFormField<String>(
                  value: _tiposIncidencia,
                  onChanged: (value) {
                    setState(() {
                      _tiposIncidencia = value!;
                    });
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'Falla mecánica',
                      child: Text(
                        'Falla Mecánica',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Falla eléctrica',
                      child: Text(
                        'Falla Eléctrica',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Operador no capacitado',
                      child: Text(
                        'Operador no capacitado',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Conocimiento insuficiente',
                      child: Text(
                        'Conocimiento insuficiente',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Instalación fuera de especificación',
                      child: Text(
                        'Instalación fuera de especificación',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Componente(s) dañado(s)',
                      child: Text(
                        'Componente(s) dañado(s)',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Parámetros incorrectos',
                      child: Text(
                        'Parámetros incorrectos',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Componente fuera de especificacion',
                      child: Text(
                        'Componente fuera de especificacion',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Descalibración',
                      child: Text(
                        'Descalibración',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Falta de mantenimiento',
                      child: Text(
                        'Falta de mantenimiento',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Tipo de Incidencia',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Prioridad',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  value: _priority,
                  items: ['Alta', 'Media', 'Baja']
                      .map((priority) => DropdownMenuItem(
                            value: priority,
                            child: Text(priority),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _priority = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Por favor selecciona una prioridad';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: DropdownButtonFormField<String>(
                  value: _ampliacionServicio,
                  onChanged: (value) {
                    setState(() {
                      _ampliacionServicio = value!;
                    });
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'Sí',
                      child: Text('Sí'),
                    ),
                    DropdownMenuItem(
                      value: 'No',
                      child: Text('No'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: '¿Necesitas Ampliación del Servicio?',
                    labelStyle: const TextStyle(fontSize: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _horaExtrasController,
                  decoration: InputDecoration(
                    labelText: 'Tiempo extra (hrs)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 8, minute: 00),
                      initialEntryMode: TimePickerEntryMode.input,
                      builder: (BuildContext context, Widget? child) {
                        return MediaQuery(
                          data: MediaQuery.of(context)
                              .copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        );
                      },
                    );
                    if (time != null) {
                      setState(() {
                        _horaExtrasController.text =
                            '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'IMPORTANTE: ',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold, // Texto "Importante" en negrita
                          color: Colors.grey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      TextSpan(
                        text:
                            '1 día extra son 8 hrs, 2 días extras 16 hrs, etc.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Tipo de Garantía',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  value: _tipoGarantia,
                  items: ['Garantía Interna', 'Garantía Externa', 'Faltante']
                      .map((tipo) => DropdownMenuItem(
                            value: tipo,
                            child: Text(tipo),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _tipoGarantia = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Por favor selecciona un tipo';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _guardarIncidencia();
                },
                child: const Text('Registrar Incidencia'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
