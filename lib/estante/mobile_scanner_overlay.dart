import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:escaner_qr/components/scanner_button_widgets.dart';
import 'package:escaner_qr/components/scanner_error_widget.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class BarcodeScannerWithOverlay extends StatefulWidget {
  final String? selectedEstanteId;
  const BarcodeScannerWithOverlay({Key? key, this.selectedEstanteId}) : super(key: key);

  @override
  _BarcodeScannerWithOverlayState createState() => 
      _BarcodeScannerWithOverlayState();
}

class Player {
  static play(String src) async {
    final player = AudioPlayer();
    await player.play(AssetSource(src));
  }
}

class _BarcodeScannerWithOverlayState extends State<BarcodeScannerWithOverlay> {
  final MobileScannerController controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  bool _isNavigating = false;
  String? _lastScannedQr;
  DateTime? _lastScanTime;
  final Duration _scanCooldown = const Duration(seconds: 3);

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.sizeOf(context).center(Offset.zero),
      width: 200,
      height: 200,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escaneo estante'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: MobileScanner(
              fit: BoxFit.contain,
              controller: controller,
              scanWindow: scanWindow,
              errorBuilder: (context, error, child) {
                return ScannerErrorWidget(error: error);
              },
              onDetect: (capture) async {
                final String qrData = capture.barcodes.first.displayValue ?? 'Información no obtenida.';
                final DateTime currentScanTime = DateTime.now();

                if (_isNavigating) return;

                if (_canRegister(qrData, currentScanTime)) {
                  _isNavigating = true;
                  controller.stop();

                  await validarYEnviarDatos(context, widget.selectedEstanteId ?? "", qrData, () {
                    setState(() {
                      _isNavigating = false;
                    });
                  });

                  _updateLastScan(qrData, currentScanTime);

                  await Future.delayed(_scanCooldown);
                  controller.start();
                } else {
                  _showFlashMessage(context, 'Advertencia', 'Código QR escaneado repetidamente en menos de 2 segundos.', Colors.yellow, Icons.warning);
                }
              },
            ),
          ),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, child) {
              if (!value.isInitialized || !value.isRunning || value.error != null) {
                return const SizedBox();
              }

              return CustomPaint(
                painter: ScannerOverlay(scanWindow: scanWindow),
              );
            },
          ),
          Positioned(
            top: 16.0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ToggleFlashlightButton(controller: controller),
                  SwitchCameraButton(controller: controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canRegister(String qrData, DateTime currentScanTime) {
    if (_lastScannedQr == qrData && _lastScanTime != null) {
      final timeSinceLastScan = currentScanTime.difference(_lastScanTime!);
      if (timeSinceLastScan < _scanCooldown) {
        return false;
      }
    }
    return true;
  }

  void _updateLastScan(String qrData, DateTime currentScanTime) {
    _lastScannedQr = qrData;
    _lastScanTime = currentScanTime;
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await controller.dispose();
  }
}

Future<void> validarYEnviarDatos(BuildContext context, String selectedId, String qrData, VoidCallback onComplete) async {
  try {
    final validacionResponse = await http.get(
      Uri.parse('${Config.validarQR}?data=$qrData'),
    );

    if (validacionResponse.statusCode == 200) {
      final response = await http.post(
        Uri.parse('${Config.insertarRegistroEstante}?datos=$qrData&estante=$selectedId'),
        body: json.encode({'selectedId': selectedId, 'data': qrData}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201) {
        _showFlashMessage(context, 'Éxito', 'Entrada registrada exitosamente, recuerda registrar su salida cuando la pieza salga del estante.', Colors.green, Icons.check_circle);
        await Player.play('audio/correct-sound.mp3');
      } else if (response.statusCode == 202) {
        _showFlashMessage(context, 'Éxito', 'Salida registrada exitosamente', Colors.green, Icons.check_circle);
        await Player.play('audio/correct-sound.mp3');
      } else if (response.statusCode == 410) {
        _showFlashMessage(context, '¡Advertencia!', 'Mismos datos registrados en menos de 2 minutos', Colors.yellow, Icons.warning);
        await Player.play('audio/wrong-sound.mp3');
      } else {
        _showFlashMessage(context, 'Error', 'Error al enviar los datos escaneados, inténtalo de nuevo.', Colors.red, Icons.error_outline);
        await Player.play('audio/wrong-sound.mp3');
      }
    } else {
      _showFlashMessage(context, 'Error', 'QR no válido', Colors.red, Icons.error_outline);
      await Player.play('audio/wrong-sound.mp3');
    }
  } catch (error) {
    _showFlashMessage(context, 'Error', 'Error al validar/enviar los datos, inténtalo de nuevo.', Colors.red, Icons.error);
    await Player.play('audio/wrong-sound.mp3');
  } finally {
    onComplete();
  }
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

class ScannerOverlay extends CustomPainter {
  const ScannerOverlay({
    required this.scanWindow,
    this.borderRadius = 12.0,
  });

  final Rect scanWindow;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.largest);

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          scanWindow,
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
      );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final borderRect = RRect.fromRectAndCorners(
      scanWindow,
      topLeft: Radius.circular(borderRadius),
      topRight: Radius.circular(borderRadius),
      bottomLeft: Radius.circular(borderRadius),
      bottomRight: Radius.circular(borderRadius),
    );

    canvas.drawPath(backgroundWithCutout, backgroundPaint);
    canvas.drawRRect(borderRect, borderPaint);

    final textSpan = TextSpan(
      text: 'Escanea el código QR para registrar la entrada, y recuerda escanearlo de nuevo al sacar la pieza del estante.',
      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 3,
    );
    textPainter.layout(maxWidth: size.width - 40);

    final textOffset = Offset(
      (size.width - textPainter.width) / 2,
      size.height - textPainter.height - 30,
    );

    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(ScannerOverlay oldDelegate) {
    return scanWindow != oldDelegate.scanWindow ||
        borderRadius != oldDelegate.borderRadius;
  }
}