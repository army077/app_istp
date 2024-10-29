// ignore_for_file: camel_case_types, avoid_print, non_constant_identifier_names, must_be_immutable, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert'; // Para decodificar el JSON
import 'package:http/http.dart' as http; // Para hacer la solicitud HTTP
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class gastoss extends StatefulWidget {
  final String ticket;
  final String idSolicitud;
  const gastoss({Key? key, required this.ticket, required this.idSolicitud})
      : super(key: key);

  @override
  State<gastoss> createState() => _gastossState();
}

class _gastossState extends State<gastoss> {
  final user = FirebaseAuth.instance.currentUser!;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  bool _dataLoaded = false; // Indica si se cargaron datos desde la API

  @override
  void dispose() {
    // Cancela cualquier suscripción o temporizador aquí
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Función para obtener datos de la API
  Future<void> _fetchData() async {
    try {
      setState(() {
        _loading = true; // Cambia a true mientras se cargan los datos
      });
      final response = await http.get(Uri.parse(
          'https://teknia.app/api7/gastos/por_ticket/${widget.ticket}/${user.email}'));
      // final response = await http.get(Uri.parse(
      //     'https://teknia.app/api7/gastos/por_ticket/166400/armando.delarosa@asiarobotica.com'));
      if (response.statusCode == 200) {
        setState(() {
          print("TICKET ---${widget.ticket}");
          print("ID SOLICITUD ---${widget.idSolicitud}");
          _transactions =
              List<Map<String, dynamic>>.from(jsonDecode(response.body));
          _loading = false; // Cambia a false cuando se cargan los datos
          _dataLoaded = true; // Indica que se cargaron datos desde la API
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _loading =
            false; // Asegúrate de cambiar a false incluso si hay un error
      });
    }
  }

  void _newTransaction() {
    // Aquí puedes implementar la lógica para agregar una nueva transacción
  }

  @override
  Widget build(BuildContext context) {
    double totalIncome = 0;
    double totalExpense = 0;
    for (var transaction in _transactions) {
      // if (transaction['facturado']) {
      //   totalExpense += double.parse(transaction['monto']);
      // } else {
      totalIncome += double.parse(transaction['monto']);
      // }
    }

    double balance = totalIncome - totalExpense;

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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            TopNeuCard(
              balance: balance.toStringAsFixed(2),
              income: totalIncome.toStringAsFixed(2),
              expense: totalExpense.toStringAsFixed(2),
              ticket: widget.ticket,
            ),
            Expanded(
              child: Center(
                child: _loading
                    ? const LoadingCircle()
                    : _dataLoaded
                        ? _transactions.isEmpty
                            ? const Text('No hay gastos registrados')
                            : ListView.builder(
                                itemCount: _transactions.length,
                                itemBuilder: (context, index) {
                                  final transaction = _transactions[index];
                                  return MyTransaction(
                                    function: _fetchData,
                                    transactionName: transaction['categoria'],
                                    money: transaction['monto'].toString(),
                                    conceptoApi: transaction['concepto'],
                                    fecha: transaction['fecha'],
                                    expenseOrIncome: transaction['facturado']
                                        ? 'Expense'
                                        : 'Income',
                                    facturado:
                                        transaction['facturado'].toString(),
                                    metodo_pago: transaction['metodo_pago'],
                                    categoria: transaction['categoria'],
                                    id_Sol: widget.idSolicitud,
                                    id: transaction['id'],
                                    concepto: transaction['concepto'] ?? "",
                                  );
                                },
                              )
                        : const Text(
                            'Cargando datos...'), // Mostrar este mensaje mientras se cargan los datos
              ),
            ),
            PlusButton(
              function: _fetchData,
              ticket: widget.ticket, // Pasar el valor del ticket aquí
              idSolicitud: widget.idSolicitud,
              correoTec: user.email ?? "",
              nombreTec: user.displayName ?? "",
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingCircle extends StatelessWidget {
  const LoadingCircle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        height: 25,
        width: 25,
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class TopNeuCard extends StatelessWidget {
  final String balance;
  final String income;
  final String expense;
  final String ticket;

  const TopNeuCard({
    Key? key,
    required this.balance,
    required this.income,
    required this.ticket,
    required this.expense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.grey[300],
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade500,
              offset: const Offset(
                4.0,
                4.0,
              ),
              blurRadius: 15.0,
              spreadRadius: 1.0,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(
                -4.0,
                -4.0,
              ),
              blurRadius: 15.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          'T I C K E T',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          ticket,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.arrow_downward),
                                Column(
                                  children: [
                                    // Text('Gastos totales' + '\$$income'),
                                    Text(' Gastos totales:  \$$income'),
                                  ],
                                ),
                              ],
                            ),
                            // Row(
                            //   children: [
                            //     const Icon(Icons.arrow_downward),
                            //     Column(
                            //       children: [
                            //         const Text('expense'),
                            //         Text('\$$expense'),
                            //       ],
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Función para recortar el texto a 20 caracteres máximo
String recortarTexto(String texto) {
  // Si la longitud del texto es menor o igual a 20, devolverlo tal cual
  if (texto.length <= 30) {
    return texto;
  } else {
    // Recortar a 20 caracteres
    return '${texto.substring(0, 30)}...';
  }
}

// Función para recortar el texto a 20 caracteres máximo
String recortarTexto2(String texto) {
  // Si la longitud del texto es menor o igual a 20, devolverlo tal cual
  print(texto);
  print(texto.length);
  if (texto.length <= 22) {
    return texto;
  } else {
    // Recortar a 20 caracteres
    return '${texto.substring(0, 22)}...';
  }
}

class MyTransaction extends StatefulWidget {
  final Future<void> Function() function;
  final String transactionName;
  final String money;
  final String conceptoApi;
  final String fecha;
  final String facturado;
  final String metodo_pago;
  final String categoria;
  final String id_Sol;
  final int id;
  final String expenseOrIncome;
  final String concepto;

  const MyTransaction({
    Key? key,
    required this.function,
    required this.transactionName,
    required this.money,
    required this.conceptoApi,
    required this.fecha,
    required this.expenseOrIncome,
    required this.facturado,
    required this.metodo_pago,
    required this.categoria,
    required this.id_Sol,
    required this.id,
    required this.concepto,
  }) : super(key: key);

  @override
  _MyTransactionState createState() => _MyTransactionState();
}

class _MyTransactionState extends State<MyTransaction> {
  bool _showMessage = false;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _concepController = TextEditingController();

  final List<String> _categories = [
    'Paquetería',
    'Alimento',
    'Hospedaje/Alojamiento',
    'Uber/Taxi',
    'Combustible',
    'Transporte (Autobus,Avión,etc.)',
    'Casetas',
    'Herramientas',
    'Refacciónes',
    'Otros',
  ];

  @override
  void dispose() {
    _priceController.dispose();
    _concepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Texto predeterminado si transactionName está vacío
    const String defaultTransactionName = 'Transacción sin nombre';
    // Texto predeterminado si money está vacío
    const String defaultMoney = 'Sin monto';

    String formattedDate(String dateString) {
      // Parse la cadena de fecha a un objeto DateTime
      DateTime date = DateTime.parse(dateString);

      // Cree un objeto DateFormat para formatear la fecha
      DateFormat formatter = DateFormat('dd/MM/yyyy');

      // Formatee la fecha y devuélvala como una cadena
      return formatter.format(date);
    }

    void editPrice() {
      // Crea controladores de texto con los valores actuales.
      TextEditingController priceController =
          TextEditingController(text: widget.money);
      TextEditingController concepController =
          TextEditingController(text: widget.conceptoApi);
      String selectedCategory = widget.categoria;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            // Utiliza StatefulBuilder para manejar el estado local del diálogo.
            builder: (context, setState) {
              return AlertDialog(
                title: const Text("Editar"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text("Precio"),
                      TextField(
                        controller: priceController,
                        decoration: const InputDecoration(
                            hintText: "Ingresa el nuevo precio"),
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 20),
                      const Text("Categoría"),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: selectedCategory,
                        onChanged: (String? newValue) {
                          setState(() {
                            // Actualiza la categoría seleccionada
                            selectedCategory = newValue!;
                          });
                        },
                        items: _categories
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text("Concepto"),
                      TextField(
                        controller: concepController,
                        decoration: const InputDecoration(
                            hintText: "Ingresa el nuevo concepto"),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text("Cancelar"),
                    onPressed: () {
                      // Cierra el diálogo
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text("Guardar"),
                    onPressed: () async {
                      // Realiza la lógica de guardado
                      String apiUrl =
                          'https://teknia.app/api7/gastos/${widget.id}';
                      final Map<String, dynamic> actGasto = {
                        'concepto': concepController.text,
                        'monto': priceController.text,
                        'categoria': selectedCategory
                      };

                      try {
                        final response = await http.put(
                          Uri.parse(apiUrl),
                          headers: {"Content-Type": "application/json"},
                          body: json.encode(actGasto),
                        );

                        if (response.statusCode == 200) {
                          // Cierra el diálogo
                          Navigator.of(context).pop();
                          // Llama a la función asincrónica para actualizar los datos en la interfaz de usuario
                          await widget.function();
                        } else {
                          print('Error al crear el gasto: ${response.body}');
                        }
                      } catch (e) {
                        print('Error al conectar con la API: $e');
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showMessage = !_showMessage;
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(15),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[500],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.attach_money_outlined,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              // Utiliza la función recortarTexto para recortar el concepto
                              recortarTexto(widget.concepto.isNotEmpty
                                  ? widget.concepto
                                  : defaultTransactionName),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'Monto: ${widget.money.isNotEmpty ? widget.money : defaultMoney}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      widget.expenseOrIncome == 'expense' ? '+' : '-',
                      style: TextStyle(
                        color: (widget.expenseOrIncome == 'expense'
                            ? Colors.green
                            : Colors.red),
                      ),
                    ),
                  ],
                ),

                // Mostrar el mensaje si _showMessage es verdadero
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_showMessage)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 16), // Icono pequeño
                              const SizedBox(
                                  width:
                                      4), // Espacio entre el icono y el texto
                              Text(
                                'Fecha: ${widget.fecha.isNotEmpty ? formattedDate(widget.fecha) : ""}',
                              ), // Texto
                            ],
                          ),
                        ),
                      if (_showMessage)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Icono principal
                              const Icon(Icons.assignment,
                                  size: 16, color: Colors.black),
                              const SizedBox(
                                  width:
                                      4), // Espacio entre el icono principal y el texto
                              const Text(
                                '¿Facturado?: ',
                                style: TextStyle(
                                    color: Colors.black), // Texto en negro
                              ),
                              // Icono de palomita verde si es true, rojo si es false
                              widget.facturado == 'true'
                                  ? const Icon(Icons.check_circle,
                                      size: 16, color: Colors.green)
                                  : const Icon(Icons.close,
                                      size: 16, color: Colors.red),
                            ],
                          ),
                        ),
                      if (_showMessage)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(Icons.payment,
                                  size: 16), // Icono pequeño
                              const SizedBox(
                                width: 4,
                              ), // Espacio entre el icono y el texto
                              Text(
                                  'Método de pago: ${recortarTexto2(widget.metodo_pago.isNotEmpty ? widget.metodo_pago : "")}'), // Texto
                            ],
                          ),
                        ),
                      if (_showMessage)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(Icons.category,
                                  size: 16), // Icono pequeño
                              const SizedBox(
                                  width:
                                      4), // Espacio entre el icono y el texto
                              Text(
                                'Categoria: ${recortarTexto2(widget.categoria.isNotEmpty ? widget.categoria : "")}',
                              ), // Texto
                            ],
                          ),
                        ),
                      if (_showMessage) const SizedBox(height: 10),
                      if (_showMessage)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, //
                          children: [
                            ElevatedButton(
                              onPressed: editPrice,
                              child: const Text('Editar gasto'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text("¿Eliminar Gasto?"),
                                      content: const Text(
                                          "¿Estás seguro de que quieres eliminar el gasto?"),
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text("Cancelar"),
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(); // Cierra el diálogo
                                          },
                                        ),
                                        TextButton(
                                          child: const Text("Sí"),
                                          onPressed: () async {
                                            try {
                                              // Realiza la lógica de eliminación
                                              String apiUrl =
                                                  'https://teknia.app/api7/gastos/${widget.id}';
                                              final response = await http
                                                  .delete(Uri.parse(apiUrl));

                                              if (response.statusCode == 200) {
                                                // Cierra el diálogo
                                                Navigator.of(context).pop();
                                                // Llama a la función asincrónica para actualizar los datos en la interfaz de usuario
                                                await widget.function();
                                              } else {
                                                print(
                                                    'Error al eliminar el gasto: ${response.body}');
                                              }
                                            } catch (e) {
                                              print(
                                                  'Error al conectar con la API: $e');
                                            }
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: const Color.fromARGB(
                                    131, 255, 47, 32), // Color de fondo
                              ),
                              child: const Text('Borrar gasto'),
                            ),
                          ],
                        ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlusButton extends StatefulWidget {
  final Future<void> Function() function;
  final String ticket;
  final String idSolicitud;
  final TextEditingController _controller = TextEditingController();
  final String correoTec;
  final String nombreTec;

  PlusButton({
    Key? key,
    required this.function,
    required this.ticket,
    required this.idSolicitud,
    required this.correoTec,
    required this.nombreTec,
  }) : super(key: key);

  @override
  _PlusButtonState createState() => _PlusButtonState();
}

