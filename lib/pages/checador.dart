import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:location/location.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ClockRecord {
  final String id;
  final String userId;
  final Timestamp timestamp;

  ClockRecord({
    required this.id,
    required this.userId,
    required this.timestamp,
  });
}

class Checador extends StatefulWidget {
  const Checador({Key? key}) : super(key: key);

  @override
  State<Checador> createState() => _ChecadorState();
}

class _ChecadorState extends State<Checador> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final user = FirebaseAuth.instance.currentUser!;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  var logger = Logger();

  //GPS
  Location location = Location();
  LocationData? currentLocation;
  late StreamSubscription<LocationData> locationSubscription;

  String _uid = "";
  String _userName = "";
  String _userEmail = "";
  ClockRecord? _currentRecord;
  bool _isSaving = false;

  // Agrega un temporizador
  Timer? _loadingTimer;
  bool _loading = false;

  String? _selectedTransport;
  String? _selectedServicio;
  String? _selectedMotivo;

  final FocusNode _montoUberFocusNode = FocusNode();

  List<ReservaISTP> tuLista = [ReservaISTP(ticket: '', id: 0)];
  String _selectedTicket = '';
  int _selectedId =
      0; // Inicializas con un valor por defecto, podría ser 0 u otro valor apropiado

  bool esUber = false;
  bool esTardeParaChecar = false;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        setState(() {
          _uid = user.uid;
          _userName = user.displayName ?? '';
          _userEmail = user.email ?? '';
          _getCurrentRecord();
          String correoTecnico = user.email ??
              ''; // Obtener el correo del técnico desde el usuario autenticado
          getReservas(correoTecnico);
          // getReservas("pa.ramos@asiarobotica.com");
        });
      }
    });

    initLocation();
  }

  Future<void> getReservas(String tecnico) async {
    final String apiUrl =
        'https://teknia.app/api/reservas_istp/tecnico_agendado/$tecnico/';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        logger.i('Info: ${data},');
        setState(() {
          tuLista = [
            ReservaISTP(id: 0, ticket: ''),
            ...data.map((item) => ReservaISTP.fromJson(item)).toList()
          ];
        });
      } else {
        // Handle error response
        logger.e('Error: ${response.statusCode}');
      }
    } catch (error) {
      // Handle network error
      logger.i('Error: $error');
    }
  }

  bool isSameDay(Timestamp timestamp1, Timestamp timestamp2) {
    DateTime date1 = timestamp1.toDate();
    DateTime date2 = timestamp2.toDate();

    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _getCurrentRecord() async {
    try {
      QuerySnapshot records = await _firestore
          .collection('checador')
          .where('userId', isEqualTo: _uid)
          .where('status', isEqualTo: "Entrada")
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (records.docs.isNotEmpty) {
        var data = records.docs.first.data() as Map<String, dynamic>;
        var id = records.docs.first.id;
        var userId = data['userId'];
        var timestamp = data['timestamp'];
        var timestampNow = Timestamp.now();
        if (isSameDay(timestamp, timestampNow)) {
          setState(() {
            _currentRecord = ClockRecord(
              id: id,
              userId: userId,
              timestamp: timestamp,
            );
            logger.i("Current with data");
          });
        } else {
          setState(() {
            _currentRecord = null;
          });
          logger.i("Current diferent date");
        }
      } else {
        setState(() {
          _currentRecord = null;
        });
        logger.i("Current with no data");
      }
    } catch (e) {
      logger.e('Error getting current record: $e');
      setState(() {
        _currentRecord = null;
      });
    }
  }

  Future<void> initLocation() async {
    try {
      await location.requestPermission();

      locationSubscription =
          location.onLocationChanged.listen((LocationData newLocation) {
        setState(() {
          currentLocation = newLocation;
          // Aquí puedes realizar acciones con la nueva ubicación
          // logger.i(
          //     'Latitud: ${currentLocation?.latitude}, Longitud: ${currentLocation?.longitude}');
        });
      });
    } catch (e) {
      logger.e('Error al obtener permisos de ubicación: $e');
    }
  }

  // Método para agregar un documento
  Future<void> addDocument() async {
    // Inicia el temporizador al comienzo de la operación
    _startLoadingTimer();

    setState(() {
      _isSaving = true;
    });

    try {
      // Obtener valores de la solicitud
      final jsonSolicitud = await getDataSolcitud(_selectedId.toString());
      final String? fechaHoraInicioStr = jsonSolicitud?['fecha_hora_inicio'];
      final String? fechaHoraFinStr = jsonSolicitud?['fecha_hora_final'];

      // Verificar si la cadena no es nula antes de intentar convertirla
      if (fechaHoraInicioStr != null) {
        try {
          // Parsear la fecha y hora en formato ISO 8601 a DateTime
          DateTime fechaHoraInicioUTC = DateTime.parse(fechaHoraInicioStr);

          // Ajustar a la zona horaria de México (UTC-6)
          final mexicoTimeZone = DateTime.now().timeZoneOffset;
          DateTime fechaHoraInicioUTC_6 =
              fechaHoraInicioUTC.add(mexicoTimeZone);

          // Formatear la fecha y hora con el formato correcto antes de parsearlo
          String fechaHoraInicioUTC_6_String =
              DateFormat('yyyy-MM-dd HH:mm:ss.SSSSSS')
                  .format(fechaHoraInicioUTC_6);

          // Parsear la fecha y hora formateada a DateTime
          DateTime fechaHoraInicioLocal =
              DateTime.parse(fechaHoraInicioUTC_6_String);
          logger.i(fechaHoraInicioLocal);

          // Obtener la fecha actual en la zona horaria de México
          DateTime fechaActual = DateTime.now();
          logger.i(fechaActual);

          // Formatear las fechas para comparar solo la parte de la fecha (sin horas)
          String fechaInicioFormatted =
              DateFormat('yyyy-MM-dd').format(fechaHoraInicioLocal);
          String fechaActualFormatted =
              DateFormat('yyyy-MM-dd').format(fechaActual);

          logger.i(fechaInicioFormatted);
          logger.i(fechaActualFormatted);

          // Comparar las fechas
          if (fechaInicioFormatted == fechaActualFormatted) {
            logger.i('La fecha de la solicitud es igual a la fecha actual.');
            // Si la fecha es la misma, podemos revisar si llego conforme se acordó con el cliente
            // Formatear las fechas solo con la hora
            String horaInicioFormatted =
                DateFormat('HH:mm:ss').format(fechaHoraInicioLocal);
            String horaActualFormatted =
                DateFormat('HH:mm:ss').format(fechaActual);

            logger.i(horaInicioFormatted);
            logger.i(horaActualFormatted);

            // Obtener la diferencia de tiempo en horas
            Duration diferenciaDeHoras =
                fechaHoraInicioLocal.difference(fechaActual);

            // Obtener el número total de horas de la diferencia
            int horasTotales = diferenciaDeHoras.inHours;

            // Imprimir el resultado
            logger.i('Diferencia de horas: $horasTotales horas');
            double puntosTotales = 0.0;
            bool llegarTarde = false;
            if (horasTotales < 0) {
              // Llegaste tarde
              horasTotales = horasTotales.abs();
              int totalCreditos = 1;
              double maxCreditosPerder = 0.6;
              double ponderacion = 0.0;
              // No puedes llegar más tarde que 2 hrs
              if (horasTotales > 2) {
              } else {
                ponderacion = (horasTotales * 1) / 2;
                puntosTotales =
                    totalCreditos - (maxCreditosPerder * ponderacion);
              }
              llegarTarde = true;
            } else {
              // Legaste temprano
              horasTotales = horasTotales.abs();
              int totalCreditos = 1;
              double maxCreditosGanar = 0.4;
              // No puedes llegar más de 2 hrs temprano
              if (horasTotales > 2) horasTotales = 2;
              double ponderacion = (horasTotales * 1) / 5;
              puntosTotales = totalCreditos + (maxCreditosGanar * ponderacion);
            }
            logger.i(puntosTotales);

            // Formatea la fecha y hora en el formato deseado
            DateTime fechaHoraInicioLocalUTC = fechaHoraInicioLocal.toUtc();
            String formattedDateTimeLlegadaCliente =
                DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'")
                    .format(fechaHoraInicioLocalUTC);

            // Obtener el número total de horas de la diferencia reales
            int horasTotalesReales = diferenciaDeHoras.inHours;

            int horasTotalesRealesAbs = horasTotalesReales.abs();

            String numeroFormateado =
                horasTotalesRealesAbs.toString().padLeft(2, '0');

            String tiempoAtraso = '${numeroFormateado}:00';

            // ------------------------------------------------------------------ //
            // Formatear la fecha y hora al formato deseado
            // Obtén la fecha y hora actual en UTC+0
            DateTime utcDateTime = DateTime.now().toUtc();

            // Formatea la fecha y hora en el formato deseado
            String formattedDateTime =
                DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(utcDateTime);

            String gasto =
                _montoController.text == '' ? '0' : _montoController.text;

            Map<String, dynamic> params = {
              "id_solicitud": _selectedId,
              "entrada": formattedDateTime,
              "userId": 0,
              "nombre_tecnico": _userName,
              "correo_tecnico": _userEmail,
              "lat_entrada": currentLocation!.latitude,
              "lon_entrada": currentLocation!.longitude,
              "ticket": _selectedTicket,
              "tipo_servicio": _selectedServicio,
              "transporte": _selectedTransport,
              "monto": double.parse(gasto),
              "motivo_tarde": _selectedMotivo,
              "domicilio": "Calle de Ejemplo, Ciudad",
              "hoja_generada": false,
              "llegada_tarde": llegarTarde,
              "llegada_estimada_cliente": formattedDateTimeLlegadaCliente,
              "tiempo_atraso": tiempoAtraso,
              "ponderacion": puntosTotales
            };
            logger.i(params);
            int? nuevoID = await setDataChecador(params);
            if (nuevoID != null) {
              logger.i('Registro creado exitosamente. Nuevo ID: $nuevoID');
              await _firestore.collection('checador').add({
                'ticket': _selectedTicket.toString(),
                'status': "Entrada",
                'entrada': Timestamp.now(),
                'userId': _uid,
                'timestamp': Timestamp.now(),
                'lat_entrada': currentLocation!.latitude,
                'lon_entrada': currentLocation!.longitude,
                'transporte': _selectedTransport,
                'tipo_servicio': _selectedServicio,
                'monto': _montoController.text,
                'motivo_tarde': _selectedMotivo,
                'id_reserva': _selectedId.toString(),
                'id_registro_checador': nuevoID.toString(),
              });
              _textController.clear();
              _montoController.clear();
              _selectedTransport = null;
              _selectedServicio = null;
              _selectedMotivo = null;
              _getCurrentRecord();

              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entrada Registrada'),
                ),
              );
            } else {
              logger.i('Error al crear el registro.');
            }
          } else {
            logger.i('La fecha de la solicitud no es igual a la fecha actual.');
            //Revisar si la checada está en tiempo y forma
            if (fechaHoraFinStr != null) {
              try {
                // Parsear la fecha y hora en formato ISO 8601 a DateTime
                DateTime fechaHoraFinUTC = DateTime.parse(fechaHoraFinStr);

                // Ajustar a la zona horaria de México (UTC-6)
                final mexicoTimeZone = DateTime.now().timeZoneOffset;
                DateTime fechaHoraFinUTC_6 =
                    fechaHoraFinUTC.add(mexicoTimeZone);

                // Formatear la fecha y hora con el formato correcto antes de parsearlo
                String fechaHoraFinUTC_6_String =
                    DateFormat('yyyy-MM-dd HH:mm:ss.SSSSSS')
                        .format(fechaHoraFinUTC_6);

                // Parsear la fecha y hora formateada a DateTime
                DateTime fechaHoraFinLocal =
                    DateTime.parse(fechaHoraFinUTC_6_String);
                logger.i(fechaHoraFinLocal);

                // Obtener la fecha actual en la zona horaria de México
                DateTime fechaActualFin = DateTime.now();

                // Comparar las fechas directamente sin formatear
                if (fechaActualFin.isBefore(fechaHoraFinLocal)) {
                  // Estamos en tiempo
                  logger.i(
                      'La fecha de la solicitud es después de la fecha actual.');
                  String fechaDummieStr =
                      DateFormat('yyyy-MM-dd').format(fechaActualFin);

                  DateTime fechaDummie =
                      DateTime.parse('${fechaDummieStr} 10:00:00.000');

                  // Formatear las fechas solo con la hora
                  String horaInicioFormatted =
                      DateFormat('HH:mm:ss').format(fechaDummie);
                  String horaActualFormatted =
                      DateFormat('HH:mm:ss').format(fechaActualFin);

                  logger.i(horaInicioFormatted);
                  logger.i(horaActualFormatted);

                  // Obtener la diferencia de tiempo en horas
                  Duration diferenciaDeHoras =
                      fechaDummie.difference(fechaActualFin);

                  // Obtener el número total de horas de la diferencia
                  int horasTotales = diferenciaDeHoras.inHours;

                  // Imprimir el resultado
                  logger.i('Diferencia de horas: $horasTotales horas');
                  double puntosTotales = 0.0;
                  bool llegarTarde = false;
                  if (horasTotales < 0) {
                    // Llegaste tarde
                    horasTotales = horasTotales.abs();
                    int totalCreditos = 1;
                    double maxCreditosPerder = 0.6;
                    double ponderacion = 0.0;
                    // No puedes llegar más tarde que 2 hrs
                    if (horasTotales > 2) {
                    } else {
                      ponderacion = (horasTotales * 1) / 2;
                      puntosTotales =
                          totalCreditos - (maxCreditosPerder * ponderacion);
                    }
                    llegarTarde = true;
                  } else {
                    // Legaste temprano
                    horasTotales = horasTotales.abs();
                    int totalCreditos = 1;
                    double maxCreditosGanar = 0.4;
                    // No puedes llegar más de 2 hrs temprano
                    if (horasTotales > 2) horasTotales = 2;
                    double ponderacion = (horasTotales * 1) / 5;
                    puntosTotales =
                        totalCreditos + (maxCreditosGanar * ponderacion);
                  }
                  logger.i(puntosTotales);

                  // Formatea la fecha y hora en el formato deseado
                  DateTime fechaDummieUTC = fechaDummie.toUtc();
                  String formattedDateTimeLlegadaCliente =
                      DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'")
                          .format(fechaDummieUTC);

                  // Obtener el número total de horas de la diferencia reales
                  int horasTotalesReales = diferenciaDeHoras.inHours;

                  int horasTotalesRealesAbs = horasTotalesReales.abs();

                  String numeroFormateado =
                      horasTotalesRealesAbs.toString().padLeft(2, '0');

                  String tiempoAtraso = '${numeroFormateado}:00';

                  // ------------------------------------------------------------------ //
                  // Formatear la fecha y hora al formato deseado
                  // Obtén la fecha y hora actual en UTC+0
                  DateTime utcDateTime = DateTime.now().toUtc();

                  // Formatea la fecha y hora en el formato deseado
                  String formattedDateTime =
                      DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'")
                          .format(utcDateTime);

                  String gasto =
                      _montoController.text == '' ? '0' : _montoController.text;

                  Map<String, dynamic> params = {
                    "id_solicitud": _selectedId,
                    "entrada": formattedDateTime,
                    "userId": 0,
                    "nombre_tecnico": _userName,
                    "correo_tecnico": _userEmail,
                    "lat_entrada": currentLocation!.latitude,
                    "lon_entrada": currentLocation!.longitude,
                    "ticket": _selectedTicket,
                    "tipo_servicio": _selectedServicio,
                    "transporte": _selectedTransport,
                    "monto": double.parse(gasto),
                    "motivo_tarde": _selectedMotivo,
                    "domicilio": "Calle de Ejemplo, Ciudad",
                    "hoja_generada": false,
                    "llegada_tarde": llegarTarde,
                    "llegada_estimada_cliente": formattedDateTimeLlegadaCliente,
                    "tiempo_atraso": tiempoAtraso,
                    "ponderacion": puntosTotales,
                  };
                  logger.i(params);
                  int? nuevoID = await setDataChecador(params);
                  if (nuevoID != null) {
                    logger
                        .i('Registro creado exitosamente. Nuevo ID: $nuevoID');
                    await _firestore.collection('checador').add({
                      'ticket': _selectedTicket.toString(),
                      'status': "Entrada",
                      'entrada': Timestamp.now(),
                      'userId': _uid,
                      'timestamp': Timestamp.now(),
                      'lat_entrada': currentLocation!.latitude,
                      'lon_entrada': currentLocation!.longitude,
                      'transporte': _selectedTransport,
                      'tipo_servicio': _selectedServicio,
                      'monto': _montoController.text,
                      'motivo_tarde': _selectedMotivo,
                      'id_reserva': _selectedId.toString(),
                      'id_registro_checador': nuevoID.toString(),
                    });
                    _textController.clear();
                    _montoController.clear();
                    _selectedTransport = null;
                    _selectedServicio = null;
                    _selectedMotivo = null;
                    _getCurrentRecord();

                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Entrada Registrada'),
                      ),
                    );
                  } else {
                    logger.i('Error al crear el registro.');
                  }
                } else {
                  logger.i('La fecha de la solicitud ya se pasó.');
                  String fechaDummieStr =
                      DateFormat('yyyy-MM-dd').format(fechaActualFin);

                  DateTime fechaDummie =
                      DateTime.parse('${fechaDummieStr} 10:00:00.000');

                  // Formatear las fechas solo con la hora
                  String horaInicioFormatted =
                      DateFormat('HH:mm:ss').format(fechaDummie);
                  String horaActualFormatted =
                      DateFormat('HH:mm:ss').format(fechaActualFin);

                  logger.i(horaInicioFormatted);
                  logger.i(horaActualFormatted);

                  // Obtener la diferencia de tiempo en horas
                  Duration diferenciaDeHoras =
                      fechaDummie.difference(fechaActualFin);

                  // Obtener el número total de horas de la diferencia
                  int horasTotales = diferenciaDeHoras.inHours;

                  // Imprimir el resultado
                  logger.i('Diferencia de horas: $horasTotales horas');
                  double puntosTotales = 0.0;
                  bool llegarTarde = false;
                  if (horasTotales < 0) {
                    // Llegaste tarde
                    horasTotales = horasTotales.abs();
                    int totalCreditos = 1;
                    double maxCreditosPerder = 0.6;
                    double ponderacion = 0.0;
                    // No puedes llegar más tarde que 2 hrs
                    if (horasTotales > 2) {
                    } else {
                      ponderacion = (horasTotales * 1) / 2;
                      puntosTotales =
                          totalCreditos - (maxCreditosPerder * ponderacion);
                    }
                    llegarTarde = true;
                  } else {
                    // Legaste temprano
                    horasTotales = horasTotales.abs();
                    int totalCreditos = 1;
                    double maxCreditosGanar = 0.4;
                    // No puedes llegar más de 2 hrs temprano
                    if (horasTotales > 2) horasTotales = 2;
                    double ponderacion = (horasTotales * 1) / 5;
                    puntosTotales =
                        totalCreditos + (maxCreditosGanar * ponderacion);
                  }
                  logger.i(puntosTotales);
                  // Formatea la fecha y hora en el formato deseado
                  DateTime fechaDummieUTC = fechaDummie.toUtc();
                  String formattedDateTimeLlegadaCliente =
                      DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'")
                          .format(fechaDummieUTC);

                  // Obtener el número total de horas de la diferencia reales
                  int horasTotalesReales = diferenciaDeHoras.inHours;

                  int horasTotalesRealesAbs = horasTotalesReales.abs();

                  String numeroFormateado =
                      horasTotalesRealesAbs.toString().padLeft(2, '0');

                  String tiempoAtraso = '${numeroFormateado}:00';

                  // ------------------------------------------------------------------ //
                  // Formatear la fecha y hora al formato deseado
                  // Obtén la fecha y hora actual en UTC+0
                  DateTime utcDateTime = DateTime.now().toUtc();

                  // Formatea la fecha y hora en el formato deseado
                  String formattedDateTime =
                      DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'")
                          .format(utcDateTime);

                  String gasto =
                      _montoController.text == '' ? '0' : _montoController.text;

                  Map<String, dynamic> params = {
                    "id_solicitud": _selectedId,
                    "entrada": formattedDateTime,
                    "userId": 0,
                    "nombre_tecnico": _userName,
                    "correo_tecnico": _userEmail,
                    "lat_entrada": currentLocation!.latitude,
                    "lon_entrada": currentLocation!.longitude,
                    "ticket": _selectedTicket,
                    "tipo_servicio": _selectedServicio,
                    "transporte": _selectedTransport,
                    "monto": double.parse(gasto),
                    "motivo_tarde": _selectedMotivo,
                    "domicilio": "Calle de Ejemplo, Ciudad",
                    "hoja_generada": false,
                    "llegada_tarde": llegarTarde,
                    "llegada_estimada_cliente": formattedDateTimeLlegadaCliente,
                    "tiempo_atraso": tiempoAtraso,
                    "ponderacion": puntosTotales,
                  };
                  logger.i(params);
                  int? nuevoID = await setDataChecador(params);
                  if (nuevoID != null) {
                    logger
                        .i('Registro creado exitosamente. Nuevo ID: $nuevoID');
                    await _firestore.collection('checador').add({
                      'ticket': _selectedTicket.toString(),
                      'status': "Entrada",
                      'entrada': Timestamp.now(),
                      'userId': _uid,
                      'timestamp': Timestamp.now(),
                      'lat_entrada': currentLocation!.latitude,
                      'lon_entrada': currentLocation!.longitude,
                      'transporte': _selectedTransport,
                      'tipo_servicio': _selectedServicio,
                      'monto': _montoController.text,
                      'motivo_tarde': _selectedMotivo,
                      'id_reserva': _selectedId.toString(),
                      'id_registro_checador': nuevoID.toString(),
                    });
                    _textController.clear();
                    _montoController.clear();
                    _selectedTransport = null;
                    _selectedServicio = null;
                    _selectedMotivo = null;
                    _getCurrentRecord();

                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Entrada Registrada'),
                      ),
                    );
                  } else {
                    logger.i('Error al crear el registro.');
                  }
                }
              } catch (e) {
                logger.e('Error al convertir la fecha y hora de fin: $e');
              }
            }
          }
        } catch (e) {
          logger.e('Error al convertir la fecha y hora: $e');
        }
      }
    } catch (e) {
      logger.e('Error during clock in: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
      // Cancela el temporizador cuando la operación se completa
      _cancelLoadingTimer();
      setState(() {
        _loading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> getDataSolcitud(String idSolicitud) async {
    final url = 'https://teknia.app/api/reservas_istp/$idSolicitud';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      logger.i(jsonData);
      return jsonData;
    } else {
      throw Exception('Error al obtener hojas de servicio');
    }
  }

  Future<int?> setDataChecador(Map<String, dynamic> params) async {
    const ipServer =
        'https://teknia.app'; // Reemplaza con tu dirección de servidor
    const String port = 'api2';
    const String ruta = '/reloj_checador/';
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
        final int? nuevoID = responseData['id'] as int?;
        return nuevoID;
      } else {
        // Manejar error del servidor
        print('Error del servidor - Código: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      // Manejar errores de red o cualquier otro error
      print('Error: $error');
      return null;
    }
  }

  // Método para obtener la lista de documentos
  Stream<QuerySnapshot> getDocuments() {
    // return _firestore.collection('clock_records').snapshots();
    return _firestore
        .collection('checador')
        .where('userId', isEqualTo: _uid)
        .where('status', isEqualTo: "Entrada")
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots();
  }

  // Método para actualizar un documento
  Future<void> updateDocument(String documentId) async {
    setState(() {
      _isSaving = true;
    });
    try {
      // Obtener el documento actual
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('checador')
          .doc(documentId)
          .get();

      // Obtener el valor de id_registro_checador
      String? idRegistroChecador = documentSnapshot['id_registro_checador'];

      // Verificar si se encontró el valor y no es nulo
      if (idRegistroChecador != null) {
        // El valor existe y no es nulo, puedes continuar con la lógica
        logger.i('Se encontró id_registro_checador: $idRegistroChecador');

        await setDataChecadorSalida(idRegistroChecador);

        await _firestore.collection('checador').doc(documentId).update({
          'salida': Timestamp.now(),
          'status': "Salida",
          'lat_salida': currentLocation!.latitude,
          'lon_salida': currentLocation!.longitude
        });
        _getCurrentRecord();
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salida Registrada'),
          ),
        );
        // Tu lógica adicional aquí
      } else {
        // El valor no se encontró o es nulo, manejar según tus necesidades
        logger.i('No se encontró id_registro_checador o es nulo');
      }
    } catch (e) {
      logger.e('Error during clock out: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> setDataChecadorSalida(String id) async {
    const ipServer =
        'https://teknia.app'; // Reemplaza con tu dirección de servidor
    const String port = 'api2';
    const String ruta = '/reloj_checador/';
    final String url = ipServer + '/' + port + ruta + id;

    // Obtén la fecha y hora actual en UTC+0
    DateTime utcDateTime = DateTime.now().toUtc();

    // Formatea la fecha y hora en el formato deseado
    String formattedDateTime =
        DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(utcDateTime);

    Map<String, String> params = {"salida": formattedDateTime};

    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(params),
      );

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

  Future<void> setDataChecadorPuntual(
      String id, Map<String, dynamic> params) async {
    const ipServer =
        'https://teknia.app'; // Reemplaza con tu dirección de servidor
    const String port = 'api2';
    const String ruta = '/reloj_checador/puntual/';
    final String url = ipServer + '/' + port + ruta + id;

    // Obtén la fecha y hora actual en UTC+0
    DateTime utcDateTime = DateTime.now().toUtc();

    // Formatea la fecha y hora en el formato deseado
    String formattedDateTime =
        DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(utcDateTime);

    Map<String, String> params = {"salida": formattedDateTime};

    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(params),
      );

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

  void consultarHoraLlegada() async {
    logger.i("Cargar info del ticket");
    if (double.parse(_selectedTicket) > 0) {
      final String apiUrl =
          'https://teknia.app/api/reservas_istp/ticket_tecnico/$_selectedTicket/$_userEmail';

      try {
        final response = await http.get(Uri.parse(apiUrl));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);

          // Convertir la fecha ISO a DateTime y ajustar la diferencia horaria manualmente
          DateTime fechaHoraInicio =
              DateTime.parse(data[0]["fecha_hora_inicio"])
                  .toUtc()
                  .subtract(Duration(hours: 6));

          // Obtener la fecha y hora actual en la zona horaria de Guadalajara, Jalisco (GMT-6)
          DateTime ahora = DateTime.now().toUtc().subtract(Duration(hours: 6));

          // Formatear las fechas para comparar solo las fechas
          DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
          String fechaInicioFormateada = formatter.format(fechaHoraInicio);
          String fechaActualFormateada = formatter.format(ahora);
          logger.i("Fecha de Inicio $fechaInicioFormateada");
          logger.i("Fecha Actual $fechaActualFormateada");

          if (fechaInicioFormateada.substring(0, 10) ==
              fechaActualFormateada.substring(0, 10)) {
            // La fecha de inicio es hoy, comparar la hora
            Duration diferencia = fechaHoraInicio.difference(ahora);
            logger.i(diferencia);
            logger.i(diferencia.inMinutes);
            // Si la diferencia es positiva es que llego antes de tiempo
            if (diferencia.inMinutes > 0) {
              logger.i('Llegó puntual (inclusive mucho antes de la hora).');
              esTardeParaChecar = false;
            } else if (diferencia.inMinutes < 0 &&
                diferencia.inMinutes.abs() < 60) {
              logger.i('Llegó puntual (dentro de 1 hora de tolerancia).');
              esTardeParaChecar = false;
            } else {
              logger.i('No llegó puntual (fuera de la hora de tolerancia).');
              esTardeParaChecar = true;
            }
          } else {
            // La fecha de inicio no es hoy, comparar con las 11 AM
            DateTime onceAM =
                DateTime(ahora.year, ahora.month, ahora.day, 11, 0)
                    .toUtc()
                    .subtract(Duration(hours: 6));
            logger.i("Fecha secundaria");
            logger.i("Fecha parecida a la once am $onceAM");
            logger.i(ahora.isBefore(onceAM));
            if (ahora.isBefore(onceAM)) {
              logger.i('Llegó puntual (antes de las 11 AM).');
              esTardeParaChecar = false;
            } else {
              logger.i('No llegó puntual (después de las 11 AM).');
              esTardeParaChecar = true;
            }
          }
        } else {
          // Handle error response
          logger.i('Error: ${response.statusCode}');
        }
      } catch (error) {
        // Handle network error
        logger.i('Error: $error');
      }
    }
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 8,
                    ),
                    //GPS
                    if (currentLocation != null)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Ubicación del GPS 🛰 encontrada 😃',
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Esperando ubicación...'),
                      ),
                    const SizedBox(
                      height: 2,
                    ),
                    //Alert de no hay wifi
                    if (!_loading)
                      const Text("")
                    else
                      const Card(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ListTile(
                              title: Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Text('Sin Internet'),
                              ),
                              trailing: Icon(Icons.error),
                              subtitle: Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Text('No se pudo guardar'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(
                      height: 2,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Ticket',
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                                horizontal: 16.0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              labelStyle: const TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                            value: _selectedTicket,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedTicket = newValue!;
                                // Aquí también actualizas el _selectedId según la reserva seleccionada
                                _selectedId = tuLista
                                    .firstWhere(
                                        (reserva) => reserva.ticket == newValue)
                                    .id;
                                consultarHoraLlegada();
                              });
                            },
                            items: tuLista.map((ReservaISTP item) {
                              return DropdownMenuItem<String>(
                                value: item.ticket,
                                child: Text(item.ticket),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButtonFormField<String>(
                        value: _selectedServicio,
                        onChanged: (value) {
                          _selectedServicio = value!;
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'Garantía',
                            child: Text('Garantía'),
                          ),
                          DropdownMenuItem(
                            value: 'Servicio Pagado',
                            child: Text('Servicio Pagado'),
                          ),
                          DropdownMenuItem(
                            value: 'Instalación y Capacitación',
                            child: Text('Instalación y Capacitación'),
                          ),
                          DropdownMenuItem(
                            value: 'Por Definir',
                            child: Text('Por Definir'),
                          ),
                          DropdownMenuItem(
                            value: 'Expo',
                            child: Text('Expo'),
                          ),
                          DropdownMenuItem(
                            value: 'Capacitación',
                            child: Text('Capacitación'),
                          ),
                          DropdownMenuItem(
                            value: 'Visita a Sucursal',
                            child: Text('Visita a Sucursal'),
                          ),
                          DropdownMenuItem(
                            value: 'Visita a Cliente',
                            child: Text('Visita a Cliente'),
                          ),
                          DropdownMenuItem(
                            value: 'Trabajo Especial',
                            child: Text('Trabajo Especial'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Tipo de Servicio',
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
                          // Función de validación
                          if (value == null || value.isEmpty) {
                            return 'Por favor, selecciona un tipo de servicio'; // Mensaje de error si no se selecciona nada
                          }
                          return null; // La validación es exitosa si se selecciona algo
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButtonFormField<String>(
                        value: _selectedTransport,
                        onChanged: (value) {
                          _selectedTransport = value!;
                          _montoController.text = "";
                          if (value == 'Transporte Empresa' ||
                              value == 'Vehiculo Personal') {
                            esUber = false;
                          } else {
                            esUber = true;
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'Uber',
                            child: Text('Uber'),
                          ),
                          DropdownMenuItem(
                            value: 'Didi',
                            child: Text('Didi'),
                          ),
                          DropdownMenuItem(
                            value: 'Taxi',
                            child: Text('Taxi'),
                          ),
                          DropdownMenuItem(
                            value: 'Transporte Empresa',
                            child: Text('Transporte Empresa'),
                          ),
                          DropdownMenuItem(
                            value: 'Vehiculo Personal',
                            child: Text('Vehiculo Personal'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Medio de Transporte',
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
                          // Función de validación
                          if (value == null || value.isEmpty) {
                            return 'Por favor, selecciona un medio de transporte'; // Mensaje de error si no se selecciona nada
                          }
                          return null; // La validación es exitosa si se selecciona algo
                        },
                      ),
                    ),
                    Visibility(
                      visible: esUber,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          focusNode: _montoUberFocusNode,
                          decoration: InputDecoration(
                            labelText: '\$ Costo del transporte',
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
                            if (value!.isEmpty &&
                                _selectedTransport != 'Transporte Empresa') {
                              return 'Por favor, ingrese el costo';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _montoController.text = value!;
                          },
                          controller: _montoController,
                        ),
                      ),
                    ),

                    Visibility(
                      visible: esTardeParaChecar,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropdownButtonFormField<String>(
                          value: _selectedMotivo,
                          onChanged: (value) {
                            _selectedMotivo = value!;
                          },
                          items: const [
                            DropdownMenuItem(
                              value: '',
                              child: Text(''),
                            ),
                            DropdownMenuItem(
                              value: 'Dirección errónea',
                              child: Text('Dirección errónea'),
                            ),
                            DropdownMenuItem(
                              value: 'Espera de taxi',
                              child: Text('Espera de taxi'),
                            ),
                            DropdownMenuItem(
                              value: 'Espera de uber',
                              child: Text('Espera de uber'),
                            ),
                            DropdownMenuItem(
                              value: 'Falla de vehículo',
                              child: Text('Falla de vehículo'),
                            ),
                            DropdownMenuItem(
                              value: 'Hora errónea',
                              child: Text('Hora errónea'),
                            ),
                            DropdownMenuItem(
                              value: 'Liberación de refacciones',
                              child: Text('Liberación de refacciones'),
                            ),
                            DropdownMenuItem(
                              value: 'Retraso del vuelo',
                              child: Text('Retraso del vuelo'),
                            ),
                            DropdownMenuItem(
                              value: 'Problema con la aerolinea',
                              child: Text('Problema con la aerolinea'),
                            ),
                            DropdownMenuItem(
                              value: 'Toma de vehículo',
                              child: Text('Toma de vehículo'),
                            ),
                            DropdownMenuItem(
                              value: 'Tráfico',
                              child: Text('Tráfico'),
                            ),
                            DropdownMenuItem(
                              value: 'Recoger Paquetería',
                              child: Text('Recoger Paquetería'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Motivos de Llegada Tarde',
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
                            if (value!.isEmpty && esTardeParaChecar) {
                              return 'Por favor, seleccione un motivo';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),
                    ElevatedButton(
                      onPressed: _currentRecord == null && _isSaving == false
                          ? () {
                              if (_formKey.currentState!.validate()) {
                                // Quitar el foco del campo de costo del transporte
                                _montoUberFocusNode.unfocus();
                                _formKey.currentState!.save();
                                addDocument();
                              }
                            }
                          : null,
                      child: const Text('Registrar Entrada'),
                    ),

                    StreamBuilder(
                      stream: getDocuments(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        var documents = snapshot.data?.docs;
                        var timestampNow = Timestamp.now();

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: documents?.length,
                          itemBuilder: (context, index) {
                            var document = documents?[index];
                            String? documentId = document?.id;
                            String itemName = document?['ticket'];
                            String? status = document?['status'];
                            String? userId = document?['userId'];
                            var timestamp = document?['timestamp'];

                            // Filtrar elementos que no tienen la propiedad 'status' o tienen 'status' diferente de 'Salida'
                            if ((status == null || status != 'Salida') &&
                                isSameDay(timestamp, timestampNow) &&
                                user.uid == userId) {
                              return ListTile(
                                title: Text(itemName),
                                subtitle: Row(
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        // Lógica para actualizar el elemento
                                        if (!_loading) {
                                          updateDocument(documentId!);
                                        } else {
                                          logger.i("Nada");
                                        }
                                      },
                                      child: Row(
                                        children: [
                                          !_loading
                                              ? const Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.access_time),
                                                      SizedBox(
                                                        width: 8,
                                                      ),
                                                      Text('Registrar Salida'),
                                                    ],
                                                  ),
                                                )
                                              : // Nombre personalizado
                                              const Text("Pendiente"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              // Si el elemento tiene 'status' igual a 'Salida', no mostrarlo
                              return const SizedBox.shrink();
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Inicia el temporizador
  void _startLoadingTimer() {
    _loadingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Se ejecuta cada 5 segundos
      logger.i('Han pasado 5 segundos y la operación aún no ha terminado.');
      setState(() {
        _loading = true;
      });
    });
  }

  // Cancela el temporizador
  void _cancelLoadingTimer() {
    _loadingTimer?.cancel();
  }

  @override
  void dispose() {
    // Cancela la suscripción al flujo de ubicación cuando el widget se destruye
    locationSubscription.cancel();
    // Asegúrate de cancelar el temporizador cuando se destruye el widget
    _cancelLoadingTimer();
    super.dispose();
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
