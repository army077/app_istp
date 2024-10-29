import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // Necesario para seleccionar imágenes

class HojaMantenimientoPage extends StatefulWidget {
  @override
  _HojaMantenimientoPageState createState() => _HojaMantenimientoPageState();
}

class _HojaMantenimientoPageState extends State<HojaMantenimientoPage> {
  late TextEditingController _usernameController;
  String _username = '';
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _loadUsername(); // Cargar el valor guardado
    _loadImage(); // Cargar la imagen guardada
  }

  // Cargar el nombre de usuario desde SharedPreferences
  void _loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? ''; // Cargar el valor
      _usernameController.text = _username; // Actualizar el controlador
    });
  }

  // Guardar el nombre de usuario en SharedPreferences
  void _saveUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('username', _usernameController.text); // Guardar el valor
    setState(() {
      _username = _usernameController.text; // Actualizar la UI
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Username guardado'),
    ));
  }

  // Guardar imagen en SharedPreferences
  Future<void> _saveImage(Uint8List imageBytes) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String base64Image = base64Encode(imageBytes);
    await prefs.setString('saved_image', base64Image);
    setState(() {
      _imageBytes = imageBytes;
    });
  }

  // Cargar imagen desde SharedPreferences
  Future<void> _loadImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? base64Image = prefs.getString('saved_image');
    if (base64Image != null) {
      setState(() {
        _imageBytes = base64Decode(base64Image);
      });
    }
  }

  // Seleccionar una imagen desde la galería o cámara
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
        source: ImageSource
            .gallery); // Cambiar a ImageSource.camera si prefieres usar la cámara
    if (pickedFile != null) {
      Uint8List imageBytes = await pickedFile.readAsBytes();
      _saveImage(imageBytes); // Guardar la imagen
    }
  }

  // Eliminar la imagen guardada
  Future<void> _deleteImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_image');
    setState(() {
      _imageBytes = null; // Limpiar la imagen en la UI
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Imagen eliminada'),
    ));
  }

  // Volver a cargar la imagen
  Future<void> _reloadImage() async {
    _pickImage(); // Volver a seleccionar una imagen
  }

  // Mostrar la imagen en un diálogo
  void _showImageDialog() {
    if (_imageBytes != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.memory(_imageBytes!,
                  width: double.infinity, height: 300, fit: BoxFit.cover),
              ButtonBar(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cerrar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose(); // Liberar recursos
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Guardar estado sin Provider'),
        actions: [
          IconButton(
            icon: Icon(Icons.check), // Icono de verificación (palomita)
            onPressed: _saveUsername, // Guardar cuando se presiona
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextField(
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter your username',
                ),
                controller:
                    _usernameController, // Controlador vinculado al TextField
              ),
              SizedBox(height: 20),
              Text('Username guardado: $_username'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Seleccionar Imagen'),
              ),
              SizedBox(height: 20),
              _imageBytes != null
                  ? GestureDetector(
                      onTap: _showImageDialog, // Abrir imagen en diálogo
                      child: Stack(
                        children: [
                          Image.memory(_imageBytes!,
                              width: 200, height: 200), // Mostrar imagen
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                _deleteImage(); // Eliminar imagen
                                Navigator.of(context)
                                    .pop(); // Cerrar el diálogo si está abierto
                              },
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            child: IconButton(
                              icon: Icon(Icons.refresh, color: Colors.blue),
                              onPressed:
                                  _reloadImage, // Volver a seleccionar imagen
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text('No image selected'),
            ],
          ),
        ),
      ),
    );
  }
}
