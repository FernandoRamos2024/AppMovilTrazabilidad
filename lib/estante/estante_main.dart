import 'package:flutter/material.dart';
import 'package:escaner_qr/estante/mobile_scanner_overlay.dart';
import 'package:escaner_qr/maquinado/maquinado_main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class EstanteHome extends StatefulWidget {
  const EstanteHome({Key? key}) : super(key: key);

  @override
  _EstanteHomeState createState() => _EstanteHomeState();
}

class _EstanteHomeState extends State<EstanteHome> {
  String? selectedEstanteId;

  late List<Map<String, String>> estantes = [];

  @override
  void initState() {
    super.initState();
    fetchEstantes();
  }

  Future<void> fetchEstantes() async {
    final response = await http.get(Uri.parse('${Config.obtenerEstantes}'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['estantes'];
      setState(() {
        estantes = data
            .map((dynamic item) => {
                  'id': item['id'] as String,
                  'nombre': item['nombre'] as String,
                })
            .toList();
        if (estantes.isNotEmpty) {
          selectedEstanteId = estantes[0]['id'];
        }
      });
    } else {
      throw Exception('Falló al obtener datos.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('Estante'),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String mode) {
              if (mode == 'maquinado') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MaquinadoHome()),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'maquinado',
                child: Text('Maquinado'),
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              estantes.isEmpty
              ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
              : Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: DropdownButton<String>(
                    value: selectedEstanteId,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedEstanteId = newValue;
                        });
                      }
                    },
                    items: estantes.map<DropdownMenuItem<String>>((Map<String, String> estante) {
                      return DropdownMenuItem<String>(
                        value: estante['id'],
                        child: Text(
                          estante['nombre']!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BarcodeScannerWithOverlay(
                selectedEstanteId: selectedEstanteId,
              ),
            ),
          );
        },
        child: const Icon(
          Icons.qr_code_scanner,
          color: Colors.red,
        ),
        backgroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}