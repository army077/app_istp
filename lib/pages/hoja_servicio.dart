import 'package:istp_app/pages/hoja_registrar.dart';
import 'package:istp_app/pages/observaciones.dart';
import 'package:istp_app/pages/trabajo_realizado.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:connectivity/connectivity.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/standalone.dart' as tz;
import 'package:logger/logger.dart';

class HojaServicio extends StatefulWidget {
  const HojaServicio({Key? key}) : super(key: key);

  @override
  State<HojaServicio> createState() => _HojaServicioState();
}

class _HojaServicioState extends State<HojaServicio> {
  final user = FirebaseAuth.instance.currentUser!;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var logger = Logger();

  final _formKey = GlobalKey<FormState>();

  List data = [];
  // Initial Selected Value
  String? dropdownValue;
  // List of items in our dropdown menu
  Set<String> tickets = {};
  String idTicket = "";
  String idSolicitud = "";
  String id_registro_checador = "";
  //Bandera solo una vez
  bool primeraVez = false;
  bool paginaSiCargo = false;
  bool guardandoDatos = false;
  bool guardandoBD = false;

  bool _hasInternet = true;
  bool _cargaronLosTickets = true;

  late DateTime? selectedDate;
  final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
  final _timeFormat = DateFormat('hh:mm a');
  final TextEditingController dateController = TextEditingController();
  final TextEditingController _horaLlegadaController = TextEditingController();
  final TextEditingController _horaSalidaController = TextEditingController();
  Map<String, dynamic> maquinas = {};
  Map<String, dynamic> actividades = {};

  final TextEditingController _razonSocialController = TextEditingController();
  final TextEditingController _contactoController = TextEditingController();
  final TextEditingController _correoClienteController =
      TextEditingController();
  final TextEditingController _numeroClienteController =
      TextEditingController();
  final TextEditingController _maquinaController = TextEditingController();
  final TextEditingController _noSerieController = TextEditingController();
  final TextEditingController _horaComidaController = TextEditingController();
  final TextEditingController _hojasServicioController =
      TextEditingController();
  final TextEditingController _trabajoRealizadoController =
      TextEditingController();
  final TextEditingController _observacionesController =
      TextEditingController();

  String? _selectedTipoServicio; // Valor inicial seleccionado

  final List<String> _tiposServicio = [
    'Garantía',
    'Servicio Pagado',
    'Instalación y Capacitación',
    'Por Definir',
    'Expo',
  ];

  String? _selectedLocalidadServicio; // Valor inicial seleccionado

  final List<String> _localidadesServicio = [
    'Local',
    'Foráneo',
  ];

  String? _selectedUltimaHoja; // Valor inicial seleccionado

  final List<String> _ultimaHoja = [
    'Sí',
    'No',
    'Servicio Pendiente',
  ];

  String? _selectedFamilia; // Valor inicial seleccionado

  final List<String> _familiasEq = [
    'Router',
    'Láser Co2',
    'Láser Fibra Óptica',
    'Plasma',
    'Dobladora',
    'Grua Neumática',
    'Externa'
  ];

  String? _selectedEquipo; // Valor inicial seleccionado

  final List<String> _equipo = [];

  String? _selectedMotivo; // Valor inicial seleccionado

  late List<String> _motivoServicio = [];

  String? _selectedClasificacion; // Valor inicial seleccionado

  late List<String> _clasificacionFalla = [];

  String? _selectedCausaRaiz; // Valor inicial seleccionado

  late List<String> _causaRaiz = [];

  String? _selectedEspecificarFalla; // Valor inicial seleccionado

  late List<String> _especificarFalla = [];

  String? _selectedNoTurnos; // Valor inicial seleccionado

  String? _selectedIneficiencia; // Valor inicial seleccionado

  final List<String> _noTurnos = [
    '1 Turno',
    '2 Turnos',
    '3 Turnos',
  ];

  final List<String> _clasificacionIneficiencia = [
    'Adaptación especial',
    'Cliente no cuenta con area adecuada',
    'Documentación',
    'Envío de pieza equivocada',
    'Equipo con daño cosmético',
    'Paquetería con información equivocada',
    'Paquetería no enviada',
    'Pieza fuera de especificaciones',
    'Pieza faltante',
    'Problema funcional del equipo',
    'Problemas de voltaje',
    'Requerimiento especial del cliente'
  ];

  bool mostrarCantidadTurnos = false; // Variable para controlar la visibilidad

  bool mostrarMotivoIneficiencia =
      false; // Variable para controlar la visibilidad

  List<String> selectedTags = [];

  List<String> availableTags = [];

  List<String> tipos = [];

  List<String> tiemposAct = [];

  // Variable global para almacenar los datos
  TiempoTrabajado? tiempoTrabajadoGlobal;
  DiasEstandar? diasEstandarGlobal;

