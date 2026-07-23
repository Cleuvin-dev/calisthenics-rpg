// Script único: normaliza assets/images/icon.jpg (na verdade conteúdo WebP,
// 260x280, não quadrado) para um PNG quadrado com fundo branco, adequado
// para o flutter_launcher_icons. Rodar com: dart run tool/prepare_app_icon.dart
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final input = File('assets/images/icon.jpg');
  final bytes = input.readAsBytesSync();

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    stderr.writeln('Não foi possível decodificar assets/images/icon.jpg');
    exit(1);
  }

  final side = decoded.width > decoded.height ? decoded.width : decoded.height;
  final canvas = img.Image(width: side, height: side, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(255, 255, 255, 255));

  final dx = (side - decoded.width) ~/ 2;
  final dy = (side - decoded.height) ~/ 2;
  img.compositeImage(canvas, decoded, dstX: dx, dstY: dy);

  final outFile = File('assets/images/icon.png')
    ..writeAsBytesSync(img.encodePng(canvas));

  stdout.writeln(
    'OK: ${outFile.path} gerado (${canvas.width}x${canvas.height})',
  );
}
