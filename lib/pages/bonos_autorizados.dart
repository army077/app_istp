import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:logger/logger.dart';
import 'dart:async'; // Importa dart:async

class HojaServicioClass {
  final int idSolicitud;
  final String razonSocial;
  final String ticket;
  final String totalRepeticiones;
  final String bonoGanado;
  final int evaluacionTecnico;
  final bool foraneo;
  final String ponderacionPromedio;
  final String promedioTiempoForma;

  HojaServicioClass({
    required this.idSolicitud,
    required this.razonSocial,
    required this.ticket,
    required this.totalRepeticiones,
    required this.bonoGanado,
    required this.evaluacionTecnico,
    required this.foraneo,
    required this.ponderacionPromedio,
    required this.promedioTiempoForma,
  });

  factory HojaServicioClass.fromJson(Map<String, dynamic> json) {
    return HojaServicioClass(
        idSolicitud: json['id_solicitud'],
        razonSocial: json['razon_social'],
        ticket: json['ticket'],
        totalRepeticiones: json['total_repeticiones'],
        bonoGanado: json['bono_ganado'],
        evaluacionTecnico: json['evaluacion_tecnico'],
        foraneo: json['foraneo'],
        ponderacionPromedio: json['ponderacion_promedio'],
        promedioTiempoForma: json['promedio_tiempo_forma']);
  }
}

class InfoTecnicoClass {
  final int id;
  final String status;
  final String sucursal;
  final String nombreTecnico;
  final String correo;
  final String telefono;
  final String puesto; // Agregamos la propiedad "puesto"
  final String nombreBonos;

  InfoTecnicoClass({
    required this.id,
    required this.status,
    required this.sucursal,
    required this.nombreTecnico,
    required this.correo,
    required this.telefono,
    required this.puesto, // Agregamos la propiedad "puesto"
    required this.nombreBonos,
  });

  factory InfoTecnicoClass.fromJson(Map<String, dynamic> json) {
    return InfoTecnicoClass(
      id: json['id'],
      status: json['status'],
      sucursal: json['sucursal'],
      nombreTecnico: json['nombre_tecnico'],
      correo: json['correo'],
      telefono: json['telefono'],
      puesto: json['puesto'], // Agregamos la propiedad "puesto"
      nombreBonos: json['nombre_bonos'],
    );
  }
}

class BonosAutorizadosClass {
  final int id;
  final String folio;
  final String nombreTecnico;
  final String correoTecnico;
  final String ticket;
  final String razonSocial;
  final bool foraneo;
  final String evaluacion; // Agregamos la propiedad "evaluacion"
  final String noHojas;
  final String monto;
  final String nombrePersona;
  final String correoPersona;
  final int idReporte;
  final String tipoServicio;
  final String nombreEmpleado;
  final String concepto;

  BonosAutorizadosClass({
    required this.id,
    required this.folio,
    required this.nombreTecnico,
    required this.correoTecnico,
    required this.ticket,
    required this.razonSocial,
    required this.foraneo,
    required this.evaluacion, // Agregamos la propiedad "evaluacion"
    required this.noHojas,
    required this.monto,
    required this.nombrePersona,
    required this.correoPersona,
    required this.idReporte,
    required this.tipoServicio,
    required this.nombreEmpleado,
    required this.concepto,
  });

  factory BonosAutorizadosClass.fromJson(Map<String, dynamic> json) {
    return BonosAutorizadosClass(
      id: json['id'],
      folio: json['folio'],
      nombreTecnico: json['nombre_tecnico'],
      correoTecnico: json['correo_tecnico'],
      ticket: json['ticket'],
      razonSocial: json['razon_social'],
      foraneo: json['foraneo'] ?? false,
      evaluacion: json['evaluacion'] ?? "4", // Agregamos la propiedad "puesto"
      noHojas: json['no_hojas'] ?? "1",
      monto: json['monto'],
      nombrePersona: json['nombre_persona'],
      correoPersona: json['correo_persona'],
      idReporte: json['id_reporte'],
      tipoServicio: json['tipo_servicio'],
      nombreEmpleado: json['nombre_empleado'],
      concepto: json['concepto'] ?? "",
    );
  }
}

class BonosAutorizadosPage extends StatefulWidget {
  final String emailTecnico;

  const BonosAutorizadosPage({required this.emailTecnico});

  @override
  // ignore: library_private_types_in_public_api
  _BonosAutorizadosPageState createState() => _BonosAutorizadosPageState();
}

class _BonosAutorizadosPageState extends State<BonosAutorizadosPage> {
  late Future<List<HojaServicioClass>> _hojasServicioFuture;
  late Future<List<InfoTecnicoClass>> _infoTecnicoFuture;
  late Future<List<BonosAutorizadosClass>> _bonosAutorizadosFuture;
  late Completer<List<BonosAutorizadosClass>> _bonosAutorizadosCompleter;

  var logger = Logger();
  List<bool> _isExpandedList = [];
  List<bool> _isExpandedList2 = [];
  List<bool> _isExpandedList3 = [];

  double totalBonos = 0.0;

