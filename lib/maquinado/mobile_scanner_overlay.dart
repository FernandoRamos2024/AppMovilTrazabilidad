import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:escaner_qr/components/scanner_button_widgets.dart';
import 'package:escaner_qr/components/scanner_error_widget.dart';
import 'result_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class BarcodeScannerWithOverlay extends StatefulWidget {
  @override
  _BarcodeScannerWithOverlayState createState() => _BarcodeScannerWithOverlayState();
}

class _BarcodeScannerWithOverlayState extends State<BarcodeScannerWithOverlay> {
  final MobileScannerController controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  bool _isNavigating = false;
  bool _isScannerRunning = false;

  @override
  void initState() {
    super.initState();
    startScanner();
  }

  void startScanner() {
    if (!_isScannerRunning) {
      controller.start();
      _isScannerRunning = true;
    }
  }

  void stopScanner() {
    if (_isScannerRunning) {
      controller.stop();
      _isScannerRunning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: 200,
      height: 200,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escaneo maquinado'),
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
                if (!_isNavigating) {
                  final String qrData = capture.barcodes.first.displayValue ?? 'Información no obtenida.';
                  _isNavigating = true;
                  stopScanner();
                  await validarYNavegar(context, qrData, () {
                    setState(() {
                      _isNavigating = false;
                    });

                    Future.delayed(Duration(seconds: 2), () {
                      startScanner();
                    });
                  });
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

  @override
  void dispose() {
    stopScanner();
    controller.dispose();
    super.dispose();
  }
}

class Player {
  static play(String src) async {
    final player = AudioPlayer();
    await player.play(AssetSource(src));
  }
}

Future<void> validarYNavegar(BuildContext context, String qrData, VoidCallback onComplete) async {
  try {
    
    final validacionResponse = await http.get(
      Uri.parse('${Config.validarQR}?data=$qrData'),
    );

    if (validacionResponse.statusCode == 200) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ResultScreen(qrData: qrData)),
      ).then((_) {
        onComplete();
      });
    } else {
      _showFlashMessage(context, 'Error', 'QR no válido', Colors.red, Icons.error_outline);
      await Player.play('audio/wrong-sound.mp3');
      onComplete();
    }
  } catch (error) {
    _showFlashMessage(context, 'Error', 'Error al validar el QR', Colors.red, Icons.error);
    await Player.play('audio/wrong-sound.mp3');
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
      text: 'Registra la entrada y recuerda registrar la salida al terminar tu turno o cuando la pieza esté terminada.',
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