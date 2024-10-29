import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MaintenanceForm extends StatefulWidget {
  @override
  _MaintenanceFormState createState() => _MaintenanceFormState();
}

class _MaintenanceFormState extends State<MaintenanceForm> {
  final _formKey = GlobalKey<FormState>();

  // Variables para los campos del formulario
  String _codigo = '';
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _detalleController = TextEditingController();

  final Map<String, Map<String, String>> _data = {
    '': {
      'titulo': '',
      'detalle': '',
    },
    'MTP0001': {
      'titulo': 'Revisión de estado de baleros y guías lineales',
      'detalle':
          'Establecer si las guías y baleros lineales se desplazan con poca fricción y sin brincos. Revisar que exista una lubricación adecuada en los mismos.',
    },
    'MTP0002': {
      'titulo': 'Cambio de agua de chiller (Fiber)',
      'detalle':
          'Llevar a cabo el cambio de agua de intercambiador de calor, evitando así contaminación de la misma y posibles daños a Fuente láser de Fibra Óptica.',
    },
  };

  bool _inspeccion = false;
  bool _inspeccionExpanded = true;
  bool _lubricacion = false;
  bool _lubricacionExpanded = true;
  bool _limpieza = false;
  bool _limpiezaExpanded = true;
  bool _ajuste = false;
  bool _ajusteExpanded = true;
  bool _remplazoDefinitivo = false;
  bool _remplazoDefinitivoExpanded = false;
  bool _sustitucionTemporal = false;
  bool _sustitucionTemporalExpanded = false;

  String? _selectedClassification;

  bool _esSi = false; // Valor predeterminado "No"
  int _selectedInsLimpieza = 1; // Valor inicial
  int _selectedInsLubricacion = 1; // Valor inicial
  int _selectedInsDesgaste = 1; // Valor inicial
  int _selectedInsDanio = 1; // Valor inicial
  int _selectedInsCalibracion = 1; // Valor inicial

  bool _esSiFueraRango = false; // Valor predeterminado "No"

  final TextEditingController _limiteSuperiorController =
      TextEditingController();
  final TextEditingController _limiteInferiorController =
      TextEditingController();

  bool _esSiDiferenteMarca = false; // Valor predeterminado "No"

  int _selectedEstetico = 1; // Valor inicial
  int _selectedConexiones = 1; // Valor inicial

  int _selectedLimpieza = 1; // Valor inicial

  int _selectedLubricacion = 1; // Valor inicial

  int _selectedAjuste = 1; // Valor inicial

  String componenteRemplazoDefinitivo = '';
  int _selectedPreventivo = 1; // Valor inicial
  int _selectedCorrectivo = 1; // Valor inicial

  int _selectedSustitucionTemporal = 1; // Valor inicial

  String? _selectedImpedimento;
  final List<String> _impedimentos = [
    "Falta de tiempo (causado por cliente)",
    "Falta de tiempo (causado por AR)",
    "No se cuenta con pieza/refacción/consumible",
    "Falta de conocimiento o experiencia en la actividad",
    "Cliente no aceptó",
    "Falta de pago (o incompleto)",
    "Voltaje fuera de rango",
    "Sin electricidad",
    "Sin material para pruebas",
    "Otro"
  ];

  final TextEditingController _otroController = TextEditingController();

  List<Refaccion> _refacciones = [];
  final TextEditingController _numeroParteController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();

  final TextEditingController _frecuenciaController = TextEditingController();
  final TextEditingController _tiempoHorasController =
      TextEditingController(text: "0");
  final TextEditingController _tiempoMinutosController =
      TextEditingController(text: "0");
  final TextEditingController _comentariosController = TextEditingController();

  void _updateFields(String? codigo) {
    if (codigo != null && _data.containsKey(codigo)) {
      setState(() {
        _tituloController.text = _data[codigo]?['titulo'] ?? "";
        _detalleController.text = _data[codigo]?['detalle'] ?? "";
      });
    } else {
      setState(() {
        _tituloController.text = "";
        _detalleController.text = "";
      });
    }
  }

  void _agregarRefaccion() {
    setState(() {
      _refacciones.add(Refaccion(
        numeroParte: _numeroParteController.text,
        cantidad: int.parse(_cantidadController.text),
      ));
      _numeroParteController.clear();
      _cantidadController.clear();
    });
  }

