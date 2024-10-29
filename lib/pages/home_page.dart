import 'package:flutter/material.dart';
import 'package:istp_app/pages/bonos_autorizados.dart';
import 'package:istp_app/pages/checador.dart';
import 'package:istp_app/pages/desgloce_hojas.dart';
import 'package:istp_app/pages/firma_cliente.dart';
import 'package:istp_app/pages/gestor_gastos_main.dart';
import 'package:istp_app/pages/hoja_incidencias.dart';
import 'package:istp_app/pages/hoja_mantenimientos.dart';
import 'package:istp_app/pages/hoja_pendientes.dart';
import 'package:istp_app/pages/hoja_servicio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:istp_app/pages/manttos.dart';
import 'package:istp_app/pages/reporte_calidad.dart';

// Definición de la clase HojaServicio
class HojasServicio {
  final String ticket;
  final String razonSocial;
  final String equipo;
  final String tipoServicio;
  final bool pdfGenerado;
  // Otros campos...

  HojasServicio({
    required this.ticket,
    required this.razonSocial,
    required this.equipo,
    required this.tipoServicio,
    required this.pdfGenerado,
    // Otros campos...
  });
}

Stream<List<HojasServicio>> getHojasDeServicioStream(String userEmail) {
  try {
    var hojasServicioCollection =
        FirebaseFirestore.instance.collection('hojas_servicio');

    // Add a query to filter documents based on the email_tecnico field
    var query =
        hojasServicioCollection.where('email_tecnico', isEqualTo: userEmail);

    return query.snapshots().map((querySnapshot) {
      var hojasServicioList = querySnapshot.docs.map((doc) {
        return HojasServicio(
          ticket: doc['ticket'],
          razonSocial: doc['razon_social'],
          equipo: doc['equipo'],
          tipoServicio: doc['tipo_servicio'],
          pdfGenerado: doc['pdf_generado'],
          // Other fields...
        );
      }).toList();

      // Ordena la lista por el campo pdfGenerado (false primero)
      hojasServicioList.sort((a, b) =>
          a.pdfGenerado.toString().compareTo(b.pdfGenerado.toString()));

      return hojasServicioList;
    });
  } catch (e) {
    print('Error al obtener hojas de servicio: $e');
    return Stream.value([]);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final user = FirebaseAuth.instance.currentUser!;
  // Initialize hojasServicioData to an empty list
  late List<HojasServicio> hojasServicioData = [];

  Future<void> signOutWithGoogle() async {
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
  }

  Future logOut() async {
    FirebaseAuth.instance.signOut();
    await signOutWithGoogle();
  }

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  _HomePageState() {
    hojasServicioData = [];
    getHojasDeServicioStream(user.email ?? "");
  }

  @override
  void initState() {
    super.initState();
    // Fetch data when the widget is created
    getHojasDeServicioStream(user.email ?? "");
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: logOut,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Center(
                  child: Text(
                    'Salir',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder(
              future: getCurrentUser(),
              builder: (context, AsyncSnapshot<User?> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final user = snapshot.data;
                final userName = user?.displayName ?? 'Usuario Desconocido';

                return Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, ${userName.split(' ')[0]}',
                            style: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              // Acción al hacer clic en el botón
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GastosMainPage(
                                      title:
                                          "Gestor"), // Reemplaza TuNuevaPagina() con la clase de la nueva página
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.all(10.0),
                              width: 150.0,
                              height: 60.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: const Color.fromARGB(226, 248, 217, 116),
                              ),
                              child: const Center(
                                child: Text(
                                  "Gestor de Gastos",
                                  style: TextStyle(
                                    color: Colors
                                        .black, // Cambia el color del texto a negro
                                    fontWeight: FontWeight
                                        .bold, // Agrega un peso de fuente si lo deseas
                                  ),
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Acción al hacer clic en el botón
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CalidadPage(), // Reemplaza TuNuevaPagina() con la clase de la nueva página
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.all(10.0),
                              width: 150.0,
                              height: 60.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: const Color.fromARGB(207, 241, 157, 101),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        "Reporte de",
                                        style: TextStyle(
                                          color: Colors
                                              .black, // Cambia el color del texto a negro
                                          fontWeight: FontWeight
                                              .bold, // Agrega un peso de fuente si lo deseas
                                        ),
                                      ),
                                      Text(
                                        "Calidad",
                                        style: TextStyle(
                                          color: Colors
                                              .black, // Cambia el color del texto a negro
                                          fontWeight: FontWeight
                                              .bold, // Agrega un peso de fuente si lo deseas
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              // Acción al hacer clic en el botón
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      // MaintenanceForm(), // Reemplaza TuNuevaPagina() con la clase de la nueva página
                                      HojaMantenimientoPage(),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.all(10.0),
                              width: 150.0,
                              height: 60.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color.fromARGB(125, 125, 134, 126),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        "Reporte de",
                                        style: TextStyle(
                                          color: Colors
                                              .black, // Cambia el color del texto a negro
                                          fontWeight: FontWeight
                                              .bold, // Agrega un peso de fuente si lo deseas
                                        ),
                                      ),
                                      Text(
                                        "Mantenimiento",
                                        style: TextStyle(
                                          color: Colors
                                              .black, // Cambia el color del texto a negro
                                          fontWeight: FontWeight
                                              .bold, // Agrega un peso de fuente si lo deseas
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Hojas de servicio del día:",
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          ContainerBody(
              hojasServicioStream: getHojasDeServicioStream(user.email ?? "")),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Acción al hacer clic en el botón flotante
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Checador(),
            ),
          );
        },
        label: const Text('Checador'),
        icon: const Icon(Icons.car_crash),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 4.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.description),
              onPressed: () {
                // Acción al hacer clic en la primera opción
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HojaServicio(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.notification_add),
              onPressed: () {
                // Acción al hacer clic en la segunda opción
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HojaPendientes(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.attach_money),
              onPressed: () {
                // Acción al hacer clic en la cuarta opción
                if (user.email != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BonosAutorizadosPage(emailTecnico: user.email!),
                    ),
                  );
                } else {
                  // Manejar el caso en el que el usuario no está autenticado o el correo electrónico es nulo
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.work_history),
              onPressed: () {
                // Acción al hacer clic en la cuarta opción
                if (user.email != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HojasServicioPage(emailTecnico: user.email!),
                    ),
                  );
                } else {
                  // Manejar el caso en el que el usuario no está autenticado o el correo electrónico es nulo
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_document),
              onPressed: () {
                // Acción al hacer clic en la tercera opción
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FirmaCliente(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ContainerBody extends StatelessWidget {
  const ContainerBody({super.key, required this.hojasServicioStream});

  final Stream<List<HojasServicio>> hojasServicioStream;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 200,
        child: StreamBuilder<List<HojasServicio>>(
          stream: hojasServicioStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No hay servicios disponibles.'),
              );
            }

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final hojaServicio = snapshot.data![index];
                return buildCard(hojaServicio);
              },
            );
          },
        ),
      ),
    );
  }

  Widget buildCard(HojasServicio hojaServicio) {
    const maxLength = 15; // Ajusta según tus preferencias
    final truncatedRazonSocial = hojaServicio.razonSocial.length > maxLength
        ? '${hojaServicio.razonSocial.substring(0, maxLength)}...'
        : hojaServicio.razonSocial;

    final truncatedTipoServicio = hojaServicio.tipoServicio.length > maxLength
        ? '${hojaServicio.tipoServicio.substring(0, maxLength + 3)}...'
        : hojaServicio.tipoServicio;

    return Container(
      width: 190,
      height: 120, // Ajusta según tus preferencias
      margin: const EdgeInsets.only(right: 16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(truncatedRazonSocial),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('# ${hojaServicio.ticket}'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(truncatedTipoServicio),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(hojaServicio.equipo),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'PDF ',
                      style:
                          const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                      children: <TextSpan>[
                        TextSpan(
                          text: hojaServicio.pdfGenerado
                              ? 'Generado'
                              : 'Pendiente',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!hojaServicio.pdfGenerado)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons
                            .error_outline, // Puedes cambiar este icono según tus preferencias
                        color: Colors
                            .red, // Puedes ajustar el color según tus preferencias
                      ),
                    ),
                ],
              ),

              // Agrega más widgets según sea necesario para mostrar la información de Firebase
            ],
          ),
        ),
      ),
    );
  }
}
