import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

class HojasServicioPage extends StatefulWidget {
  final String emailTecnico;

  const HojasServicioPage({required this.emailTecnico});

  @override
  // ignore: library_private_types_in_public_api
  _HojasServicioPageState createState() => _HojasServicioPageState();
}

class _HojasServicioPageState extends State<HojasServicioPage> {
  late Future<List<HojaServicioClass>> _hojasServicioFuture;
  List<bool> _isExpandedList = [];
  // Definir una lista de nombres de los meses
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

  @override
  void initState() {
    super.initState();
    _hojasServicioFuture = obtenerHojasServicio(widget.emailTecnico);
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

  void _toggleExpansion(int index) {
    setState(() {
      _isExpandedList[index] = !_isExpandedList[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hojas de Servicio del Mes',
          style: TextStyle(fontSize: 20),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(
            top: 16.0), // Ajusta el valor según sea necesario
        child: FutureBuilder<List<HojaServicioClass>>(
          future: _hojasServicioFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No hay hojas de servicio este mes.');
            } else {
              double totalBonos = 0.0;
              return ListView.builder(
                itemCount:
                    snapshot.data!.length + 1, // +1 para incluir el total
                itemBuilder: (context, index) {
                  if (index < snapshot.data!.length) {
                    // Construye la lista como antes
                    String bonoBase = snapshot.data![index].foraneo
                        ? (475 *
                                double.parse(
                                    snapshot.data![index].totalRepeticiones) *
                                double.parse(
                                    snapshot.data![index].promedioTiempoForma))
                            .toStringAsFixed(2)
                        : (237.5 *
                                double.parse(
                                    snapshot.data![index].totalRepeticiones) *
                                double.parse(
                                    snapshot.data![index].promedioTiempoForma))
                            .toStringAsFixed(2);
                    String bonoPuntualidad = snapshot.data![index].foraneo
                        ? (237.5 *
                                double.parse(
                                    snapshot.data![index].totalRepeticiones) *
                                double.parse(
                                    snapshot.data![index].ponderacionPromedio))
                            .toStringAsFixed(2)
                        : (118.75 *
                                double.parse(
                                    snapshot.data![index].totalRepeticiones) *
                                double.parse(
                                    snapshot.data![index].ponderacionPromedio))
                            .toStringAsFixed(2);
                    String bonoEvaluacion = snapshot.data![index].foraneo
                        ? (237.5 *
                                double.parse(
                                    snapshot.data![index].totalRepeticiones) *
                                snapshot.data![index].evaluacionTecnico /
                                5)
                            .toStringAsFixed(2)
                        : (118.75 *
                                double.parse(
                                    snapshot.data![index].totalRepeticiones) *
                                snapshot.data![index].evaluacionTecnico /
                                5)
                            .toStringAsFixed(2);
                    // Cálculo de los totales parciales
                    String totalTemp = (double.parse(bonoBase) +
                            double.parse(bonoPuntualidad) +
                            double.parse(bonoEvaluacion))
                        .toString();
                    totalBonos += double.parse(totalTemp);
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleExpansion(index),
                          child: ExpansionTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Tooltip(
                                    message: snapshot.data![index].razonSocial,
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              snapshot.data![index].razonSocial
                                                          .length >
                                                      23
                                                  ? "${snapshot.data![index].razonSocial.substring(0, 21)}..."
                                                  : snapshot
                                                      .data![index].razonSocial,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              'Ticket: ${snapshot.data![index].ticket}, No. Hojas: ${snapshot.data![index].totalRepeticiones}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Icon(_isExpandedList[index]
                                ? Icons.expand_less
                                : Icons.expand_more),
                            onExpansionChanged: (isExpanded) =>
                                _toggleExpansion(index),
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Bono Base (reporte en tiempo y forma):',
                                                style: TextStyle(fontSize: 13),
                                              ),
                                              Text(
                                                'Bono por puntualidad:',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                              Text(
                                                'Bono por evaluación del técnico:',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                              Text(
                                                'Total Bono:',
                                                style: TextStyle(fontSize: 15),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '\$ $bonoBase',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color.fromARGB(
                                                    255, 46, 134, 19),
                                              ),
                                            ),
                                            Text(
                                              '\$ $bonoPuntualidad',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color.fromARGB(
                                                    255, 46, 134, 19),
                                              ),
                                            ),
                                            if (snapshot.data![index]
                                                    .evaluacionTecnico >
                                                0)
                                              Text(
                                                '\$ $bonoEvaluacion',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color.fromARGB(
                                                      255, 46, 134, 19),
                                                ),
                                              ),
                                            if (snapshot.data![index]
                                                    .evaluacionTecnico ==
                                                0)
                                              const Text(
                                                'pendiente',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color.fromARGB(
                                                      255, 224, 38, 38),
                                                ),
                                              ),
                                            Text(
                                              '\$ $totalTemp',
                                              style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 10, 10, 10),
                                                  fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    // El último elemento (después de todos los elementos de la lista)
                    // Se utiliza para imprimir el total
                    return Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total de bonos del mes ${nombresMeses[DateTime.now().month - 1]}:',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$ ${totalBonos.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                },
              );
            }
          },
        ),
      ),
    );
  }
}
