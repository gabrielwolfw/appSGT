import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';

class GpxHelper {
  static const String folderName = 'GpxFiles';

  static Future<void> saveGpx(List<LatLng> routeCoordinates) async {
    final String gpxData = _generateGpx(routeCoordinates);
    final String directory = (await DownloadsPath.downloadsDirectory())!.path;
    final String gpxFolderPath = '$directory/$folderName';

    // Crea la carpeta si no existe
    final Directory folder = Directory(gpxFolderPath);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    // Genera un nombre de archivo único con un timestamp
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final File file = File('$gpxFolderPath/StraviaRuta_$timestamp.gpx');

    try {
      await file.writeAsString(gpxData);
    } catch (e) {
      debugPrint('Error al guardar el archivo GPX: $e');
    }
  }

  static String _generateGpx(List<LatLng> routeCoordinates) {
    final StringBuffer gpxString = StringBuffer();

    // Crea el encabezado del archivo GPX
    gpxString
        .writeln('<?xml version="1.0" encoding="UTF-8" standalone="no" ?>');
    gpxString.writeln(
        '<gpx xmlns="http://www.topografix.com/GPX/1/1" version="1.1" creator="YourAppName">');
    gpxString.writeln('<trk>');
    gpxString.writeln('<trkseg>');

    // Agrega las coordenadas a la ruta
    for (final LatLng coord in routeCoordinates) {
      gpxString.writeln(
          '<trkpt lat="${coord.latitude}" lon="${coord.longitude}"></trkpt>');
    }

    // Finaliza el archivo GPX
    gpxString.writeln('</trkseg>');
    gpxString.writeln('</trk>');
    gpxString.writeln('</gpx>');

    return gpxString.toString();
  }
}
