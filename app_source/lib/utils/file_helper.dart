import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';

class GpxHelper {
  static const String folderName = 'GpxFiles'; // Nombre de la carpeta

  static Future<void> saveGpx(List<LatLng> routeCoordinates) async {
    final String gpxData = _generateGpx(routeCoordinates);
    final String directory = (await getExternalStorageDirectory())!.path;
    final String gpxFolderPath = '$directory/$folderName';

    // Crea la carpeta si no existe
    final Directory folder = Directory(gpxFolderPath);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final File file = File('$gpxFolderPath/StraviaRuta.gpx');

    await file.writeAsString(gpxData);
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