  // Método para agregar un documento
  Future<void> addDocumentAndNavigate(
      Map<String, dynamic> jsonData, BuildContext context) async {
    try {
      // Agregar el documento a Firebase
      await _firestore.collection('hojas_servicio').add(jsonData);
      logger.i("Cargado en firebase!");

      // Navegar a RegistrationPage
      // ignore: use_build_context_synchronously
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const RegistrationPage(),
        ),
      );
    } catch (e) {
      logger.e('Error during clock in: $e');
      // Manejar el error según tus necesidades
    }
  }

  void cargado() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Center(
            child: Text(
              'Hoja de servicio Cargada',
              style: TextStyle(color: Colors.black, fontSize: 22),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
          content: const Text(
            'Se generó el PDF con éxito',
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

  void _submitForm(BuildContext context) async {
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
      // Mostrar cuadro de diálogo de confirmación
      // ignore: use_build_context_synchronously
      bool confirmacion = await mostrarDialogoConfirmacion(context) ?? false;

      if (confirmacion) {
        try {
          // Código para continuar con la generación de la hoja de servicio
          // Formulario válido, realiza la acción deseada
          _formKey.currentState!.save();
          setState(() {
            guardandoBD = true;
          });

          final formattedDate = dateFormatter.format(selectedDate!);
          final formattedDateLlegada = _horaLlegadaController.text;
          final formattedDateSalida = _horaSalidaController.text;

          String razonSocial = _razonSocialController.text;
          String contacto = _contactoController.text;
          String correoCliente = _correoClienteController.text;
          String numeroCliente = _numeroClienteController.text;
          String maquina = _maquinaController.text;
          String noSerie = _noSerieController.text;
          String horaComida = _horaComidaController.text;
          String noHojas = _hojasServicioController.text;
          String trabajoRealizado = _trabajoRealizadoController.text;
          String observaciones = _observacionesController.text;

          String tagsString = selectedTags.join(', ');

          // Eliminar los espacios en blanco
          // String numeroSinEspacios = numeroCliente.replaceAll(' ', '');
          String numeroSinEspacios = '';

          if (numeroCliente.startsWith('+52')) {
            // Tiene el prefijo '+52'
            numeroSinEspacios =
                numeroCliente.replaceAll(RegExp(r'[^0-9]'), '').substring(2);
            logger.i(numeroSinEspacios); // Resultado: '3327536722'
          } else {
            // No tiene el prefijo '+52'
            numeroSinEspacios = numeroCliente.replaceAll(RegExp(r'[^0-9]'), '');
            logger.i(numeroSinEspacios); // Resultado: '3327536722'
          }

          logger.i('ID Ticket: $idTicket');
          logger.i('Fecha: $formattedDate');
          logger.i('Razon Social: $razonSocial');
          logger.i('Contacto: $contacto');
          logger.i('Correo: $correoCliente');
          logger.i('Número de Tel: $numeroSinEspacios');
          logger.i('Maquina: $maquina');
          logger.i('No Serie: $noSerie');
          logger.i('Tipo de Servicio: $_selectedTipoServicio');
          logger.i('Motivo del Servicio: $_selectedMotivo');
          logger.i('Localidad del Servicio: $_selectedLocalidadServicio');
          logger.i('Ultima Hoja: $_selectedUltimaHoja');
          logger.i('Hora de Llegada: $formattedDateLlegada');
          logger.i('Hora de Salida: $formattedDateSalida');
          logger.i('Hora de Comida: $horaComida');
          logger.i('Número de Hojas: $noHojas');
          logger.i('Familia: $_selectedFamilia');
          logger.i('Modelo: $_selectedEquipo');
          logger.i('Clasificación de Falla: $_selectedClasificacion');
          logger.i('Causa Raíz: $_selectedCausaRaiz');
          logger.i('Especificar la Falla: $_selectedEspecificarFalla');
          logger.i('Trabajo Realizado: $trabajoRealizado');
          logger.i('Observaciones: $observaciones');
          logger.i('Actividades: $tagsString');

          String timeString = horaComida;
          String hours = "00";
          String minutes = "00";

          List<String> parts = timeString.split(':');
          if (parts.length == 2) {
            hours = parts[0];
            minutes = parts[1];

            logger.i('Hours: $hours');
            logger.i('Minutes: $minutes');
          } else {
            logger.i('Invalid time format');
          }

          List<String> registroTiempos = [];

          for (String tag in selectedTags) {
            int index = tipos.indexOf(tag);
            if (index != -1) {
              registroTiempos.add(tiemposAct[index].toString());
            }
          }

          logger.i(registroTiempos);

          int sumaTiempos = 0;
          for (String tiempo in registroTiempos) {
            sumaTiempos += int.parse(tiempo);
          }

          String tiempoTotal = sumaTiempos.toString();

          logger.i('Tiempo total: $tiempoTotal');

          // Inicializar la biblioteca 'timezone'
          tz.initializeTimeZones();

          // Obtener la fecha y hora actual en la zona horaria local
          DateTime now = DateTime.now();

          // Obtener la zona horaria GMT-5 (Eastern Standard Time)
          tz.Location gmt_5 = tz.getLocation('America/Mexico_City');

          // Convertir la fecha y hora actual a GMT-5
          tz.TZDateTime gmt_5DateTime = tz.TZDateTime.from(now, gmt_5);

          // Formatear la fecha y hora en GMT-5
          String gmt_5FechaHora =
              DateFormat('yyyy-MM-dd HH:mm:ss').format(gmt_5DateTime);

          logger.i('Fecha y hora actual en GMT-5: $gmt_5FechaHora');

          // Formatear la fecha y hora en GMT-5
          String gmt_5FechaRegistro =
              DateFormat('yyyy-MM-dd').format(gmt_5DateTime);

          DateTime utcDateTime = DateTime.now().toUtc();

          // Formatea la fecha y hora en el formato deseado
          String formattedDateTime =
              DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(utcDateTime);

          // Parsea la hora en formato Flutter
          DateTime parsedHoraLlegada =
              DateFormat('hh:mm a').parse(formattedDateLlegada);

          // Formatea la hora en el nuevo formato "09:00:00"
          String formattedHoraLlegada =
              DateFormat('HH:mm:ss').format(parsedHoraLlegada);

          // Parsea la hora en formato Flutter
          DateTime parsedHoraSalida =
              DateFormat('hh:mm a').parse(formattedDateSalida);

          // Formatea la hora en el nuevo formato "09:00:00"
          String formattedHoraSalida =
              DateFormat('HH:mm:ss').format(parsedHoraSalida);

          int numeroHojas = 0;

          if (noHojas != '') {
            numeroHojas = int.parse(noHojas);
          }

          String tiempoComida = '00:00:00';
          if (int.parse(hours) > 0 && int.parse(hours) < 10) {
            tiempoComida = "0$hours:$minutes:00";
          } else if (int.parse(hours) > 9) {
            tiempoComida = "$hours:$minutes:00";
          }

          String tiempoAct = '00';
          if (int.parse(tiempoTotal) > 0 && int.parse(tiempoTotal) < 10) {
            tiempoAct = "0$tiempoTotal";
          } else if (int.parse(tiempoTotal) > 9) {
            tiempoAct = tiempoTotal;
          }

          int turnosSelect = 0;

          if (_selectedNoTurnos == '1 Turno') {
            turnosSelect = 1;
          } else if (_selectedNoTurnos == '2 Turnos') {
            turnosSelect = 2;
          } else if (_selectedNoTurnos == '3 Turnos') {
            turnosSelect = 3;
          } else {
            turnosSelect = 0;
          }

          Map<String, dynamic> params = {
            "id_solicitud": int.parse(idSolicitud),
            "id_registro_checador": int.parse(id_registro_checador),
            "marca_tiempo": formattedDateTime,
            "fecha_registro": gmt_5FechaRegistro,
            "nombre_tecnico": user.displayName,
            "email_tecnico": user.email,
            "version_app": "2.1.9", // fecha 24/07/2024
            "ticket": '$dropdownValue',
            "ticketId": int.parse(idTicket),
            "razon_social": razonSocial,
            "contacto_empresa": contacto,
            "correo_cliente": correoCliente,
            "telefono_cliente": numeroSinEspacios,
            "modelo": maquina,
            "no_serie": noSerie,
            "tipo_servicio": _selectedTipoServicio ?? "",
            "motivo_servicio": _selectedMotivo ?? "",
            "localidad_servicio": _selectedLocalidadServicio ?? "",
            "ultima_hoja": _selectedUltimaHoja == 'Sí' ? true : false,
            "hora_llegada": formattedHoraLlegada,
            "hora_salida": formattedHoraSalida,
            "tiempo_comida": tiempoComida,
            "familia_eq": _selectedFamilia ?? "",
            "equipo": _selectedEquipo ?? "",
            "clasificacion_falla": _selectedClasificacion ?? "",
            "causa_raiz": _selectedCausaRaiz ?? "",
            "especificar_falla": _selectedEspecificarFalla ?? "",
            "no_turnos": turnosSelect,
            "trabajo_realizo": trabajoRealizado,
            "observaciones": observaciones,
            "actividades": tagsString,
            "tiempo_actividades": "$tiempoAct:30:00",
            "no_hojas": numeroHojas
          };
          logger.i(params);

          int? nuevoID = await setDataHojaServicio(params);
          logger.i("Nuevo ID: $nuevoID");
          await setDataChecadorHojaGenerada(id_registro_checador, nuevoID ?? 0);

          // Crear el mapa con los datos
          final jsonData = {
            'fecha_registro': Timestamp.now(),
            'marca_tiempo': gmt_5FechaHora,
            'nombre_tecnico': user.displayName,
            'email_tecnico': user.email,
            'version_app': "2.1.3", // fecha 05/04/2024
            'fecha': '${formattedDate}T12:00:00.000Z',
            "ticket": '$dropdownValue',
            'ticketId': idTicket,
            'id_solicitud': int.parse(idSolicitud),
            'razon_social': razonSocial,
            'contacto_empresa': contacto,
            'correo_cliente': correoCliente,
            'telefono_cliente': numeroSinEspacios,
            'cargado_bd': false,
            'pdf_generado': false,
            'modelo': maquina,
            'no_serie': noSerie,
            'tipo_servicio': _selectedTipoServicio ?? "",
            'motivo_servicio': _selectedMotivo ?? "",
            'localidad_servicio': _selectedLocalidadServicio ?? "",
            'ultima_hoja': _selectedUltimaHoja ?? "",
            'hora_llegada': formattedDateLlegada,
            'hora_salida': formattedDateSalida,
            'horas': hours,
            'minutos': minutes,
            'familia_eq': _selectedFamilia ?? "",
            'equipo': _selectedEquipo ?? "",
            'clasificacion_falla': _selectedClasificacion ?? "",
            'causa_raiz': _selectedCausaRaiz ?? "",
            'especificar_falla': _selectedEspecificarFalla ?? "",
            'no_turnos': turnosSelect.toString(),
            'actividades_realizadas': trabajoRealizado,
            'observaciones': observaciones,
            'tiempo_comida': horaComida,
            'actividades': tagsString,
            'tiempo_actividades': tiempoTotal,
            'no_hojas': noHojas,
          };

          logger.i(jsonData);

          bool ultimaHoja = jsonData["ultima_hoja"] == 'Sí' ? true : false;
          if (ultimaHoja) {
            await setFinalizarServicio(idSolicitud);
          }

          setState(() {
            guardandoBD = false;
          });

          // ignore: use_build_context_synchronously
          await addDocumentAndNavigate(jsonData, context);
        } catch (error) {
          // Captura cualquier error que pueda ocurrir durante la generación de la hoja de servicio
          // Puedes imprimir el error y mostrar un mensaje al usuario
          // ignore: use_build_context_synchronously
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text(
                    'Hubo un error al generar la hoja de servicio: $error'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        // El usuario canceló la operación
        logger.i('Operación cancelada por el usuario');
      }
    }
  }

  Future<bool?> mostrarDialogoConfirmacion(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar generación de hoja de servicio'),
          content: const Text('¿Estás seguro de generar la hoja de servicio?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Usuario canceló
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Usuario confirmó
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<int?> setDataHojaServicio(Map<String, dynamic> params) async {
    const ipServer =
        'https://teknia.app'; // Reemplaza con tu dirección de servidor
    const String port = 'api3';
    const String ruta = '/hojas_servicio/';
    const String url = ipServer + '/' + port + ruta;

    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(params),
      );

      logger.i('Response status: ${response.statusCode}');
      logger.i('Response body: ${response.body}');

      if (response.statusCode == 201) {
        // Registro creado exitosamente
        final Map<String, dynamic> responseData = json.decode(response.body);
        logger.i(responseData);
        final int? nuevoID = responseData['id'] as int?;
        return nuevoID;
      } else {
        // Manejar error del servidor
        logger.i('Error del servidor - Código: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      // Manejar errores de red o cualquier otro error
      logger.e('Error: $error');
      return null;
    }
  }

  Future<void> setDataChecadorHojaGenerada(String id, int idHoja) async {
    const ipServer =
        'https://teknia.app'; // Reemplaza con tu dirección de servidor
    const String port = 'api2';
    const String ruta = '/reloj_checador/hoja_servicio_generada/';
    final String url = ipServer + '/' + port + ruta + id;

    Map<String, dynamic> params = {
      "id_hoja_servicio": idHoja,
    };

    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(params),
      );

      logger.i('Response status: ${response.statusCode}');
      logger.i('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // El servidor respondió correctamente
        logger.i('Respuesta del servidor: ${response.body}');
      } else {
        // Manejar error del servidor
        logger.i('Error del servidor - Código: ${response.statusCode}');
      }
    } catch (error) {
      // Manejar errores de red o cualquier otro error
      logger.i('Error: $error');
    }
  }

  Future<void> setFinalizarServicio(String id) async {
    const ipServer =
        'https://teknia.app'; // Reemplaza con tu dirección de servidor
    const String port = 'api';
    const String ruta = '/reservas_istp/finalizar/';
    final String url = ipServer + '/' + port + ruta + id;

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // El servidor respondió correctamente
        logger.i('Respuesta del servidor: ${response.body}');
      } else {
        // Manejar error del servidor
        logger.i('Error del servidor - Código: ${response.statusCode}');
      }
    } catch (error) {
      // Manejar errores de red o cualquier otro error
      logger.i('Error: $error');
    }
  }

  Future<List<List<String>>> fetchData(String tecnico) async {
    if (_cargaronLosTickets) {
      return [];
    } else {
      logger.i("Entras aqui");
      try {
        final String apiUrl =
            'https://teknia.app/api2/reloj_checador/registros_disponibles/$tecnico/';
        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as List<dynamic>;
          final dataArray = await Future.wait(data.map<Future<List<String>>>(
            (item) async {
              final ticket = item['ticket']?.toString() ?? '';
              final idSolicitud = item['id_solicitud']?.toString() ?? '';
              final idChecador = item['id']?.toString() ?? '';
              tickets.add(ticket);

              final String ticketUrl =
                  'https://teknia.app/api/reservas_istp/$idSolicitud/';
              final ticketResponse = await http.get(Uri.parse(ticketUrl));

              if (ticketResponse.statusCode == 200) {
                final ticketData = json.decode(ticketResponse.body);
                final idTicket = ticketData['ticketid']?.toString() ?? '';
                final empresa = ticketData['razon_social']?.toString() ?? '';
                final contacto = ticketData['contacto']?.toString() ?? '';
                final correo = ticketData['correo_cliente']?.toString() ?? '';
                final productId = ticketData['productid']?.toString() ?? '';

                _cargaronLosTickets = true;

                return [
                  ticket,
                  empresa,
                  contacto,
                  correo,
                  productId,
                  idTicket,
                  idSolicitud,
                  idChecador
                ];
              } else {
                // Manejar la respuesta de la API del ticket si es necesario
                return [];
              }
            },
          ).toList());

          return dataArray;
        } else {
          // Manejar el caso en que la solicitud no fue exitosa
          logger.i('Error: ${response.statusCode}');
          Fluttertoast.showToast(
            msg: 'Error al cargar los tickets abiertos',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          return [];
        }
      } catch (error) {
        // Manejar errores de red, como la falta de conexión
        logger.i('Error de red: $error');
        Fluttertoast.showToast(
          msg: 'Sin conexión, error al cargar los tickets abiertos',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return [];
      }
    }
  }

  void updateRazonSocial(String ticket) {
    if (ticket != '------------ ticket ------------') {
      logger.i("Ticket SEleccionado: $ticket");
      if (data.isEmpty) {
      } else {
        final ticketData = data.firstWhere(
          (item) => item[0] == ticket,
          orElse: () => ['', '', '', '', '', ''],
        );

        var productId = ticketData.length > 4 ? ticketData[4] : '';
        logger.i(ticketData);
        cargarMaquina(productId, ticketData);
      }
    } else {
      _razonSocialController.text = "";
      _contactoController.text = "";
      _correoClienteController.text = "";
      _maquinaController.text = "";
      _noSerieController.text = "";
      _horaComidaController.text = "";
      _trabajoRealizadoController.text = "";
      _observacionesController.text = "";
    }
    setState(() {});
  }

  void updateEquipos(String familia) async {
    final url = Uri.parse(
        'https://teknia.app/api/actividades_tecnicas/maquinas/$familia');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<String> opciones =
            data.map((item) => item['maquina'] as String).toList();
        setState(() {
          _equipo.clear();
          _equipo.addAll(opciones);
          _selectedEquipo = null; // Restablecer el valor seleccionado
        });
      } else {
        throw Exception('Error al cargar las máquinas');
      }
    } catch (error) {
      logger.i('Error al cargar las máquinas: $error');
    }
  }

  void obtenerTotalHrsServicio(String dropdownValue, String userEmail) async {
    if (dropdownValue != "" && userEmail != "") {
      final url = Uri.parse(
          'https://teknia.app/api2/tiempo_trabajado_ticket/$dropdownValue/$userEmail');
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          List<dynamic> jsonResponse = jsonDecode(response.body);
          if (jsonResponse.isNotEmpty) {
            tiempoTrabajadoGlobal = TiempoTrabajado.fromJson(jsonResponse[0]);
            // Ahora puedes usar tiempoTrabajadoGlobal en cualquier parte del código
            logger.i('Correo Técnico: ${tiempoTrabajadoGlobal!.correoTecnico}');
            logger.i('Ticket: ${tiempoTrabajadoGlobal!.ticket}');
            logger.i(
                'Número de Checadas: ${tiempoTrabajadoGlobal!.numeroDeChecadas}');
            logger.i(
                'Total Horas Activas: ${tiempoTrabajadoGlobal!.totalHorasActivas}');
          } else {
            throw Exception('No data found');
          }
        } else {
          throw Exception('Error al cargar los datos');
        }
      } catch (error) {
        print('Error al cargar los datos: $error');
      }
    }
  }

  void obtenerTiemposStandar(String familia, String equipo) async {
    logger.i("Checar Tiempos");
    if (familia.isNotEmpty && equipo.isNotEmpty) {
      // Codificar los componentes de la URL
      final encodedFamilia = Uri.encodeComponent(familia);
      final encodedEquipo = Uri.encodeComponent(equipo);
      final url = Uri.parse(
          'https://teknia.app/api2/tiempo_standard/$encodedFamilia/$encodedEquipo');
      try {
        final response = await http.get(url);
        logger.i("url");
        logger.i(url.toString());
        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse = jsonDecode(response.body);
          logger.i(jsonResponse);
          diasEstandarGlobal = DiasEstandar.fromJson(jsonResponse);
          // Ahora puedes usar diasEstandarGlobal en cualquier parte del código
          logger.i('Dias Estandar: ${diasEstandarGlobal!.diasEstandar}');

          //HACER COMPARACION Y DECIDIR SI ES TRUE
          if (tiempoTrabajadoGlobal!.numeroDeChecadas >=
              int.parse(diasEstandarGlobal!.diasEstandar)) {
            mostrarMotivoIneficiencia = true;
          } else {
            mostrarMotivoIneficiencia = false;
          }
        } else {
          logger.i('Error al cargar los datos: ${response.statusCode}');
        }
      } catch (error) {
        print('Error al cargar los datos: $error');
      }
    }
  }

  void updateMotivos(String servicio) async {
    if (servicio != '------------ servicio ------------') {
      logger.i(servicio);
      _selectedMotivo = null;
      _motivoServicio.clear(); // Limpiar la lista de modelos

      _selectedClasificacion = null;
      _clasificacionFalla.clear();
      _clasificacionFalla = [];

      _selectedCausaRaiz = null;
      _causaRaiz.clear(); // Limpiar la lista de modelos
      _causaRaiz = [];

      _selectedEspecificarFalla = null;
      _especificarFalla.clear(); // Limpiar la lista de modelos
      _especificarFalla = [];

      if (servicio == 'Garantía') {
        _motivoServicio = [
          'Instalación de Refacción',
          'Diagnóstico',
          'Envío a Taller',
        ];
      } else if (servicio == 'Servicio Pagado') {
        _motivoServicio = [
          'Instalación de Refacción',
          'Envío a Taller',
          'Diagnóstico',
          'Capacitación',
          'Reubicación de Equipo',
          'Mantenimiento Preventivo',
          'Mantenimiento Correctivo'
        ];
      } else if (servicio == 'Instalación y Capacitación') {
        _motivoServicio = ['Instalación de Equipo', 'Capacitación'];
      } else if (servicio == 'Por Definir') {
        _motivoServicio = [
          'Instalación de Refacción',
          'Diagnóstico',
          'Envío a Taller',
          'Reubicación de Equipo',
          'Mantenimiento Preventivo',
          'Mantenimiento Correctivo'
        ];
      } else if (servicio == 'Expo') {
        _motivoServicio = [
          'Expo',
        ];
      }

      // setState(() {
      //   _selectedMotivo =
      //       _motivoServicio.first; // Actualizar el valor seleccionado

      //   _selectedClasificacion =
      //       _clasificacionFalla.first; // Actualizar el valor seleccionado

      //   _selectedCausaRaiz =
      //       _causaRaiz.first; // Actualizar el valor seleccionado

      //   _selectedEspecificarFalla =
      //       _especificarFalla.first; // Actualizar el valor seleccionado
      // });
      logger.i(_motivoServicio);
    } else {
      logger.i("El servicio seleccionado es inválido");
    }
    setState(() {
      // Actualiza el estado del widget si es necesario
    });
  }

  void updateClasificacion(String hoja) async {
    if (hoja != '---------- ultima hoja ----------') {
      logger.i(hoja);
      _selectedClasificacion = null;
      _clasificacionFalla.clear(); // Limpiar la lista de modelos

      if (hoja == 'Sí' &&
          (_selectedMotivo == 'Instalación de Refacción' ||
              _selectedMotivo == 'Diagnóstico' ||
              _selectedMotivo == 'Mantenimiento Correctivo')) {
        _clasificacionFalla = [
          'Mano de obra (Operador)',
          'Máquina (Equipo AR)',
          'Material(es)',
          'Falta de mantenimiento',
          'Instalación fuera de estándar',
        ];
      } else {
        _clasificacionFalla = [];

        _selectedCausaRaiz = null;
        _causaRaiz.clear(); // Limpiar la lista de modelos
        _causaRaiz = [];

        _selectedEspecificarFalla = null;
        _especificarFalla.clear(); // Limpiar la lista de modelos
        _especificarFalla = [];
      }

      // setState(() {
      //   _selectedClasificacion =
      //       _clasificacionFalla.first; // Actualizar el valor seleccionado

      //   _selectedCausaRaiz = _causaRaiz.first;

      //   _selectedEspecificarFalla = _especificarFalla.first;
      // });
      logger.i(_clasificacionFalla);
    } else {
      logger.i("Ultima hoja seleccionado es inválido");
    }
    setState(() {
      // Actualiza el estado del widget si es necesario
    });
  }

  void updateClasificacionPorMotivo(String motivo) async {
    if (motivo != '------------ motivo ------------') {
      logger.i(motivo);
      _selectedClasificacion = null;
      _clasificacionFalla.clear(); // Limpiar la lista de modelos

      if (_selectedUltimaHoja == 'Sí' &&
          (motivo == 'Instalación de Refacción' ||
              motivo == 'Diagnóstico' ||
              motivo == 'Mantenimiento Correctivo')) {
        _clasificacionFalla = [
          'Mano de obra (Operador)',
          'Máquina (Equipo AR)',
          'Material(es)',
          'Falta de mantenimiento',
          'Instalación fuera de estándar',
        ];
      } else {
        _clasificacionFalla = [];

        _selectedCausaRaiz = null;
        _causaRaiz.clear(); // Limpiar la lista de modelos
        _causaRaiz = [];

        _selectedEspecificarFalla = null;
        _especificarFalla.clear(); // Limpiar la lista de modelos
        _especificarFalla = [];
      }

      // setState(() {
      //   _selectedClasificacion =
      //       _clasificacionFalla.first; // Actualizar el valor seleccionado

      //   _selectedCausaRaiz = _causaRaiz.first;

      //   _selectedEspecificarFalla = _especificarFalla.first;
      // });
      logger.i(_clasificacionFalla);
    } else {
      logger.i("Ultima hoja seleccionado es inválido");
    }
    setState(() {
      // Actualiza el estado del widget si es necesario
    });
  }

  void updateCausaRaiz(String clasificacion) async {
    if (clasificacion != '---------- clasificacion ----------') {
      logger.i(clasificacion);
      _selectedCausaRaiz = null;
      _causaRaiz.clear(); // Limpiar la lista de modelos

      if (clasificacion == 'Mano de obra (Operador)') {
        _causaRaiz = [
          'Operador no capacitado',
          'Operador no calificado',
          'Error de operación',
          'Uso de máquina con parámetros fuera de rango',
        ];
      } else if (clasificacion == 'Máquina (Equipo AR)') {
        _causaRaiz = [
          'Desgaste',
          'Cumplió su vida útil',
          'Defecto de fabricación',
          'Componente defectuoso de proveedor',
          'Especificación de la máquina no es adecuada',
          'Componente/accesorio fuera de especificación',
        ];
      } else if (clasificacion == 'Material(es)') {
        _causaRaiz = [
          'La especificación del material no es acorde',
          'Método (Uso de la máquina)',
        ];
      } else if (clasificacion == 'Falta de mantenimiento') {
        _causaRaiz = [
          'Falta de mantenimiento preventivo',
          'Daño por mantenimiento por personal no calificado',
          'Uso del equipo bajo condiciones no aptas',
          'Uso de componente o accesorio de apoyo con falla',
        ];
      } else if (clasificacion == 'Instalación fuera de estándar') {
        _causaRaiz = [
          'Piso desnivelado',
          'Máquina instalada en área abierta',
          'Exceso de suciedad',
          'Área no ventilada',
          'Alimentación eléctrica fuera de estándar',
          'Cable de alimentación fuera de especificación',
          'Equipo no aterrizado'
        ];
      } else {
        _causaRaiz = [];
      }

      // setState(() {
      //   _selectedCausaRaiz =
      //       _causaRaiz.first; // Actualizar el valor seleccionado
      // });
      logger.i(_causaRaiz);
    } else {
      logger.i("La clasificación que has seleccionado es inválida");
    }
    setState(() {
      // Actualiza el estado del widget si es necesario
    });
  }

  void updateEspecificarFalla(String causa) async {
    if (causa != '---------- causa raiz ----------') {
      logger.i(causa);
      _selectedEspecificarFalla = null;
      _especificarFalla.clear(); // Limpiar la lista de modelos

      if (causa == 'Componente/accesorio fuera de especificación') {
        _especificarFalla = [
          'Chiller',
          'Sistema de extracción',
          'Sistema SAAP (Incluido en el equipo)',
          'Fuente de alimentación de aíre del cliente',
        ];
      } else if (causa == 'Método (Uso de la máquina)') {
        _especificarFalla = [
          'Uso inadecuado de la máquina',
          'Uso de herramienta de corte inadecuada',
        ];
      } else {
        _especificarFalla = [];
      }

      // setState(() {
      //   _selectedEspecificarFalla =
      //       _especificarFalla.first; // Actualizar el valor seleccionado
      // });
      logger.i(_especificarFalla);
    } else {
      logger.i("La clasificación que has seleccionado es inválida");
    }
    setState(() {
      // Actualiza el estado del widget si es necesario
    });
  }

  void updateActividades(String equipo) async {
    if (equipo != '------------ equipo ------------') {
      logger.i(equipo);
      String actividadesJson =
          await rootBundle.loadString('lib/images/actividades.json');
      actividades = json.decode(actividadesJson);
      final actividad = actividades['actividades'] as List<dynamic>;

      // Buscar el array de máquinas correspondiente a la familia seleccionada
      final actividadesEquipo = actividad.firstWhere(
          (registro) => registro['maquina'] == equipo,
          orElse: () => null);

      if (actividadesEquipo != null) {
        final actividadesList = actividadesEquipo['info'] as List<dynamic>?;

        if (actividadesList != null) {
          tipos = actividadesList
              .map((objeto) => objeto["tipo"].toString())
              .toList();
          tiemposAct = actividadesList
              .map((objeto) => objeto["tiempo"].toString())
              .toList();
          selectedTags.clear(); // Limpiar la lista de modelos
          availableTags.clear();
          availableTags
              .addAll(tipos.cast<String>()); // Agregar nuevas actividades
          logger.i(availableTags);
        } else {
          logger
              .i('No se encontraron actividades para la maquina seleccionada');
        }
      }
    } else {
      selectedTags.clear(); // Limpiar la lista de modelos
      availableTags.clear();
      logger.i("La maquina seleccionada es inválida");
    }
    setState(() {
      // Actualiza el estado del widget si es necesario
    });
  }

  Future<void> cargarMaquina(String productId, List ticketData) async {
    try {
      logger.i(productId);
      final response = await http.get(Uri.parse(
          'https://script.google.com/macros/s/AKfycbzB8XlDFKIzh0LyA8V04OYqVrG0rKcSSm756zTj2opGEiacp6NGRhLWAENwyJ86892E/exec?productId=$productId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i(data);
        _razonSocialController.text =
            ticketData.length > 1 ? ticketData[1] : '';
        _contactoController.text = ticketData.length > 2 ? ticketData[2] : '';
        _correoClienteController.text =
            ticketData.length > 3 ? ticketData[3] : '';

        idTicket = ticketData.length > 5 ? ticketData[5] : '';
        idSolicitud = ticketData.length > 6 ? ticketData[6] : '';
        id_registro_checador = ticketData.length > 7 ? ticketData[7] : '';

        var nombreMaq = data["data"]["nombreMaq"];
        _maquinaController.text = nombreMaq;
        var noSerie = data["data"]["noSerie"];
        _noSerieController.text = noSerie;
        logger.i(idTicket);
        logger.i(idSolicitud);
      } else {
        logger.i('Error: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error: $e');
    }
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
    _razonSocialController.text = "";
    _contactoController.text = "";
    _correoClienteController.text = "";
    _maquinaController.text = "";
    _noSerieController.text = "";
    _horaComidaController.text = "";
    _trabajoRealizadoController.text = "";
    _observacionesController.text = "";
    _cargaronLosTickets = false;
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
      body: FutureBuilder<List<List<String>>>(
        future: fetchData(user.email ?? ''),
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
            return Stack(
              children: [
                SingleChildScrollView(
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
                                  decoration: const InputDecoration(
                                    labelText: 'Ticket',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: tickets
                                      .toList()
                                      .map<DropdownMenuItem<String>>(
                                        (String value) =>
                                            DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      dropdownValue = newValue;
                                      updateRazonSocial(
                                          newValue!); // Agrega esta línea para actualizar la razón social
                                    });
                                  },
                                  validator: (value) {
                                    // Valida si se ha seleccionado una clasificación cuando hay opciones disponibles
                                    if (tickets.isNotEmpty && value == null) {
                                      return 'Por favor, seleccione un ticket';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Razón Social',
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
                                      return 'Por favor, ingrese el cliente';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _razonSocialController.text = value!;
                                  },
                                  controller:
                                      _razonSocialController, // Agrega esta línea
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Maquina',
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
                                      return 'Por favor, ingrese la maquina';
                                    }
                                    // Aquí puedes agregar validaciones adicionales para el formato del correo electrónico
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _maquinaController.text = value!;
                                  },
                                  controller: _maquinaController,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Número de Serie',
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
                                      return 'Por favor, ingrese la serie';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _noSerieController.text = value!;
                                  },
                                  controller:
                                      _noSerieController, // Agrega esta línea
                                ),
                                const SizedBox(height: 16.0),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Contacto',
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
                                      return 'Por favor, ingrese el contacto';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _contactoController.text = value!;
                                  },
                                  controller:
                                      _contactoController, // Agrega esta línea
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Correo del Cliente',
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
                                      return 'Por favor, ingrese el correo';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _correoClienteController.text = value!;
                                  },
                                  controller:
                                      _correoClienteController, // Agrega esta línea
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Teléfono del Cliente',
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
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Por favor, ingrese el teléfono';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _numeroClienteController.text = value!;
                                  },
                                  controller:
                                      _numeroClienteController, // Agrega esta línea
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: dateController,
                                  readOnly: true,
                                  onTap: () {
                                    showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    ).then((selectedDate) {
                                      if (selectedDate != null) {
                                        setState(() {
                                          this.selectedDate = DateTime(
                                            selectedDate.year,
                                            selectedDate.month,
                                            selectedDate.day,
                                          );
                                          dateController.text = dateFormatter
                                              .format(selectedDate);
                                        });
                                      }
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Fecha del Servicio',
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
                                  value: _selectedTipoServicio,
                                  decoration: const InputDecoration(
                                    labelText: 'Tipo de Servicio',
                                    border: OutlineInputBorder(),
                                  ),
                                  items:
                                      _tiposServicio.map((String tipoServicio) {
                                    return DropdownMenuItem<String>(
                                      value: tipoServicio,
                                      child: Text(tipoServicio),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      _selectedTipoServicio = newValue;
                                      updateMotivos(newValue);
                                    }
                                  },
                                  validator: (value) {
                                    // Valida si se ha seleccionado una clasificación cuando hay opciones disponibles
                                    if (_tiposServicio.isNotEmpty &&
                                        value == null) {
                                      return 'Por favor, seleccione un tipo de servicio';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  value: _selectedMotivo,
                                  decoration: const InputDecoration(
                                    labelText: 'Motivo de Servicio',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _motivoServicio.map((String motivo) {
                                    return DropdownMenuItem<String>(
                                      value: motivo,
                                      child: Text(motivo),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedMotivo = newValue;
                                      updateClasificacionPorMotivo(newValue!);
                                    });
                                  },
                                  validator: (value) {
                                    // Valida si se ha seleccionado una clasificación cuando hay opciones disponibles
                                    if (_motivoServicio.isNotEmpty &&
                                        value == null) {
                                      return 'Por favor, seleccione una motivo de servicio';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  value: _selectedLocalidadServicio,
                                  decoration: const InputDecoration(
                                    labelText: 'Localidad del Servicio',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _localidadesServicio
                                      .map((String servicio) {
                                    return DropdownMenuItem<String>(
                                      value: servicio,
                                      child: Text(servicio),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      _selectedLocalidadServicio = newValue;
                                    }
                                  },
                                  validator: (value) {
                                    // Valida si se ha seleccionado una clasificación cuando hay opciones disponibles
                                    if (_localidadesServicio.isNotEmpty &&
                                        value == null) {
                                      return 'Por favor, seleccione una opcion';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  value: _selectedUltimaHoja,
                                  decoration: const InputDecoration(
                                    labelText: '¿Última Hoja?',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _ultimaHoja.map((String servicio) {
                                    return DropdownMenuItem<String>(
                                      value: servicio,
                                      child: Text(servicio),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      _selectedUltimaHoja = newValue;
                                      if (newValue != 'Sí') {
                                        _hojasServicioController.clear();
                                        selectedTags
                                            .clear(); // Limpiar la lista de modelos
                                        availableTags.clear();
                                        mostrarCantidadTurnos = false;
                                        _selectedNoTurnos = null;

                                        mostrarMotivoIneficiencia = false;
                                      } else {
                                        if (_selectedTipoServicio ==
                                            'Instalación y Capacitación') {
                                          mostrarCantidadTurnos = true;
                                          obtenerTotalHrsServicio(
                                              dropdownValue ?? "",
                                              user.email ?? "");
                                        } else {
                                          mostrarCantidadTurnos = false;
                                          _selectedNoTurnos = null;
                                        }
                                      }
                                      updateClasificacion(newValue);
                                    }
                                  },
                                  validator: (value) {
                                    // Valida si se ha seleccionado una clasificación cuando hay opciones disponibles
                                    if (_ultimaHoja.isNotEmpty &&
                                        value == null) {
                                      return 'Por favor, seleccione una opción';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _horaLlegadaController,
                                  readOnly: true,
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                    );
                                    if (time != null) {
                                      setState(() {
                                        _horaLlegadaController.text =
                                            _timeFormat.format(DateTime(1, 1, 1,
                                                time.hour, time.minute));
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Hora de Llegada con el Cliente',
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
                                TextField(
                                  controller: _horaSalidaController,
                                  readOnly: true,
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                    );
                                    if (time != null) {
                                      setState(() {
                                        _horaSalidaController.text =
                                            _timeFormat.format(DateTime(1, 1, 1,
                                                time.hour, time.minute));
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Hora de Salida con el Cliente',
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
                                TextFormField(
                                  controller: _horaComidaController,
                                  decoration: InputDecoration(
                                    labelText: 'Tiempo de comida (hrs)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Por favor ingrese algún texto';
                                    }
                                    return null;
                                  },
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime:
                                          const TimeOfDay(hour: 1, minute: 00),
                                      initialEntryMode:
                                          TimePickerEntryMode.input,
                                      builder: (BuildContext context,
                                          Widget? child) {
                                        return MediaQuery(
                                          data: MediaQuery.of(context).copyWith(
                                              alwaysUse24HourFormat: true),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (time != null) {
                                      setState(() {
                                        _horaComidaController.text =
                                            '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _hojasServicioController,
                                  decoration: InputDecoration(
                                    labelText:
                                        '¿Cuántas hojas de servicio llenaste?',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9]')),
                                  ],
                                  enabled: _selectedUltimaHoja ==
                                      'Sí', // Habilitar cuando se selecciona 'Sí'
                                ),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  value: _selectedFamilia,
                                  decoration: const InputDecoration(
                                    labelText: 'Familia',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _familiasEq.map((String familia) {
                                    return DropdownMenuItem<String>(
                                      value: familia,
                                      child: Text(familia),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedFamilia = newValue;
                                      updateEquipos(
                                          newValue!); // Agrega esta línea para actualizar
                                    });
                                  },
                                  validator: (value) {
                                    // Valida si se ha seleccionado una clasificación cuando hay opciones disponibles
                                    if (_familiasEq.isNotEmpty &&
                                        value == null) {
                                      return 'Por favor, seleccione una familia';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  value: _equipo.contains(_selectedEquipo)
                                      ? _selectedEquipo
                                      : null,
                                  decoration: const InputDecoration(
                                    labelText: 'Modelo',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _equipo.map((String modelo) {
                                    return DropdownMenuItem<String>(
                                      value: modelo,
                                      child: Text(modelo),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedEquipo = newValue;
                                      if (_selectedUltimaHoja == 'Sí' &&
                                          newValue != null) {
                                        updateActividades(newValue);
                                        if (_selectedTipoServicio ==
                                            'Instalación y Capacitación') {
                                          obtenerTiemposStandar(
                                              _selectedFamilia ?? "", newValue);
                                        }
                                      }
                                    });
                                  },
                                  validator: (value) {
                                    if (_equipo.isNotEmpty && value == null) {
                                      return 'Por favor, seleccione un modelo';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  value: _selectedClasificacion,
                                  decoration: const InputDecoration(
                                    labelText: 'Clasificación de Falla',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _clasificacionFalla
                                      .map((String clasificacion) {
                                    return DropdownMenuItem<String>(
                                      value: clasificacion,
                                      child: Text(
                                        clasificacion,
                                        style: const TextStyle(
                                            fontSize:
                                                12), // Establece el tamaño de letra deseado
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedClasificacion = newValue;
                                      updateCausaRaiz(newValue!);
                                    });
                                  },
                                  validator: (value) {
                                    // Valida si se ha seleccionado una clasificación cuando hay opciones disponibles
                                    if (_clasificacionFalla.isNotEmpty &&
                                        value == null) {
                                      return 'Por favor, seleccione una clasificación de falla';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  value: _selectedCausaRaiz,
                                  decoration: const InputDecoration(
                                    labelText: 'Causa Raíz',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _causaRaiz.map((String causa) {
                                    return DropdownMenuItem<String>(
                                      value: causa,
                                      child: Text(
                                        causa,
                                        style: const TextStyle(
                                            fontSize:
                                                12), // Establece el tamaño de letra deseado
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedCausaRaiz = newValue;
                                      updateEspecificarFalla(newValue!);
                                    });
                                  },
                                  validator: (value) {
                                    // Valida si se ha seleccionado una clasificación cuando hay opciones disponibles
                                    if (_causaRaiz.isNotEmpty &&
                                        value == null) {
                                      return 'Por favor, seleccione una clasificación de falla';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  value: _selectedEspecificarFalla,
                                  decoration: const InputDecoration(
                                    labelText:
                                        'Especificar la Falla (si aplica)',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _especificarFalla.map((String falla) {
                                    return DropdownMenuItem<String>(
                                      value: falla,
                                      child: Text(
                                        falla,
                                        style: const TextStyle(
                                            fontSize:
                                                12), // Establece el tamaño de letra deseado
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedEspecificarFalla = newValue;
                                    });
                                  },
                                  validator: (value) {
                                    // Valida si se ha seleccionado una clasificación cuando hay opciones disponibles
                                    if (_especificarFalla.isNotEmpty &&
                                        value == null) {
                                      return 'Por favor, seleccione una clasificación de falla';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                Visibility(
                                  visible:
                                      mostrarCantidadTurnos, // Controla la visibilidad aquí
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedNoTurnos,
                                    decoration: const InputDecoration(
                                      labelText: 'Cantidad de turnos',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _noTurnos.map((String servicio) {
                                      return DropdownMenuItem<String>(
                                        value: servicio,
                                        child: Text(servicio),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedNoTurnos = newValue;
                                        });
                                      }
                                    },
                                    validator: (value) {
                                      // Valida si se ha seleccionado una clasificación cuando hay opciones disponibles
                                      if (mostrarCantidadTurnos &&
                                          value == null) {
                                        return 'Por favor, seleccione una opción';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Visibility(
                                  visible:
                                      mostrarMotivoIneficiencia, // Controla la visibilidad aquí
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedIneficiencia,
                                    decoration: const InputDecoration(
                                      labelText: 'Motivos Ineficiencia',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _clasificacionIneficiencia
                                        .map((String servicio) {
                                      return DropdownMenuItem<String>(
                                        value: servicio,
                                        child: Text(
                                          servicio,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedIneficiencia = newValue;
                                        });
                                      }
                                    },
                                    validator: (value) {
                                      // Valida si se ha seleccionado una clasificación cuando hay opciones disponibles
                                      if (mostrarMotivoIneficiencia &&
                                          value == null) {
                                        return 'Por favor, seleccione una opción';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 14),
                                GestureDetector(
                                  onTap: () async {
                                    logger.i("Trabajo Realizado");
                                    // Navegar a la vista TrabajoRealizadoPage y pasar el valor del campo
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TrabajoRealizadoPage(
                                                trabajoRealizado:
                                                    _trabajoRealizadoController
                                                        .text),
                                      ),
                                    );
                                    // Actualizar el valor del campo con el resultado
                                    if (result != null) {
                                      setState(() {
                                        _trabajoRealizadoController.text =
                                            result;
                                      });
                                    }
                                  },
                                  child: TextFormField(
                                    enabled: false,
                                    maxLines: null,
                                    decoration: InputDecoration(
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              255, 138, 138, 138),
                                        ),
                                      ),
                                      disabledBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              255, 138, 138, 138),
                                        ),
                                      ),
                                      labelText: 'Trabajo Realizado',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 12.0, horizontal: 16.0),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
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
                                        return 'Por favor, ingrese la tarea';
                                      }
                                      return null;
                                    },
                                    onSaved: (value) {
                                      _trabajoRealizadoController.text = value!;
                                    },
                                    controller: _trabajoRealizadoController,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                GestureDetector(
                                  onTap: () async {
                                    logger.i(
                                        "Observaciones y/o Recomendaciones al Cliente");
                                    // Navegar a la vista TrabajoRealizadoPage y pasar el valor del campo
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ObservacionesPage(
                                                  observaciones:
                                                      _observacionesController
                                                          .text)),
                                    );
                                    // Actualizar el valor del campo con el resultado
                                    if (result != null) {
                                      setState(() {
                                        _observacionesController.text = result;
                                      });
                                    }
                                  },
                                  child: TextFormField(
                                    enabled: false,
                                    maxLines: null,
                                    decoration: InputDecoration(
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              255, 138, 138, 138),
                                        ),
                                      ),
                                      disabledBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              255, 138, 138, 138),
                                        ),
                                      ),
                                      labelText:
                                          'Observaciones y/o Recomendaciones al Cliente',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 12.0, horizontal: 16.0),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
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
                                        return 'Por favor, ingrese las observaciones';
                                      }
                                      return null;
                                    },
                                    onSaved: (value) {
                                      _observacionesController.text = value!;
                                    },
                                    controller: _observacionesController,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Actividades Realizadas",
                                      style: TextStyle(
                                        fontSize: 16.0,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8.0,
                                      runSpacing: 4.0,
                                      children: availableTags.map((tag) {
                                        final isSelected =
                                            selectedTags.contains(tag);
                                        return ChoiceChip(
                                          label: Text(
                                            tag,
                                            style: TextStyle(
                                              fontSize: 16.0,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          selected: isSelected,
                                          selectedColor: const Color.fromARGB(
                                              255, 228, 59, 47),
                                          onSelected: (isSelected) {
                                            setState(() {
                                              if (isSelected) {
                                                selectedTags.add(tag);
                                              } else {
                                                selectedTags.remove(tag);
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    _submitForm(context);
                                  },
                                  child: const Text('Enviar'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (guardandoBD) // Muestra el ProgressIndicator si guardandoBD es true
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            );
          }
        },
      ),
    );
  }
}

class TiempoTrabajado {
  final String correoTecnico;
  final String ticket;
  final int numeroDeChecadas;
  final double totalHorasActivas;

  TiempoTrabajado({
    required this.correoTecnico,
    required this.ticket,
    required this.numeroDeChecadas,
    required this.totalHorasActivas,
  });

  factory TiempoTrabajado.fromJson(Map<String, dynamic> json) {
    return TiempoTrabajado(
      correoTecnico: json['correo_tecnico'],
      ticket: json['ticket'],
      numeroDeChecadas: int.parse(json['numero_de_checadas']),
      totalHorasActivas: double.parse(json['total_horas_activas']),
    );
  }
}

class DiasEstandar {
  final String diasEstandar;

  DiasEstandar({
    required this.diasEstandar,
  });

  factory DiasEstandar.fromJson(Map<String, dynamic> json) {
    return DiasEstandar(
      diasEstandar:
          json['no_dias'].toString(), // Convertir a string si es necesario
    );
  }
}