class _PlusButtonState extends State<PlusButton> {
  String fecha = '';
  String monto = '';
  String metodoPago = '';
  String facturado = '';
  String categoria = '';
  String concepto = '';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Llamar a la función para mostrar el ModalBottomSheet
        showCustomDialogClutsh(context);
      },
      child: Container(
        height: 55,
        width: 55,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '+',
            style: TextStyle(color: Colors.white, fontSize: 25),
          ),
        ),
      ),
    );
  }

  // Función para mostrar el ModalBottomSheet
  void showCustomDialogClutsh(BuildContext context) {
    showModalBottomSheet(
      context: context,
      clipBehavior: Clip.none,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Theme(
          data: ThemeData(
            colorScheme:
                ColorScheme.light(primary: Colors.grey[800] ?? Colors.grey),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Form(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Agregar Gasto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: widget._controller,
                      decoration: InputDecoration(
                        labelText: 'Fecha y Hora del Gasto',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        constraints: const BoxConstraints(maxHeight: 56.0),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            // Mostrar selector de fecha y hora
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );

                            if (selectedDate != null) {
                              // Mostrar selector de hora
                              final selectedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );

                              if (selectedTime != null) {
                                // Combina la fecha y la hora seleccionadas
                                final dateTime = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  selectedTime.hour,
                                  selectedTime.minute,
                                );

                                // Convertir DateTime a una cadena en formato ISO 8601
                                fecha = dateTime.toIso8601String();

                                // Formatear la fecha para mostrar en el TextFormField
                                final formattedDate =
                                    DateFormat('yyyy-MM-dd HH:mm')
                                        .format(dateTime);

                                // Establecer el valor del TextFormField
                                setState(() {
                                  widget._controller.text = formattedDate;
                                });
                              }
                            }
                          },
                        ),
                      ),
                      onChanged: (value) {
                        try {
                          // Convertir el valor ingresado a DateTime utilizando el formato 'yyyy-MM-dd HH:mm'
                          final dateTime =
                              DateFormat('yyyy-MM-dd HH:mm').parse(value);

                          // Convertir DateTime a una cadena en formato ISO 8601
                          fecha = dateTime.toIso8601String();
                        } catch (e) {
                          print('Error al convertir la fecha y hora: $e');
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Monto \$ MXN',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        constraints: const BoxConstraints(maxHeight: 56.0),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      onChanged: (value) {
                        monto = value;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Método de pago',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        constraints: const BoxConstraints(maxHeight: 60.0),
                      ),
                      items: <String>[
                        'One Card',
                        'Efectivo',
                        'Uber Business',
                        'Tag'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        metodoPago = value ?? '';
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        constraints: const BoxConstraints(maxHeight: 60.0),
                      ),
                      items: <String>[
                        'Paquetería',
                        'Alimento',
                        'Hospedaje/Alojamiento',
                        'Uber/Taxi',
                        'Combustible',
                        'Transporte (Autobus,Avión,etc.)',
                        'Casetas',
                        'Herramientas',
                        'Refacciónes',
                        'Otros',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        categoria = value ?? '';
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Concepto de gasto',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        constraints: const BoxConstraints(maxHeight: 56.0),
                      ),
                      onChanged: (value) {
                        concepto = value;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Facturado',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        constraints: const BoxConstraints(maxHeight: 60.0),
                      ),
                      items: <String>[
                        'Si',
                        'No',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        facturado = value ?? '';
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          print('fecha: $fecha');
                          print('monto: $monto');
                          print('metodo_pago: $metodoPago');
                          print('facturado: $facturado');
                          print('categoria: $categoria');
                          print('Ticket: ${widget.ticket}');
                          print('Concepto: $concepto');

                          const String apiUrl =
                              "https://teknia.app/api7/gastos/";

                          final Map<String, dynamic> gastoData = {
                            "id_solicitud": widget.idSolicitud,
                            'ticket': widget.ticket,
                            'monto': monto,
                            'metodo_pago': metodoPago,
                            'categoria': categoria,
                            'nombre_tecnico': widget.nombreTec,
                            'correo_tecnico': widget.correoTec,
                            'fecha': fecha,
                            'facturado': facturado == 'Si' ? true : false,
                            'concepto': concepto
                          };

                          try {
                            final response = await http.post(
                              Uri.parse(apiUrl),
                              headers: {"Content-Type": "application/json"},
                              body: json.encode(gastoData),
                            );

                            if (response.statusCode == 201) {
                              Navigator.pop(context);
                              await widget.function();
                            } else {
                              print(
                                  'Error al crear el gasto: ${response.body}');
                            }
                          } catch (e) {
                            print('Error al conectar con la API: $e');
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.all(10.0),
                          width: 62.0,
                          height: 20.0,
                          child: const Center(
                            child: Text('Enviar'),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Cierra la página actual
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(10.0),
                          width: 62.0,
                          height: 20.0,
                          child: const Center(
                            child: Text('Cerrar'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
