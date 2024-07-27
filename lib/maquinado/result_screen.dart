import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../config.dart';

class ResultScreen extends StatefulWidget {
  final String qrData;

  ResultScreen({required this.qrData});

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class Area {
  final String id;
  final String nombre;
  final List<Maquina> maquinas;
  final List<Operador> operadores;

  Area({required this.id, required this.nombre, required this.maquinas, required this.operadores});

  factory Area.fromJson(Map<String, dynamic> json) {
    var maquinasJson = json['maquinas'] as List;
    var operadoresJson = json['operadores'] as List;

    List<Maquina> maquinasList = maquinasJson.map((i) => Maquina.fromJson(i)).toList();
    List<Operador> operadoresList = operadoresJson.map((i) => Operador.fromJson(i)).toList();

    return Area(
      id: json['id'],
      nombre: json['nombre'],
      maquinas: maquinasList,
      operadores: operadoresList,
    );
  }
}

class Maquina {
  final String id;
  final String nombre;
  final String estatus;
  final String idArea;

  Maquina({required this.id, required this.nombre, required this.estatus, required this.idArea});

  factory Maquina.fromJson(Map<String, dynamic> json) {
    return Maquina(
      id: json['id'],
      nombre: json['nombre'],
      estatus: json['estatus'],
      idArea: json['id_area'],
    );
  }
}

class Operador {
  final String id;
  final String nombre;
  final String idArea;

  Operador({required this.id, required this.nombre, required this.idArea});

  factory Operador.fromJson(Map<String, dynamic> json) {
    return Operador(
      id: json['id'],
      nombre: json['nombre'],
      idArea: json['id_area'],
    );
  }
}

class Player {
  static play(String src) async {
    final player = AudioPlayer();
    await player.play(AssetSource(src));
  }
}

class _ResultScreenState extends State<ResultScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedArea;
  String? _selectedMachine;
  String? _selectedOperator;
  String? _selectedAction;
  
  bool _isLoading = true;

  List<Area> _areas = [];
  List<Maquina> _filteredMachines = [];
  List<Operador> _filteredOperators = [];

  @override
  void initState() {
    super.initState();
    _fetchAreas();
  }

