import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static final String? validarQR = dotenv.env['VALIDAR_QR'];
  static final String? obtenerAreas = dotenv.env['OBTENER_AREAS'];
  static final String? obtenerEstantes = dotenv.env['OBTENER_ESTANTES'];
  static final String? insertarRegistroEstante = dotenv.env['INSERTAR_REGISTRO_ESTANTE'];
  static final String? verificarAccionInsertar = dotenv.env['VERIFICAR_E_INSERTAR'];
  static final String? insertarFaltantes = dotenv.env['INSERTAR_FALTANTES'];
}