  final List<String> nombresMeses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre'
  ];

  DateTime now = DateTime.now();
  late String selectedYear;
  late String selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedYear = DateFormat('yyyy').format(now);
    selectedMonth = DateFormat('MM').format(now);
    _bonosAutorizadosCompleter = Completer<List<BonosAutorizadosClass>>();
    _bonosAutorizadosFuture = _bonosAutorizadosCompleter.future;

    _hojasServicioFuture = obtenerHojasServicio(widget.emailTecnico);
    _infoTecnicoFuture =
        obtenerInfoTecnico(widget.emailTecnico).then((infoTecnicos) {
      if (infoTecnicos.isNotEmpty) {
        int idTecnico = infoTecnicos.first.id;
        obtenerBonosAutorizados(selectedYear, selectedMonth, idTecnico)
            .then((bonos) {
          setState(() {
            totalBonos = bonos.fold(
              0.0,
              (sum, bono) => sum + double.parse(bono.monto),
            );
          });
          _bonosAutorizadosCompleter.complete(bonos);
        }).catchError((error) {
          _bonosAutorizadosCompleter.completeError(error);
        });
      } else {
        _bonosAutorizadosCompleter
            .completeError('No hay información del técnico');
      }
      return infoTecnicos;
    });
  }

  Future<List<HojaServicioClass>> obtenerHojasServicio(
      String emailTecnico) async {
    final url =
        'https://teknia.app/api3/checador_bonos/mes_actual/$emailTecnico';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      _isExpandedList = List.generate(jsonData.length, (index) => false);
      return jsonData.map((item) => HojaServicioClass.fromJson(item)).toList();
    } else {
      throw Exception('Error al obtener hojas de servicio');
    }
  }

  Future<List<InfoTecnicoClass>> obtenerInfoTecnico(String emailTecnico) async {
    final url = 'https://teknia.app/api4/bonos_istp/obtener_id/$emailTecnico';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      logger.i("Json Tecnico");
      logger.i(response.body);
      _isExpandedList2 = List.generate(jsonData.length, (index) => false);
      return jsonData.map((item) => InfoTecnicoClass.fromJson(item)).toList();
    } else {
      throw Exception('Error al obtener la información del técnico');
    }
  }

  Future<List<BonosAutorizadosClass>> obtenerBonosAutorizados(
      String anio, String noMes, int idTecnico) async {
    final url = 'https://teknia.app/api4/bonos_desgloce/$anio$noMes$idTecnico';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      logger.i("Json Bonos");
      logger.i(response.body);
      _isExpandedList3 = List.generate(jsonData.length, (index) => false);
      return jsonData
          .map((item) => BonosAutorizadosClass.fromJson(item))
          .toList();
    } else {
      throw Exception('Error al obtener la información del técnico');
    }
  }

  void _actualizarBonosAutorizados() {
    _infoTecnicoFuture.then((infoTecnicos) {
      if (infoTecnicos.isNotEmpty) {
        int idTecnico = infoTecnicos.first.id;
        setState(() {
          _bonosAutorizadosCompleter = Completer<List<BonosAutorizadosClass>>();
          _bonosAutorizadosFuture = _bonosAutorizadosCompleter.future;
          obtenerBonosAutorizados(selectedYear, selectedMonth, idTecnico)
              .then((bonos) {
            setState(() {
              totalBonos = bonos.fold(
                0.0,
                (sum, bono) => sum + double.parse(bono.monto),
              );
            });
            _bonosAutorizadosCompleter.complete(bonos);
          }).catchError((error) {
            _bonosAutorizadosCompleter.completeError(error);
          });
        });
      } else {
        _bonosAutorizadosCompleter
            .completeError('No hay información del técnico');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bonos Autorizados', style: TextStyle(fontSize: 20)),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DropdownButton<String>(
                  value: selectedMonth,
                  items: List.generate(12, (index) {
                    String month = (index + 1).toString().padLeft(2, '0');
                    return DropdownMenuItem<String>(
                      value: month,
                      child: Text(nombresMeses[index]),
                    );
                  }),
                  onChanged: (newMonth) {
                    setState(() {
                      selectedMonth = newMonth!;
                    });
                  },
                ),
                DropdownButton<String>(
                  value: selectedYear,
                  items: List.generate(5, (index) {
                    String year = (now.year - index).toString();
                    return DropdownMenuItem<String>(
                      value: year,
                      child: Text(year),
                    );
                  }),
                  onChanged: (newYear) {
                    setState(() {
                      selectedYear = newYear!;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: _actualizarBonosAutorizados,
                  child: const Text('Actualizar'),
                ),
              ],
            ),
            Expanded(
              child: FutureBuilder<List<BonosAutorizadosClass>>(
                future: _bonosAutorizadosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No hay bonos autorizados este mes.'),
                    );
                  } else {
                    // Agrupando bonos por ticket para determinar si un bono es el segundo
                    Map<String, List<BonosAutorizadosClass>> bonosPorTicket =
                        {};
                    for (var bono in snapshot.data!) {
                      if (bonosPorTicket.containsKey(bono.ticket)) {
                        bonosPorTicket[bono.ticket]!.add(bono);
                      } else {
                        bonosPorTicket[bono.ticket] = [bono];
                      }
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        var bono = snapshot.data![index];
                        var bonosConMismoTicket = bonosPorTicket[bono.ticket]!;
                        var esSegundoBono =
                            bonosConMismoTicket.indexOf(bono) > 0;
                        String montoTexto = esSegundoBono
                            ? 'Ajuste \$ ${bono.monto}'
                            : '\$ ${double.parse(bono.monto).toStringAsFixed(2)}';

                        return Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Tooltip(
                                  message: bono.razonSocial,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (!esSegundoBono) ...[
                                        Text(
                                          bono.razonSocial.length > 23
                                              ? "${bono.razonSocial.substring(0, 21)}..."
                                              : bono.razonSocial,
                                        ),
                                        Text(
                                          'Ticket: ${bono.ticket}, No. Hojas: ${bono.noHojas}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          'Autorizado por: ${bono.nombrePersona}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ] else ...[
                                        Text(
                                          'Concepto: ${bono.concepto}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          'Autorizado por: ${bono.nombrePersona}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              Text(
                                montoTexto,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14.0),
              color: Colors.grey[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total de bonos del mes ${nombresMeses[int.parse(selectedMonth) - 1]}:',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    '\$ ${totalBonos.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
