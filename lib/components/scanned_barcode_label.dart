import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannedBarcodeLabel extends StatelessWidget {
  const ScannedBarcodeLabel({
    Key? key,
    required this.barcodes,
  }) : super(key: key);

  final Stream<BarcodeCapture> barcodes;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: barcodes,
      builder: (context, snapshot) {
        final scannedBarcodes = snapshot.data?.barcodes ?? [];

        if (scannedBarcodes.isEmpty) {
          return const Text(
            '¡Escanea algo!',
            overflow: TextOverflow.fade,
            style: TextStyle(color: Colors.white),
          );
        }

        final String qrData = scannedBarcodes.first.displayValue ?? 'Información no obtenida.';

        return Text(
          qrData,
          overflow: TextOverflow.fade,
          style: const TextStyle(color: Colors.white),
        );
      },
    );
  }
}