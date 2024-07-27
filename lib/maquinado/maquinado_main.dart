import 'package:flutter/material.dart';
import 'package:escaner_qr/maquinado/mobile_scanner_overlay.dart';
import 'package:escaner_qr/estante/estante_main.dart';

void main() {
  runApp(
    const MaquinadoApp(),
  );
}

class MaquinadoApp extends StatelessWidget {
  const MaquinadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Escaner QR',
      theme: ThemeData(
        primarySwatch: Colors.red,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.red).copyWith(
          secondary: const Color.fromARGB(255, 255, 168, 168),
        ),
        scaffoldBackgroundColor: Colors.white, // Fondo blanco
        appBarTheme: const AppBarTheme(
          color: Colors.red, // Color de la barra de navegación
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.red), // Color de fondo del botón
          ),
        ),
      ),
      home: const MaquinadoHome(),
    );
  }
}

class MaquinadoHome extends StatelessWidget {
  const MaquinadoHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('Maquinado'),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String mode) {
              if (mode == 'estante') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EstanteHome()),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'estante',
                child: Text('Estante'),
              ),
            ],
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(16.0),
          margin: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/fresadora.png',
                height: 200,
                fit: BoxFit.cover,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BarcodeScannerWithOverlay(),
            ),
          );
        },
        child: const Icon(
          Icons.qr_code_scanner,
          color: Colors.red,
        ), // Icono de la cámara
        backgroundColor: Colors.white, // Color de fondo del botón flotante
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Coloca el botón flotante en la esquina inferior derecha
    );
  }
}