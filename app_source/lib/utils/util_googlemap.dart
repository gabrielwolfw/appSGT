import 'dart:async';

import 'package:app_source/utils/file_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

final GlobalKey<_GoogleMapScreenState> mapKey =
    GlobalKey<_GoogleMapScreenState>();

class GoogleMapScreen extends StatefulWidget {
  const GoogleMapScreen({super.key});

  static double totalDistance = 0.0;
  static int totalTime = 0;

  @override
  _GoogleMapScreenState createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  late GoogleMapController mapController;
  Position? currentPosition;
  bool isTracking = false;
  List<LatLng> routeCoordinates = [];
  final Set<Polyline> _polylines = {};
  StreamSubscription<Position>? positionStream;
  late Timer _timer;
  late DateTime _startTime;
  int _elapsedSeconds = 0;
  double _totalDistance = 0;
  double speedMps = 0;

  @override
  void initState() {
    super.initState();
    determinePosition();
  }

  void resetTimeAndDistance() {
    setState(() {
      // Restablecer tiempo y distancia
      GoogleMapScreen.totalDistance = 0.0;
      GoogleMapScreen.totalTime = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tiempo y distancia restablecidos'),
      ),
    );
  }

  // Inicia el cronómetro
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        _elapsedSeconds = DateTime.now().difference(_startTime).inSeconds;
      });
    });
  }

  // Detiene el cronómetro
  void _stopTimer() {
    _timer.cancel();
  }

  Future<void> determinePosition() async {
    PermissionStatus permissionStatus = await Permission.location.request();

    if (permissionStatus.isGranted) {
      try {
        currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {});
      } catch (e) {
        debugPrint('Hubo un error al obtener la ubicación: $e');
      }
    } else {
      debugPrint('Los permisos de ubicación fueron denegados');
    }
  }

  void startTracking() {
    setState(() {
      routeCoordinates.clear(); // Limpia las coordenadas anteriores
      isTracking = true; // Activa el seguimiento
      _startTime = DateTime.now(); // Inicia el cronómetro
      _elapsedSeconds = 0; // Reinicia los segundos
      _totalDistance = 0; // Reinicia la distancia
    });
    _startTimer();
    _clearRoute();

    positionStream = Geolocator.getPositionStream().listen((Position position) {
      _onPositionChanged(position);
      _elapsedSeconds = DateTime.now().difference(_startTime).inSeconds;
    });
  }

  void stopTracking() {
    positionStream?.cancel();

    setState(() {
      isTracking = false; // Detiene el seguimiento
    });
    _stopTimer();

    _saveRouteAsGpx();
  }

  // Actualiza la ruta, indica la distancia recorrida y mueve la cámara
  void updateRoute(Position position) {
    if (routeCoordinates.isNotEmpty) {
      // Calcular la distancia entre la posición anterior y la actual
      double distanceInMeters = Geolocator.distanceBetween(
        routeCoordinates.last.latitude,
        routeCoordinates.last.longitude,
        position.latitude,
        position.longitude,
      );

      _totalDistance += distanceInMeters;
    }

    setState(() {
      routeCoordinates.add(LatLng(position.latitude, position.longitude));

      // Agregar la nueva coordenada a la polilínea
      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: routeCoordinates,
        color: Colors.red, // Color de la línea
        width: 5, // Ancho de la línea
      ));
    });
  }

  void updateCameraPosition(Position position) {
    mapController.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 18.0,
      ),
    ));
  }

  void _onPositionChanged(Position newPosition) {
    if (isTracking) {
      updateRoute(newPosition);
    }
  }

  // Guarda la ruta en un archivo GPX
  void _saveRouteAsGpx() async {
    try {
      if (routeCoordinates.isNotEmpty) {
        await GpxHelper.saveGpx(routeCoordinates);
        debugPrint(
            'Se ha guardado la ruta en un archivo GPX en la memoria externa');

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('GPX Saved'),
              content: const Text(
                  'Se ha guardado la ruta en un archivo GPX en la memoria externa'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );

        // Muestra un SnackBar con el mensaje de confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Se ha guardado la ruta en un archivo GPX en la memoria externa'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al guardar el archivo GPX: $e');

      // Muestra un SnackBar indicando el error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar el archivo GPX'),
        ),
      );
    }
  }

  void _clearRoute() {
    setState(() {
      // Limpiar datos de la ruta
      routeCoordinates.clear();
      _polylines.clear();
      GoogleMapScreen.totalDistance = 0.0;
      GoogleMapScreen.totalTime = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ruta borrada'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int elapsedHours = (_elapsedSeconds / 3600).floor();
    int elapsedMinutes = ((_elapsedSeconds % 3600) / 60).floor();
    int elapsedSeconds = (_elapsedSeconds % 60).floor();

    double distanceKm = (_totalDistance / 1000);

    String roundedDistanceKm = distanceKm.toStringAsFixed(2);

    double speedMps = _totalDistance / _elapsedSeconds;

    String roundedSpeedMps = speedMps.toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta'),
      ),
      body: (currentPosition != null)
          ? Column(
              children: [
                Expanded(
                  flex: 5,
                  child: GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: LatLng(currentPosition!.latitude,
                          currentPosition!.longitude),
                      zoom: 18.0,
                    ),
                    polylines: _polylines, // Añade las polilíneas al mapa
                    markers: {
                      // Marcador de ubicación actual (punto azul)
                      Marker(
                        markerId: const MarkerId('current_position'),
                        position: LatLng(
                          currentPosition!.latitude,
                          currentPosition!.longitude,
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue,
                        ),
                      ),
                      // Marcador del inicio de la ruta (punto rojo)
                      if (routeCoordinates.isNotEmpty)
                        Marker(
                          markerId: const MarkerId('start_position'),
                          position: LatLng(
                            routeCoordinates.first.latitude,
                            routeCoordinates.first.longitude,
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                      // Marcador del final de la ruta (punto verde)
                      if (routeCoordinates.isNotEmpty)
                        Marker(
                          markerId: const MarkerId('end_position'),
                          position: LatLng(
                            routeCoordinates.last.latitude,
                            routeCoordinates.last.longitude,
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen,
                          ),
                        ),
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.0),
                        child: SizedBox(
                          width:
                              10.0, // Ajusta este valor para cambiar el ancho del botón
                          child: ElevatedButton(
                            onPressed: _saveRouteAsGpx,
                            style: ButtonStyle(
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.0),
                                ),
                              ),
                            ),
                            child: const Text('Guardar Ruta como KML'),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.0),
                        child: SizedBox(
                          width:
                              10.0, // Ajusta este valor para cambiar el ancho del botón
                          child: ElevatedButton(
                            onPressed: _clearRoute,
                            style: ButtonStyle(
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.0),
                                ),
                              ),
                            ),
                            child: const Text('Clear Route'),
                          ),
                        ),
                      ),
                      Text(
                        'Tiempo: $elapsedHours : $elapsedMinutes : $elapsedSeconds',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Distancia: $roundedDistanceKm km',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Velocidad: $roundedSpeedMps m/s',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