  @override
  void dispose() {
    _frecuenciaController.dispose();
    _tiempoHorasController.dispose();
    _tiempoMinutosController.dispose();
    _comentariosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      Text(
                        "Formato de Mantenimiento",
                        style: TextStyle(
                          fontSize: 18.0, // Tamaño de fuente
                          fontWeight: FontWeight.bold, // Negrita
                          color: Colors.black, // Color del texto
                        ),
                      ),
                    ],
                  ),
                ),
                // Campo Código Alfanumérico
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Código (Orden de Trabajo)',
                      border: OutlineInputBorder(),
                    ),
                    value: _codigo,
                    onChanged: (newValue) {
                      setState(() {
                        _codigo = newValue ?? "";
                      });
                      _updateFields(newValue);
                    },
                    items: _data.keys.map((codigo) {
                      return DropdownMenuItem(
                        value: codigo,
                        child: Text(codigo),
                      );
                    }).toList(),
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor, seleccione un código alfanumérico';
                      }
                      return null;
                    },
                  ),
                ),

                // Campo Título
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _tituloController,
                    decoration: InputDecoration(
                      labelText: 'Título',
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 16.0),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      labelStyle: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.normal,
                          color: Colors.black),
                    ),
                    onSaved: (value) {
                      _tituloController.text = value!;
                    },
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Por favor, ingrese el título';
                      }
                      return null;
                    },
                  ),
                ),

                // Campo Detalle
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _detalleController,
                    decoration: InputDecoration(
                      labelText: 'Detalle',
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 16.0),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      labelStyle: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.normal,
                          color: Colors.black),
                    ),
                    maxLines: 4,
                    onSaved: (value) {
                      _detalleController.text = value!;
                    },
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Por favor, ingrese el detalle';
                      }
                      return null;
                    },
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Text(
                        "Clasificación de operación",
                        style: TextStyle(
                          fontSize: 18.0, // Tamaño de fuente
                          fontWeight: FontWeight.bold, // Negrita
                          color: Colors.black, // Color del texto
                        ),
                      ),
                    ],
                  ),
                ),

                // Descripción
                const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Text(
                        "La naturaleza de la operación/actividad a realizar",
                        style: TextStyle(
                            fontSize: 12.0, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),

                // Checkbox: Inspección
                CheckboxListTile(
                  title: const Text("Inspección"),
                  value: _inspeccion,
                  onChanged: (bool? value) {
                    setState(() {
                      _inspeccion = value!;
                      _inspeccionExpanded = true;
                    });
                  },
                ),

                if (_inspeccion)
                  SizedBox(
                    width: 400,
                    child: ExpansionTile(
                      onExpansionChanged: (value) => setState(() {
                        _inspeccionExpanded = !value;
                      }),
                      title: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        width:
                            400, // Ancho del contenedor para pantallas grandes
                        child: Text(
                          _inspeccionExpanded
                              ? 'Mostrar mas . . .'
                              : 'Mostrar menos . . .',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.blueAccent),
                        ),
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          width:
                              400, // Ancho del contenedor para pantallas grandes
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Alinea a la izquierda
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    const Column(
                                      children: [
                                        Text(
                                          '¿Incompleto?',
                                          style: TextStyle(
                                            fontSize: 18.0, // Tamaño de fuente
                                            fontWeight:
                                                FontWeight.bold, // Negrita
                                            color:
                                                Colors.black, // Color del texto
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Switch(
                                          value: _esSi,
                                          onChanged: (bool value) {
                                            setState(() {
                                              _esSi = value;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    const Column(
                                      children: [
                                        Text('Seleccionaste:'),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          _esSi ? '    Sí    ' : '  No    ',
                                          style: const TextStyle(
                                            fontSize: 16.0, // Tamaño de fuente
                                            fontWeight:
                                                FontWeight.bold, // Negrita
                                            color:
                                                Colors.black, // Color del texto
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 4.0),
                                  child: Text(
                                    'Lubricación',
                                    style: TextStyle(
                                      fontSize: 18.0, // Tamaño de fuente
                                      fontWeight: FontWeight.bold, // Negrita
                                      color: Colors.black, // Color del texto
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    RadioListTile<int>(
                                      title: const Text(
                                          '1- Sin lubricación (seco)'),
                                      value: 1,
                                      groupValue: _selectedInsLubricacion,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedInsLubricacion = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4,
                                          vertical:
                                              -4), // Ajusta el tamaño visual
                                      materialTapTargetSize: MaterialTapTargetSize
                                          .shrinkWrap, // Reduce el tamaño del área de toque
                                    ),
                                    RadioListTile<int>(
                                      title: const Text(
                                          '2- Lubricación vieja y sucia'),
                                      value: 2,
                                      groupValue: _selectedInsLubricacion,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedInsLubricacion = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text(
                                          '3- Lubricado (insuficiente)'),
                                      value: 3,
                                      groupValue: _selectedInsLubricacion,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedInsLubricacion = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('4- Bien lubricado'),
                                      value: 4,
                                      groupValue: _selectedInsLubricacion,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedInsLubricacion = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 4.0),
                                  child: Text(
                                    'Desgaste',
                                    style: TextStyle(
                                      fontSize: 18.0, // Tamaño de fuente
                                      fontWeight: FontWeight.bold, // Negrita
                                      color: Colors.black, // Color del texto
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    RadioListTile<int>(
                                      title: const Text(
                                          '1- Remplazo inmediato sugerido'),
                                      value: 1,
                                      groupValue: _selectedInsDesgaste,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedInsDesgaste = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4,
                                          vertical:
                                              -4), // Ajusta el tamaño visual
                                      materialTapTargetSize: MaterialTapTargetSize
                                          .shrinkWrap, // Reduce el tamaño del área de toque
                                    ),
                                    RadioListTile<int>(
                                      title: const Text(
                                          '2- Remplazar próximamente'),
                                      value: 2,
                                      groupValue: _selectedInsDesgaste,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedInsDesgaste = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('3- Ligero desgaste'),
                                      value: 3,
                                      groupValue: _selectedInsDesgaste,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedInsDesgaste = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('4- En buen estado'),
                                      value: 4,
                                      groupValue: _selectedInsDesgaste,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedInsDesgaste = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 4.0),
                                  child: Text(
                                    'Limpieza',
                                    style: TextStyle(
                                      fontSize: 18.0, // Tamaño de fuente
                                      fontWeight: FontWeight.bold, // Negrita
                                      color: Colors.black, // Color del texto
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    RadioListTile<int>(
                                      title: const Text('1- Muy sucio'),
                                      value: 1,
                                      groupValue: _selectedInsLimpieza,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedInsLimpieza = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4,
                                          vertical:
                                              -4), // Ajusta el tamaño visual
                                      materialTapTargetSize: MaterialTapTargetSize
                                          .shrinkWrap, // Reduce el tamaño del área de toque
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('2- Sucio'),
                                      value: 2,
                                      groupValue: _selectedInsLimpieza,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedInsLimpieza = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('3- Un poco sucio'),
                                      value: 3,
                                      groupValue: _selectedInsLimpieza,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedInsLimpieza = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('4- Limpio'),
                                      value: 4,
                                      groupValue: _selectedInsLimpieza,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedInsLimpieza = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 4.0),
                                  child: Text(
                                    'Con Daño',
                                    style: TextStyle(
                                      fontSize: 18.0, // Tamaño de fuente
                                      fontWeight: FontWeight.bold, // Negrita
                                      color: Colors.black, // Color del texto
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    RadioListTile<int>(
                                      title: const Text('1- No funcional'),
                                      value: 1,
                                      groupValue: _selectedInsDanio,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedInsDanio = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4,
                                          vertical:
                                              -4), // Ajusta el tamaño visual
                                      materialTapTargetSize: MaterialTapTargetSize
                                          .shrinkWrap, // Reduce el tamaño del área de toque
                                    ),
                                    RadioListTile<int>(
                                      title: const Text(
                                          '2- Falla próxima inminente (riesgo de otros daños/accidente - detener producción)'),
                                      value: 2,
                                      groupValue: _selectedInsDanio,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedInsDanio = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text(
                                          '3- Falla próxima inminente (sin consecuencias graves - puede operar hasta el fallo)'),
                                      value: 3,
                                      groupValue: _selectedInsDanio,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedInsDanio = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('4- 100% Funcional'),
                                      value: 4,
                                      groupValue: _selectedInsDanio,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedInsDanio = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 4.0),
                                  child: Text(
                                    'Calibración',
                                    style: TextStyle(
                                      fontSize: 18.0, // Tamaño de fuente
                                      fontWeight: FontWeight.bold, // Negrita
                                      color: Colors.black, // Color del texto
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    RadioListTile<int>(
                                      title: const Text('1- Descalibrado'),
                                      value: 1,
                                      groupValue: _selectedInsCalibracion,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedInsCalibracion = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4,
                                          vertical:
                                              -4), // Ajusta el tamaño visual
                                      materialTapTargetSize: MaterialTapTargetSize
                                          .shrinkWrap, // Reduce el tamaño del área de toque
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('2- Ok'),
                                      value: 2,
                                      groupValue: _selectedInsCalibracion,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedInsCalibracion = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text(
                                          '3- No aplica (Sin Default)'),
                                      value: 3,
                                      groupValue: _selectedInsCalibracion,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedInsCalibracion = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    const Column(
                                      children: [
                                        Text(
                                          'Fuera de Rango',
                                          style: TextStyle(
                                            fontSize: 18.0, // Tamaño de fuente
                                            fontWeight:
                                                FontWeight.bold, // Negrita
                                            color:
                                                Colors.black, // Color del texto
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Switch(
                                          value: _esSiFueraRango,
                                          onChanged: (bool value) {
                                            setState(() {
                                              _esSiFueraRango = value;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    const Column(
                                      children: [
                                        Text('Seleccionaste:'),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          _esSiFueraRango
                                              ? '    Sí    '
                                              : '  No    ',
                                          style: const TextStyle(
                                            fontSize: 16.0, // Tamaño de fuente
                                            fontWeight:
                                                FontWeight.bold, // Negrita
                                            color:
                                                Colors.black, // Color del texto
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                if (_esSiFueraRango)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            TextField(
                                              controller:
                                                  _limiteSuperiorController,
                                              decoration: const InputDecoration(
                                                labelText: 'Límite Superior',
                                                border: OutlineInputBorder(),
                                              ),
                                              style: const TextStyle(
                                                color: Colors.red,
                                              ),
                                              keyboardType: const TextInputType
                                                  .numberWithOptions(
                                                  decimal: true),
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp(r'[0-9.]')),
                                                // Permite dígitos y puntos decimales
                                                LengthLimitingTextInputFormatter(
                                                    10), // Limita el número de caracteres
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            TextField(
                                              controller:
                                                  _limiteInferiorController,
                                              decoration: const InputDecoration(
                                                labelText: 'Límite Inferior',
                                                border: OutlineInputBorder(),
                                              ),
                                              style: const TextStyle(
                                                color: Colors.red,
                                              ),
                                              keyboardType: const TextInputType
                                                  .numberWithOptions(
                                                  decimal: true),
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp(r'[0-9.]')),
                                                // Permite dígitos y puntos decimales
                                                LengthLimitingTextInputFormatter(
                                                    10), // Limita el número de caracteres
                                              ],
                                            ),
                                          ],
                                        ),
                                      ), // Añade un espacio entre las columnas si es necesario
                                    ],
                                  ),
                                //Codigo de Kevin-----------------------------------------------------------
                                const SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    const Column(
                                      children: [
                                        Text(
                                          'Diferente marca',
                                          style: TextStyle(
                                            fontSize: 18.0, // Tamaño de fuente
                                            fontWeight:
                                                FontWeight.bold, // Negrita
                                            color:
                                                Colors.black, // Color del texto
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Switch(
                                          value: _esSiDiferenteMarca,
                                          onChanged: (bool value) {
                                            setState(() {
                                              _esSiDiferenteMarca = value;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    const Column(
                                      children: [
                                        Text('Seleccionaste:'),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          _esSiDiferenteMarca
                                              ? '    Sí    '
                                              : '  No    ',
                                          style: const TextStyle(
                                            fontSize: 16.0, // Tamaño de fuente
                                            fontWeight:
                                                FontWeight.bold, // Negrita
                                            color:
                                                Colors.black, // Color del texto
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 4.0),
                                  child: Text(
                                    'Estético',
                                    style: TextStyle(
                                      fontSize: 18.0, // Tamaño de fuente
                                      fontWeight: FontWeight.bold, // Negrita
                                      color: Colors.black, // Color del texto
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    RadioListTile<int>(
                                      title: const Text(
                                          '1- Con rayaduras y golpes fuertes'),
                                      value: 1,
                                      groupValue: _selectedEstetico,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedEstetico = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4,
                                          vertical:
                                              -4), // Ajusta el tamaño visual
                                      materialTapTargetSize: MaterialTapTargetSize
                                          .shrinkWrap, // Reduce el tamaño del área de toque
                                    ),
                                    RadioListTile<int>(
                                      title: const Text(
                                          '2- Con rayaduras o golpes leves'),
                                      value: 2,
                                      groupValue: _selectedEstetico,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedEstetico = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('3- En buen estado'),
                                      value: 3,
                                      groupValue: _selectedEstetico,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedEstetico = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 4.0),
                                  child: Text(
                                    'Conexiones (cables)',
                                    style: TextStyle(
                                      fontSize: 18.0, // Tamaño de fuente
                                      fontWeight: FontWeight.bold, // Negrita
                                      color: Colors.black, // Color del texto
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    RadioListTile<int>(
                                      title: const Text('1- Sueltos'),
                                      value: 1,
                                      groupValue: _selectedConexiones,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedConexiones = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4,
                                          vertical:
                                              -4), // Ajusta el tamaño visual
                                      materialTapTargetSize: MaterialTapTargetSize
                                          .shrinkWrap, // Reduce el tamaño del área de toque
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('2- Flojos'),
                                      value: 2,
                                      groupValue: _selectedConexiones,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedConexiones = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('3-En buen estado'),
                                      value: 3,
                                      groupValue: _selectedConexiones,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedConexiones = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),

                                //Aqui termina -------------------------------------------------------------
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Checkbox: Lubricación
                CheckboxListTile(
                  title: const Text("Lubricación"),
                  value: _lubricacion,
                  onChanged: (bool? value) {
                    setState(() {
                      _lubricacion = value!;
                      _lubricacionExpanded = true;
                    });
                  },
                ),

                if (_lubricacion)
                  SizedBox(
                    width: 400,
                    child: ExpansionTile(
                      onExpansionChanged: (value) => setState(() {
                        _lubricacionExpanded = !value;
                      }),
                      title: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        width:
                            400, // Ancho del contenedor para pantallas grandes
                        child: Text(
                          _lubricacionExpanded
                              ? 'Mostrar mas . . .'
                              : 'Mostrar menos . . .',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.blueAccent),
                        ),
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          width:
                              400, // Ancho del contenedor para pantallas grandes
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Alinea a la izquierda
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const SizedBox(
                                  height: 20,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 4.0),
                                  child: Text(
                                    'Componente en cuestion o equipo',
                                    style: TextStyle(
                                      fontSize: 18.0, // Tamaño de fuente
                                      fontWeight: FontWeight.bold, // Negrita
                                      color: Colors.black, // Color del texto
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    RadioListTile<int>(
                                      title: const Text('1- No Aplica'),
                                      value: 1,
                                      groupValue: _selectedLubricacion,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedLubricacion = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4,
                                          vertical:
                                              -4), // Ajusta el tamaño visual
                                      materialTapTargetSize: MaterialTapTargetSize
                                          .shrinkWrap, // Reduce el tamaño del área de toque
                                    ),
                                    RadioListTile<int>(
                                      title: const Text(
                                          '2- Pendiente (no iniciada)'),
                                      value: 2,
                                      groupValue: _selectedLubricacion,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedLubricacion = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('3- Incompleta'),
                                      value: 3,
                                      groupValue: _selectedLubricacion,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedLubricacion = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('4- Terminada'),
                                      value: 4,
                                      groupValue: _selectedLubricacion,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedLubricacion = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Checkbox: Limpieza
                CheckboxListTile(
                  title: const Text("Limpieza"),
                  value: _limpieza,
                  onChanged: (bool? value) {
                    setState(() {
                      _limpieza = value!;
                      _limpiezaExpanded = true;
                    });
                  },
                ),

                if (_limpieza)
                  SizedBox(
                    width: 400,
                    child: ExpansionTile(
                      onExpansionChanged: (value) => setState(() {
                        _limpiezaExpanded = !value;
                      }),
                      title: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        width:
                            400, // Ancho del contenedor para pantallas grandes
                        child: Text(
                          _limpiezaExpanded
                              ? 'Mostrar mas . . .'
                              : 'Mostrar menos . . .',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.blueAccent),
                        ),
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          width:
                              400, // Ancho del contenedor para pantallas grandes
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Alinea a la izquierda
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const SizedBox(
                                  height: 20,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 4.0),
                                  child: Text(
                                    'Componente en cuestion o equipo',
                                    style: TextStyle(
                                      fontSize: 18.0, // Tamaño de fuente
                                      fontWeight: FontWeight.bold, // Negrita
                                      color: Colors.black, // Color del texto
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    RadioListTile<int>(
                                      title: const Text('1- No Aplica'),
                                      value: 1,
                                      groupValue: _selectedLimpieza,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedLimpieza = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4,
                                          vertical:
                                              -4), // Ajusta el tamaño visual
                                      materialTapTargetSize: MaterialTapTargetSize
                                          .shrinkWrap, // Reduce el tamaño del área de toque
                                    ),
                                    RadioListTile<int>(
                                      title: const Text(
                                          '2- Pendiente (no iniciada)'),
                                      value: 2,
                                      groupValue: _selectedLimpieza,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedLimpieza = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('3- Incompleta'),
                                      value: 3,
                                      groupValue: _selectedLimpieza,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedLimpieza = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('4- Terminada'),
                                      value: 4,
                                      groupValue: _selectedLimpieza,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedLimpieza = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Checkbox: Ajuste
                CheckboxListTile(
                  title: const Text("Ajuste"),
                  value: _ajuste,
                  onChanged: (bool? value) {
                    setState(() {
                      _ajuste = value!;
                      _ajusteExpanded = true;
                    });
                  },
                ),

                if (_ajuste)
                  SizedBox(
                    width: 400,
                    child: ExpansionTile(
                      onExpansionChanged: (value) => setState(() {
                        _ajusteExpanded = !value;
                      }),
                      title: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        width:
                            400, // Ancho del contenedor para pantallas grandes
                        child: Text(
                          _ajusteExpanded
                              ? 'Mostrar mas . . .'
                              : 'Mostrar menos . . .',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.blueAccent),
                        ),
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          width:
                              400, // Ancho del contenedor para pantallas grandes
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Alinea a la izquierda
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const SizedBox(
                                  height: 20,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 4.0),
                                  child: Text(
                                    'Componente en cuestion o equipo',
                                    style: TextStyle(
                                      fontSize: 18.0, // Tamaño de fuente
                                      fontWeight: FontWeight.bold, // Negrita
                                      color: Colors.black, // Color del texto
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    RadioListTile<int>(
                                      title: const Text('1- No Aplica'),
                                      value: 1,
                                      groupValue: _selectedAjuste,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedAjuste = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4,
                                          vertical:
                                              -4), // Ajusta el tamaño visual
                                      materialTapTargetSize: MaterialTapTargetSize
                                          .shrinkWrap, // Reduce el tamaño del área de toque
                                    ),
                                    RadioListTile<int>(
                                      title: const Text(
                                          '2- Pendiente (no iniciada)'),
                                      value: 2,
                                      groupValue: _selectedAjuste,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedAjuste = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('3- Incompleta'),
                                      value: 3,
                                      groupValue: _selectedAjuste,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedAjuste = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('4- Terminada'),
                                      value: 4,
                                      groupValue: _selectedAjuste,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedAjuste = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Checkbox: Sustitución Temporal
                CheckboxListTile(
                  title: const Text("Sustitución Temporal"),
                  value: _sustitucionTemporal,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value != null && value) {
                        _remplazoDefinitivo = false;
                        _remplazoDefinitivoExpanded = true;
                      }

                      _sustitucionTemporal = value!;
                      _sustitucionTemporalExpanded = true;
                    });
                  },
                ),

                if (_sustitucionTemporal)
                  SizedBox(
                    width: 400,
                    child: ExpansionTile(
                      onExpansionChanged: (value) => setState(() {
                        _sustitucionTemporalExpanded = !value;
                      }),
                      title: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        width:
                            400, // Ancho del contenedor para pantallas grandes
                        child: Text(
                          _sustitucionTemporalExpanded
                              ? 'Mostrar mas . . .'
                              : 'Mostrar menos . . .',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.blueAccent),
                        ),
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          width:
                              400, // Ancho del contenedor para pantallas grandes
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Alinea a la izquierda
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const SizedBox(
                                  height: 20,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 4.0),
                                  child: Text(
                                    'Componente en cuestion o equipo',
                                    style: TextStyle(
                                      fontSize: 18.0, // Tamaño de fuente
                                      fontWeight: FontWeight.bold, // Negrita
                                      color: Colors.black, // Color del texto
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    RadioListTile<int>(
                                      title: const Text('1- No Aplica'),
                                      value: 1,
                                      groupValue: _selectedSustitucionTemporal,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedSustitucionTemporal = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4,
                                          vertical:
                                              -4), // Ajusta el tamaño visual
                                      materialTapTargetSize: MaterialTapTargetSize
                                          .shrinkWrap, // Reduce el tamaño del área de toque
                                    ),
                                    RadioListTile<int>(
                                      title: const Text(
                                          '2- Pendiente (no iniciada)'),
                                      value: 2,
                                      groupValue: _selectedSustitucionTemporal,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedSustitucionTemporal = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('3- Incompleta'),
                                      value: 3,
                                      groupValue: _selectedSustitucionTemporal,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedSustitucionTemporal = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('4- Terminada'),
                                      value: 4,
                                      groupValue: _selectedSustitucionTemporal,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedSustitucionTemporal = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                                if (_selectedSustitucionTemporal == 2 ||
                                    _selectedSustitucionTemporal == 3)
                                  DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Impedimento',
                                      border: OutlineInputBorder(),
                                    ),
                                    value: _selectedImpedimento,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedImpedimento = newValue;
                                      });
                                    },
                                    items: _impedimentos
                                        .map<DropdownMenuItem<String>>(
                                            (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value.length > 35
                                              ? "${value.substring(0, 35)}..."
                                              : value,
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      );
                                    }).toList(),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, seleccione un impedimento';
                                      }
                                      return null;
                                    },
                                  ),
                                if (_selectedImpedimento == "Otro")
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: TextFormField(
                                      controller: _otroController,
                                      decoration: const InputDecoration(
                                        labelText: 'Especifique otro',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (_selectedImpedimento == "Otro" &&
                                            (value == null || value.isEmpty)) {
                                          return 'Por favor, especifique el impedimento';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Checkbox: Remplazo Definitivo
                CheckboxListTile(
                  title: const Text("Remplazo Definitivo"),
                  value: _remplazoDefinitivo,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value != null && value) {
                        _sustitucionTemporal = false;
                        _sustitucionTemporalExpanded = true;
                      }

                      _remplazoDefinitivo = value!;
                      _remplazoDefinitivoExpanded = true;
                    });
                  },
                ),

                if (_remplazoDefinitivo)
                  SizedBox(
                    width: 400,
                    child: ExpansionTile(
                      onExpansionChanged: (value) => setState(() {
                        _remplazoDefinitivoExpanded = !value;
                      }),
                      title: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        width:
                            400, // Ancho del contenedor para pantallas grandes
                        child: Text(
                          _remplazoDefinitivoExpanded
                              ? 'Mostrar mas . . .'
                              : 'Mostrar menos . . .',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.blueAccent),
                        ),
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          width:
                              400, // Ancho del contenedor para pantallas grandes
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Alinea a la izquierda
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText:
                                        'Componente en cuestion o equipo',
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
                                  onSaved: (value) {
                                    componenteRemplazoDefinitivo = value!;
                                  },
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Por favor, ingrese el título';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 4.0),
                                  child: Text(
                                    'Preventivo',
                                    style: TextStyle(
                                      fontSize: 18.0, // Tamaño de fuente
                                      fontWeight: FontWeight.bold, // Negrita
                                      color: Colors.black, // Color del texto
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    RadioListTile<int>(
                                      title: const Text('1- No Aplica'),
                                      value: 1,
                                      groupValue: _selectedPreventivo,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedPreventivo = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4,
                                          vertical:
                                              -4), // Ajusta el tamaño visual
                                      materialTapTargetSize: MaterialTapTargetSize
                                          .shrinkWrap, // Reduce el tamaño del área de toque
                                    ),
                                    RadioListTile<int>(
                                      title: const Text(
                                          '2- Pendiente (no iniciada)'),
                                      value: 2,
                                      groupValue: _selectedPreventivo,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedPreventivo = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('3- Incompleta'),
                                      value: 3,
                                      groupValue: _selectedPreventivo,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedPreventivo = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('4- Terminada'),
                                      value: 4,
                                      groupValue: _selectedPreventivo,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedPreventivo = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 4.0),
                                  child: Text(
                                    'Correctivo',
                                    style: TextStyle(
                                      fontSize: 18.0, // Tamaño de fuente
                                      fontWeight: FontWeight.bold, // Negrita
                                      color: Colors.black, // Color del texto
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    RadioListTile<int>(
                                      title: const Text('1- No Aplica'),
                                      value: 1,
                                      groupValue: _selectedCorrectivo,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedCorrectivo = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4,
                                          vertical:
                                              -4), // Ajusta el tamaño visual
                                      materialTapTargetSize: MaterialTapTargetSize
                                          .shrinkWrap, // Reduce el tamaño del área de toque
                                    ),
                                    RadioListTile<int>(
                                      title: const Text(
                                          '2- Pendiente (no iniciada)'),
                                      value: 2,
                                      groupValue: _selectedCorrectivo,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedCorrectivo = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('3- Incompleta'),
                                      value: 3,
                                      groupValue: _selectedCorrectivo,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedCorrectivo = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    RadioListTile<int>(
                                      title: const Text('4- Terminada'),
                                      value: 4,
                                      groupValue: _selectedCorrectivo,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedCorrectivo = value!;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text(
                        "Consumibles o refacciones \n"
                        "requeridas",
                        style: TextStyle(
                          fontSize: 18.0, // Tamaño de fuente
                          fontWeight: FontWeight.bold, // Negrita
                          color: Colors.black, // Color del texto
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _numeroParteController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Parte',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _cantidadController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _agregarRefaccion,
                  child: const Text('Agregar Refacción'),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text(
                        'Refacciones Agregadas:',
                        style: TextStyle(
                          fontSize: 18.0, // Tamaño de fuente
                          fontWeight: FontWeight.bold, // Negrita
                          color: Colors.black, // Color del texto
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _refacciones.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Text('No hay refacciones agregadas.'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _refacciones.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                                '${_refacciones[index].numeroParte} - Cantidad: ${_refacciones[index].cantidad}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  _refacciones.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),

                const SizedBox(
                  height: 20,
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text(
                        'Datos Adicionales:',
                        style: TextStyle(
                          fontSize: 18.0, // Tamaño de fuente
                          fontWeight: FontWeight.bold, // Negrita
                          color: Colors.black, // Color del texto
                        ),
                      ),
                    ],
                  ),
                ),
                // Campo de Frecuencia
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                      "Cada cuanto tiempo es necesaria la operación expresada en días"),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _frecuenciaController,
                    decoration: const InputDecoration(
                      labelText: 'Frecuencia (días)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 20),

                // Campo de Tiempo Estimado
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                      "El tiempo estándar esperado para completar la actividad/operación en horas y minutos"),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _tiempoHorasController,
                          decoration: const InputDecoration(
                            labelText: 'Horas',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _tiempoMinutosController,
                          decoration: const InputDecoration(
                            labelText: 'Minutos',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Campo de Comentarios
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _comentariosController,
                    decoration: const InputDecoration(
                      labelText: 'Comentarios',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ),

                const SizedBox(height: 20),

                // Botón de Envío
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      // Aquí se puede procesar la información del formulario
                    }
                  },
                  child: const Text('Enviar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Refaccion {
  String numeroParte;
  int cantidad;

  Refaccion({required this.numeroParte, required this.cantidad});
}
