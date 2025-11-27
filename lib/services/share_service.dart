import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  final ScreenshotController screenshotController = ScreenshotController();

  // ========== CAPTURE AND SHARE WIDGET ==========

  /// Captura un widget usando GlobalKey y lo comparte
  Future<void> captureAndShareWidget(
    GlobalKey key, {
    String? text,
    String? subject,
  }) async {
    try {
      // Obtener el RenderRepaintBoundary del widget
      final RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Capturar la imagen
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // Guardar en archivo temporal
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/fyncee_chart_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);

      // Compartir
      await Share.shareXFiles(
        [XFile(file.path)],
        text: text ?? 'Compartido desde Fyncee',
        subject: subject ?? 'Gráfica de Fyncee',
      );
    } catch (e) {
      print('Error al capturar y compartir widget: $e');
      rethrow;
    }
  }

  // ========== CAPTURE USING SCREENSHOT CONTROLLER ==========

  /// Captura un widget envuelto en Screenshot widget y lo comparte
  Future<void> captureAndShareScreenshot({
    String? text,
    String? subject,
  }) async {
    try {
      final bytes = await screenshotController.capture();
      if (bytes == null) {
        throw Exception('No se pudo capturar la imagen');
      }

      // Guardar en archivo temporal
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/fyncee_screenshot_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);

      // Compartir
      await Share.shareXFiles(
        [XFile(file.path)],
        text: text ?? 'Compartido desde Fyncee',
        subject: subject ?? 'Gráfica de Fyncee',
      );
    } catch (e) {
      print('Error al capturar y compartir screenshot: $e');
      rethrow;
    }
  }

  // ========== SHARE TEXT ==========

  /// Comparte texto simple
  Future<void> shareText(String text, {String? subject}) async {
    try {
      await Share.share(
        text,
        subject: subject ?? 'Compartido desde Fyncee',
      );
    } catch (e) {
      print('Error al compartir texto: $e');
      rethrow;
    }
  }

  // ========== SHARE FILE ==========

  /// Comparte un archivo por su ruta
  Future<void> shareFile(
    String filePath, {
    String? text,
    String? subject,
  }) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: text ?? 'Compartido desde Fyncee',
        subject: subject ?? 'Archivo de Fyncee',
      );
    } catch (e) {
      print('Error al compartir archivo: $e');
      rethrow;
    }
  }

  // ========== SHARE MULTIPLE FILES ==========

  /// Comparte múltiples archivos
  Future<void> shareFiles(
    List<String> filePaths, {
    String? text,
    String? subject,
  }) async {
    try {
      await Share.shareXFiles(
        filePaths.map((path) => XFile(path)).toList(),
        text: text ?? 'Compartido desde Fyncee',
        subject: subject ?? 'Archivos de Fyncee',
      );
    } catch (e) {
      print('Error al compartir archivos: $e');
      rethrow;
    }
  }
}
