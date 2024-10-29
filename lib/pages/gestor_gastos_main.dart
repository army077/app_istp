// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:istp_app/pages/gestor_gastos.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GastosMainPage extends StatefulWidget {
  const GastosMainPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<GastosMainPage> createState() => _GastosMainPageState();
}

class _GastosMainPageState extends State<GastosMainPage> {
  final user = FirebaseAuth.instance.currentUser!;
  List<String> gastos = [];
  List<String> idSolicitudes = [];
  List<String> filteredGastos = [];
  final TextEditingController _ticketController = TextEditingController();
  bool showButton = false;
  String selectedTicket = '';
  String selectedIdSolicitud = '';
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  int totalSum = 0; // Variable para almacenar la suma total

  @override
  void initState() {
    super.initState();
    filteredGastos = [];
  }

  @override
  void dispose() {
    // Cancela cualquier suscripción o temporizador aquí
    super.dispose();
  }

  void _mostrarModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: 60,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(98, 89, 84, 84),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Buscar ticket',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ticketController,
                              onChanged: (value) async {
                                final ticket = value.trim();
                                setState(() {
                                  showButton = ticket.isNotEmpty;
                                });
                                if (ticket.isNotEmpty) {
                                  final response = await http.get(
                                    Uri.parse(
                                        'https://teknia.app/api/reservas_istp/por_tecnico/${user.email}'),
                                  );
                                  if (response.statusCode == 200) {
                                    final List<dynamic> data =
                                        json.decode(response.body);
                                    setState(() {
                                      filteredGastos = data
                                          .where((element) => element['ticket']
                                              .toString()
                                              .startsWith(ticket))
                                          .map((element) =>
                                              element['ticket'].toString())
                                          .toList();
                                    });
                                  }
                                } else {
                                  setState(() {
                                    filteredGastos = [];
                                  });
                                }
                              },
                              decoration: const InputDecoration(
                                labelText: 'Ticket',
                                prefixIcon: Icon(
                                  Icons.confirmation_number_outlined,
                                  color: Colors.red,
                                ),
                                filled: true,
                                fillColor: Color.fromARGB(29, 156, 156, 156),
                              ),
                            ),
                          ),
                          if (showButton) const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (filteredGastos.isNotEmpty) const SizedBox(height: 20),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredGastos.length,
                        itemBuilder: (BuildContext context, int index) {
                          return ListTile(
                            title: Text(filteredGastos[index]),
                            onTap: () async {
                              final selectedTicket = filteredGastos[index];
                              String selectedIdSolicitud = '';
                              final response = await http.get(
                                Uri.parse(
                                    'https://teknia.app/api/reservas_istp/por_tecnico/${user.email}'),
                              );
                              if (response.statusCode == 200) {
                                final List<dynamic> data =
                                    json.decode(response.body);
                                final ticketData = data.firstWhere(
                                  (element) =>
                                      element['ticket'].toString() ==
                                      selectedTicket,
                                  orElse: () => null,
                                );
                                if (ticketData != null) {
                                  print('ticket: ${ticketData["id"]}');
                                  selectedIdSolicitud =
                                      ticketData["id"].toString();
                                  filteredGastos.clear();
                                } else {
                                  print('Ticket no encontrado');
                                }
                              } else {
                                print('Error al cargar datos');
                              }

                              setState(() {
                                this.selectedTicket = selectedTicket;
                                this.selectedIdSolicitud = selectedIdSolicitud;
                              });
                              _ticketController.clear();
                              gastos.clear();
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => gastoss(
                                    ticket: selectedTicket,
                                    idSolicitud: selectedIdSolicitud,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDatePicker(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, DateTime>>(
      context: context,
      builder: (BuildContext context) => DateSelectionScreen(
        rangeStart: _rangeStart,
        rangeEnd: _rangeEnd,
      ),
    );

    if (result != null) {
      setState(() {
        _rangeStart = result['start'];
        _rangeEnd = result['end'];
      });

      _applyFilter();
    }
  }

  void _applyFilter() async {
    final formattedStartDate = _rangeStart!.toIso8601String().substring(0, 10);
    final formattedEndDate = _rangeEnd!.toIso8601String().substring(0, 10);

    final response = await http.get(
      Uri.parse(
        'https://teknia.app/api7/gastos/por_fecha/${user.email}?fecha_1=$formattedStartDate&fecha_2=$formattedEndDate',
      ),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      int sum = 0;
      for (var entry in data) {
        sum += int.parse(
            entry['total_monto']); // Sumar los valores de "total_monto"
      }
      setState(() {
        gastos = data.map((e) => e['ticket'].toString()).toList();
        idSolicitudes = data.map((e) => e['id_solicitud'].toString()).toList();
        totalSum = sum; // Almacenar la suma total
      });
    } else {
      print('Error al cargar los datos');
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
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "    Gestor de Gastos AR",
                  style: TextStyle(
                    color: Colors.black, // Cambia el color del texto a negro
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(
                    height: 5,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Card(
                            child: InkWell(
                              onTap: () => _showDatePicker(context),
                              child: const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text("Filtro por fecha"),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () {
                            if (gastos.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => gastoss(
                                    ticket: gastos[0],
                                    idSolicitud: idSolicitudes[0],
                                  ),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("\$ $totalSum"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: gastos.length,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => gastoss(
                                ticket: gastos[index],
                                idSolicitud: idSolicitudes[index],
                              ),
                            ),
                          );
                        },
                        child: ListTile(
                          title: Text(gastos[index]),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarModal(context);
        },
        heroTag: 'add_gastos_floating_button',
        backgroundColor: Colors.grey,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}

class DateSelectionScreen extends StatefulWidget {
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  const DateSelectionScreen({Key? key, this.rangeStart, this.rangeEnd})
      : super(key: key);

  @override
  _DateSelectionScreenState createState() => _DateSelectionScreenState();
}

class _DateSelectionScreenState extends State<DateSelectionScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _rangeStart = widget.rangeStart ?? _focusedDay;
    _rangeEnd = widget.rangeEnd ?? _focusedDay;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = focusedDay;
      _focusedDay = focusedDay;
      _rangeStart = start ?? focusedDay;
      _rangeEnd = end ?? focusedDay;
    });
  }

  void _applyFilter() {
    Navigator.of(context).pop({'start': _rangeStart, 'end': _rangeEnd});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 900,
      child: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: _onDaySelected,
            rangeStartDay: _rangeStart,
            rangeSelectionMode: RangeSelectionMode.toggledOn,
            onRangeSelected: _onRangeSelected,
            rangeEndDay: _rangeEnd,
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
          ),
          ElevatedButton(
            onPressed: _applyFilter,
            child: const Text("Aplicar filtro"),
          ),
        ],
      ),
    );
  }
}
