import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:istp_app/pages/home_page.dart';
import 'dart:convert';
import 'package:logger/logger.dart';

class CalidadPage extends StatefulWidget {
  const CalidadPage({Key? key}) : super(key: key);

  @override
  State<CalidadPage> createState() => _CalidadState();
}

class _CalidadState extends State<CalidadPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final user = FirebaseAuth.instance.currentUser!;

  var logger = Logger();

  final _formKey = GlobalKey<FormState>();
  String? _numeroTicket;
  String? _cliente;
  String? _modeloEquipo;
  String? _numeroSerie;
  String? _categoria;
  String? _subcategoria;
  String? _tipoIncidente;
  String? _causaIncidente;
  String? _accesorioSoftwareProblema;

  String _userName = "";
  String _userEmail = "";

  final TextEditingController _otroSubcategoriaController =
      TextEditingController();
  final TextEditingController _otroTipoIncidenteController =
      TextEditingController();
  final TextEditingController _otroCausaIncidenteController =
      TextEditingController();
  final TextEditingController _otroAccesorioSoftwareProblemaController =
      TextEditingController();

  List<String> accesorios = [];

  List<String> incidentes = [];

  List<String> tipoIncidentes = [];

  List<String> subCategorias = [];

  List<String> categorias = [];

  List<String> _modelosDeEquipo = [];

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        setState(() {
          _userName = user.displayName ?? '';
          _userEmail = user.email ?? '';
        });
      }
    });
    _fetchModelosDeEquipo();
    _fetchClasificaciones();
  }

  @override
  void dispose() {
    _otroSubcategoriaController.dispose();
    _otroTipoIncidenteController.dispose();
    _otroCausaIncidenteController.dispose();
    _otroAccesorioSoftwareProblemaController.dispose();
    super.dispose();
  }

  Future<void> _fetchModelosDeEquipo() async {
    final url = Uri.parse('https://teknia.app/api/all_maquinas/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        logger.i(data);
        setState(() {
          _modelosDeEquipo =
              data.map((item) => item['maquina'] as String).toList();
        });
      } else {
        // Maneja errores de respuesta
        throw Exception('Error al cargar los modelos de equipo');
      }
    } catch (e) {
      // Maneja errores de conexión o de la solicitud
      logger.i(e);
    }
  }

  Future<void> _fetchClasificaciones() async {
    const url = 'https://teknia.app/api/clasificaciones_calidad/';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);

      List<String> arrayAccs = [];
      List<String> arrayIncidentes = [];
      List<String> arrayTipoIncidentes = [];
      List<String> arraySubCatego = [];
      List<String> arrayCatego = [];

      for (var item in data) {
        if (item['tipo'] == 'accesorio_con_problema') {
          arrayAccs.add(item['nombre']);
        } else if (item['tipo'] == 'causa_incidente') {
          arrayIncidentes.add(item['nombre']);
        } else if (item['tipo'] == 'tipo_incidente') {
          arrayTipoIncidentes.add(item['nombre']);
        } else if (item['tipo'] == 'subcategoria') {
          arraySubCatego.add(item['nombre']);
        } else if (item['tipo'] == 'categoria') {
          arrayCatego.add(item['nombre']);
        }
      }

      // Mueve la opción "Otro" al final si existe en la lista
      arrayAccs = _moveOptionToEnd(arrayAccs, 'Otro');
      arrayIncidentes = _moveOptionToEnd(arrayIncidentes, 'Otro');
      arrayTipoIncidentes = _moveOptionToEnd(arrayTipoIncidentes, 'Otro');
      arraySubCatego = _moveOptionToEnd(arraySubCatego, 'Otro');
      arrayCatego = _moveOptionToEnd(arrayCatego, 'Otro');

      logger.i('arrayAccs: $arrayAccs');
      logger.i('arrayIncidentes: $arrayIncidentes');
      logger.i('arrayTipoIncidentes: $arrayTipoIncidentes');
      logger.i('arraySubCatego: $arraySubCatego');
      logger.i('Categorías: $arrayCatego');

      setState(() {
        accesorios = arrayAccs;
        incidentes = arrayIncidentes;
        tipoIncidentes = arrayTipoIncidentes;
        subCategorias = arraySubCatego;
        categorias = arrayCatego;
      });
    } else {
      logger.e('Error al obtener los datos: ${response.statusCode}');
    }
  }

  List<String> _moveOptionToEnd(List<String> list, String option) {
    if (list.contains(option)) {
      list.remove(option);
      list.add(option);
    }
    return list;
  }

  Future<void> _guardarIncidencia(BuildContext parentContext) async {
    return showDialog<void>(
      context: parentContext, // Use the parent context
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmación'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Está seguro que desea registrar el reporte?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
                _submitForm(parentContext); // Pass the parent context
              },
            ),
          ],
        );
      },
    );
  }

  void _submitForm(BuildContext parentContext) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // Llama a onSaved para cada campo

      // Crear el cuerpo de la solicitud con los datos del formulario
      final Map<String, dynamic> requestBody = {
        'numero_ticket': _numeroTicket,
        'nombre_tecnico': _userName,
        'correo_tecnico': _userEmail,
        'cliente': _cliente,
        'modelo_equipo': _modeloEquipo,
        'numero_serie': _numeroSerie,
        'categoria': _categoria,
        'subcategoria': _subcategoria == 'Otro'
            ? _otroSubcategoriaController.text
            : _subcategoria,
        'tipo_incidente': _tipoIncidente == 'Otro'
            ? _otroTipoIncidenteController.text
            : _tipoIncidente,
        'causa_incidente': _causaIncidente == 'Otro'
            ? _otroCausaIncidenteController.text
            : _causaIncidente,
        'accesorio_software_problema': _accesorioSoftwareProblema == 'Otro'
            ? _otroAccesorioSoftwareProblemaController.text
            : _accesorioSoftwareProblema,
      };

      logger.i(requestBody);

      try {
        // Enviar la solicitud POST a la API
        final response = await http.post(
          Uri.parse('https://teknia.app/api/guardar_reporte_calidad'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        if (!mounted) return; // Check if the widget is still mounted

        // Manejar la respuesta de la API
        if (response.statusCode == 201) {
          var url =
              "https://script.google.com/macros/s/AKfycbw6LBaegyigQSTwKprr52wmyosCC-CRqImwPaifmuXRoKcrA-Fh8eHBcmS5YtCgZ7UPGw/exec?mensaje_calidad=true&celular=3323391899&ticket=$_numeroTicket";
          final response = await http.get(
            Uri.parse(url),
          );
          if (response.statusCode == 200) {
            showDialog(
              // ignore: use_build_context_synchronously
              context: parentContext, // Usa el contexto principal
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Éxito'),
                  content: const Text(
                      'El reporte de calidad se guardó exitosamente.'),
                  actions: [
                    TextButton(
                      child: const Text('Aceptar'),
                      onPressed: () {
                        Navigator.of(context).pop(); // Cerrar el diálogo
                        Navigator.of(parentContext).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (BuildContext context) =>
                                const HomePage(), // Reemplaza con la página de destino
                          ),
                          (Route<dynamic> route) =>
                              false, // Elimina todas las rutas anteriores
                        );
                      },
                    ),
                  ],
                );
              },
            );
          }
        } else {
          throw Exception('Error al guardar el reporte');
        }
      } catch (error) {
        if (!mounted) return; // Check if the widget is still mounted

        showDialog(
          context: parentContext, // Use the parent context
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Error al guardar el reporte: $error'),
              actions: [
                TextButton(
                  child: const Text('Ok'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Cerrar el diálogo
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  Widget _buildDropdownWithOtherOption(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
    TextEditingController otherController,
  ) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: value,
            onChanged: (selectedValue) {
              onChanged(selectedValue);
            },
            items: items.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value.length > 39 ? "${value.substring(0, 39)}..." : value,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor selecciona una opción';
              }
              return null;
            },
          ),
          if (value == 'Otro')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextFormField(
                controller: otherController,
                decoration: InputDecoration(
                  labelText: 'Por favor especifica',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor especifica la opción';
                  }
                  return null;
                },
              ),
            ),
        ],
      ),
    );
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
                            'Este reporte NO se envia por correo al cliente (es solo para uso interno de calidad)',
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
                padding: const EdgeInsets.all(7.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Cliente',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa el cliente';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _cliente = value!;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(7.0),
                child: DropdownButtonFormField<String>(
                  value: _modeloEquipo,
                  onChanged: (value) {
                    setState(() {
                      _modeloEquipo = value;
                    });
                  },
                  items: _modelosDeEquipo.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value.length > 32
                            ? "${value.substring(0, 32)}..."
                            : value,
                      ),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Modelo de Equipo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor selecciona una opción';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(7.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Número de Serie',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa el número de serie';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _numeroSerie = value!;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: DropdownButtonFormField<String>(
                  value: _categoria,
                  onChanged: (value) {
                    setState(() {
                      _categoria = value!;
                    });
                  },
                  items: categorias.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value.length > 32
                            ? "${value.substring(0, 32)}..."
                            : value,
                      ),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor selecciona una opción';
                    }
                    return null;
                  },
                ),
              ),
              _buildDropdownWithOtherOption(
                'Subcategoría',
                _subcategoria,
                subCategorias,
                (String? newValue) {
                  setState(() {
                    _subcategoria = newValue;
                    if (newValue == 'Otro') {
                      _otroSubcategoriaController.text = "";
                    }
                  });
                },
                _otroSubcategoriaController,
              ),
              _buildDropdownWithOtherOption(
                'Tipo de Incidente',
                _tipoIncidente,
                tipoIncidentes,
                (String? newValue) {
                  setState(() {
                    _tipoIncidente = newValue;
                    if (newValue == 'Otro') {
                      _otroTipoIncidenteController.text = "";
                    }
                  });
                },
                _otroTipoIncidenteController,
              ),
              _buildDropdownWithOtherOption(
                'Causa del Incidente',
                _causaIncidente,
                incidentes,
                (String? newValue) {
                  setState(() {
                    _causaIncidente = newValue;
                    if (newValue == 'Otro') {
                      _otroCausaIncidenteController.text = "";
                    }
                  });
                },
                _otroCausaIncidenteController,
              ),
              _buildDropdownWithOtherOption(
                'Accesorio/Software Problema',
                _accesorioSoftwareProblema,
                accesorios,
                (String? newValue) {
                  setState(() {
                    _accesorioSoftwareProblema = newValue;
                    if (newValue == 'Otro') {
                      _otroAccesorioSoftwareProblemaController.text = "";
                    }
                  });
                },
                _otroAccesorioSoftwareProblemaController,
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () =>
                      _guardarIncidencia(context), // Pass context from here
                  child: const Text('Registrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