  Future<void> _fetchAreas() async {
    final response = await http.get(Uri.parse('${Config.obtenerAreas}'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['areas'];
      setState(() {
        _areas = data.map((dynamic item) => Area.fromJson(item)).toList();
        _isLoading = false;
      });
    } else {
      throw Exception('Error al obtener datos.');
    }
  }

  void _onAreaChanged(String? newValue) {
    setState(() {
      _selectedArea = newValue;
      _selectedMachine = null;
      _selectedOperator = null;
      _filteredMachines = _areas
          .firstWhere((area) => area.id == newValue)
          .maquinas;
      _filteredOperators = _areas
          .firstWhere((area) => area.id == newValue)
          .operadores;
    });
  }

  void _onMachineChanged(String? newValue) {
    setState(() {
      _selectedMachine = newValue;
    });
  }

  void _onOperatorChanged(String? newValue) {
    setState(() {
      _selectedOperator = newValue;
    });
  }

  Future<void> _confirmAndRegisterData() async {
    if (_formKey.currentState?.validate() ?? false) {
      bool confirm = await _showConfirmationDialog();
      if (confirm) {
        await _registerData();
      }
    }
  }

  Future<void> _registerData() async {
    final url = Uri.parse('${Config.verificarAccionInsertar}');
    final response = await http.get(Uri(
      scheme: url.scheme,
      host: url.host,
      port: url.port,
      path: url.path,
      queryParameters: {
        'datos': widget.qrData,
        'area': _selectedArea ?? '',
        'maquina': _selectedMachine ?? '',
        'operador': _selectedOperator ?? '',
        'accion': _selectedAction ?? '', 
      },
    ));

    if (response.statusCode == 201) {
      _showFlashMessage(context, 'Éxito', 'Entrada registrada exitosamente, recuerda registrar su salida una vez finalizada la pieza o tu turno.', Colors.green, Icons.check_circle);
      await Player.play('audio/correct-sound.mp3');
      Navigator.pop(context);
    } else if (response.statusCode == 202) {
      _showFlashMessage(context, 'Éxito', 'Salida registrada exitosamente', Colors.green, Icons.check_circle);
      await Player.play('audio/correct-sound.mp3');
      Navigator.pop(context);
    } else if (response.statusCode == 401) {
      _showMissingRecordDialog(context, 'entrada');
    } else if (response.statusCode == 402) {
      _showMissingRecordDialog(context, 'salida');
    } else {
      _showFlashMessage(context, 'Error', 'Error al registrar datos, inténtalo de nuevo.', Colors.red, Icons.error);
      await Player.play('audio/wrong-sound.mp3');
    }
  }

  Future<void> _showMissingRecordDialog(BuildContext context, String missingRecordType) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          backgroundColor: Color(0xFFFFE600),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.black),
              SizedBox(width: 10),
              Text(
                'Registro Faltante',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Falta un registro de $missingRecordType.',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                SizedBox(height: 10),
                Text(
                  '¿Deseas registrar el faltante y el nuevo registro?',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
           actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text(
                  'Verificar',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              SizedBox(width: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text(
                  'Registrar',
                  style: TextStyle(color: Colors.green, fontSize: 14),
                ),
                onPressed: () async {
                  await _registerMissingAndNewRecord(missingRecordType);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
        );
      },
    );
  }

  Future<void> _registerMissingAndNewRecord(String missingRecordType) async {
    final url = Uri.parse('${Config.insertarFaltantes}');
    final response = await http.get(Uri(
      scheme: url.scheme,
      host: url.host,
      port: url.port,
      path: url.path,
      queryParameters: {
        'datos': widget.qrData,
        'area': _selectedArea ?? '',
        'maquina': _selectedMachine ?? '',
        'operador': _selectedOperator ?? '',
        'accion': _selectedAction ?? '',
        'faltante': missingRecordType == 'salida' ? '402' : '401',
      },
    ));

    if (response.statusCode == 200) {
      _showFlashMessage(context, 'Éxito', 'Datos registrados exitosamente', Colors.green, Icons.check_circle);
      await Player.play('audio/correct-sound.mp3');
      Navigator.pop(context);
    } else {
      _showFlashMessage(context, 'Error', 'Error al registrar datos, inténtalo de nuevo.', Colors.red, Icons.error);
      await Player.play('audio/wrong-sound.mp3');
    }
  }

  Future<bool> _showConfirmationDialog() async {
    final selectedAreaName = _areas.firstWhere((area) => area.id == _selectedArea).nombre;
    final selectedMachineName = _filteredMachines.firstWhere((machine) => machine.id == _selectedMachine).nombre;
    final selectedOperatorName = _filteredOperators.firstWhere((operator) => operator.id == _selectedOperator).nombre;
    final selectedActionName = _selectedAction;

    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text(
                'Confirmar Registro',
                style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Partida: ${widget.qrData}', style: TextStyle(color: Colors.black, fontSize: 13)),
                SizedBox(height: 5),
                Text('Área: $selectedAreaName', style: TextStyle(color: Colors.black, fontSize: 13)),
                SizedBox(height: 5),
                Text('Máquina: $selectedMachineName', style: TextStyle(color: Colors.black, fontSize: 13)),
                SizedBox(height: 5),
                Text('Operador: $selectedOperatorName', style: TextStyle(color: Colors.black, fontSize: 13)),
                SizedBox(height: 5),
                Text('Acción: $selectedActionName', style: TextStyle(color: Colors.black, fontSize: 13)),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Color(0xFFFFFFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Text(
                    'No',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                SizedBox(width: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Text(
                    'Sí',
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _showFlashMessage(BuildContext context, String title, String message, Color? backgroundColor, IconData icon) {
    Fluttertoast.showToast(
      msg: "$title\n$message",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: backgroundColor ?? Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text('Registro'),
        backgroundColor: Colors.red,
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ))
        : SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Código de partida: ${widget.qrData}',
                      style: TextStyle(fontSize: 20, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20.0),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Área',
                        labelStyle: TextStyle(color: Colors.red),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      dropdownColor: Colors.white,
                      value: _selectedArea,
                      items: _areas.map((Area area) {
                        return DropdownMenuItem<String>(
                          value: area.id,
                          child: Text(area.nombre, style: TextStyle(color: Colors.red)),
                        );
                      }).toList(),
                      onChanged: _onAreaChanged,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, seleccione un área';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.0),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Máquina',
                        labelStyle: TextStyle(color: Colors.red),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      dropdownColor: Colors.white,
                      value: _selectedMachine,
                      items: _filteredMachines.map((Maquina maquina) {
                        return DropdownMenuItem<String>(
                          value: maquina.id,
                          child: Text(maquina.nombre, style: TextStyle(color: Colors.red)),
                        );
                      }).toList(),
                      onChanged: _onMachineChanged,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, seleccione una máquina';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.0),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Operador',
                        labelStyle: TextStyle(color: Colors.red),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      dropdownColor: Colors.white,
                      value: _selectedOperator,
                      items: _filteredOperators.map((Operador operador) {
                        return DropdownMenuItem<String>(
                          value: operador.id,
                          child: Text(operador.nombre, style: TextStyle(color: Colors.red)),
                        );
                      }).toList(),
                      onChanged: _onOperatorChanged,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, seleccione un operador';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.0),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Acción',
                        labelStyle: TextStyle(color: Colors.red),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      dropdownColor: Colors.white,
                      value: _selectedAction,
                      items: [
                        'entrada',
                        'turno terminado',
                        'pieza terminada'
                      ].map((String action) {
                        return DropdownMenuItem<String>(
                          value: action,
                          child: Text(
                            action.toUpperCase(),
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedAction = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, seleccione una acción';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.0),
                    ElevatedButton(
                      onPressed: _confirmAndRegisterData,
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                        foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                      ),
                      child: Text('Registrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}