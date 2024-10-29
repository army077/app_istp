import 'package:flutter/material.dart';

class ObservacionesPage extends StatelessWidget {
  final String observaciones;
  final TextEditingController _textEditingController = TextEditingController();

  ObservacionesPage({Key? key, required this.observaciones}) : super(key: key) {
    _textEditingController.text = observaciones;
  }

  // void atras(){
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) =>
  //           TrabajoRealizadoPage(trabajoRealizado: 'Valor del campo'),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          // Acción al presionar el botón de retroceso
          String inputText = observaciones;
          Navigator.pop(context, inputText);
          return true; // Permite la navegación hacia atrás
        },
        child: Scaffold(
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
                const Spacer(), // Añadido para espaciar los elementos
                IconButton(
                  icon:
                      const Icon(Icons.check), // Ícono de palomita para guardar
                  onPressed: () {
                    // Lógica para guardar cambios
                    String inputText = _textEditingController.text;
                    Navigator.pop(context, inputText);
                  },
                ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _textEditingController,
                    maxLines: null,
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Observaciones y/o Recomendaciones al Cliente',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
