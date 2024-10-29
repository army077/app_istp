import 'package:flutter/material.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  String _progressMessage = 'Se está guardando...';
  double _progressValue = 0.0;

  @override
  void initState() {
    super.initState();
    _simulateRegistration();
  }

  void _simulateRegistration() async {
    for (double i = 0.0; i <= 0.6; i += 0.1) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _progressValue = i;
      });
    }
    // Actualiza el mensaje cuando se completa el tiempo
    setState(() {
      _progressValue = 0.8;
    });

    // Actualiza el mensaje cuando se alcanza el 50% del tiempo
    setState(() {
      _progressMessage = 'Ya casi terminamos...';
    });

    // Espera otros 5 segundos
    await Future.delayed(const Duration(milliseconds: 400));

    // Actualiza el mensaje cuando se completa el tiempo
    setState(() {
      _progressValue = 1.0;
    });

    // Actualiza el mensaje cuando se completa el tiempo
    setState(() {
      _progressMessage = 'Listo!';
    });

    // Espera un poco antes de navegar de vuelta a la página principal
    await Future.delayed(const Duration(milliseconds: 400));

    // Navega de vuelta a la página principal (home)
    // ignore: use_build_context_synchronously
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoja de Servicio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Frase de progreso
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  _progressMessage,
                  style: const TextStyle(fontSize: 24),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Indicador de progreso lineal
            LinearProgressIndicator(
              minHeight: 4,
              backgroundColor: Colors.grey[300],
              value: _progressValue,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
