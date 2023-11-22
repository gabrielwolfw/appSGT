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

  @override
  void initState() {
    super.initState();
    determinePosition();
    _startTime = DateTime.now();
    _startTimer();
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
    });

    positionStream = Geolocator.getPositionStream().listen((Position position) {
      _onPositionChanged(position);
      _elapsedSeconds = DateTime.now().difference(_startTime).inSeconds;
    });
  }

  void stopTracking() {
    positionStream?.cancel();

    setState(() {
      isTracking = false;
      // Detiene el seguimiento
    });

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

  @override
  Widget build(BuildContext context) {
    int elapsedMinutes =
        (_elapsedSeconds / 60).floor(); // Convertir los segundos a minutos

    String roundedDistance = _totalDistance.toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stravia Mapa'),
      ),
      body: (currentPosition != null)
          ? Column(
              children: [
                Expanded(
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
                        markerId: MarkerId('current_position'),
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
                          markerId: MarkerId('start_position'),
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
                          markerId: MarkerId('end_position'),
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
                      Text(
                        'Tiempo: $elapsedMinutes minutos',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Distancia: $roundedDistance metros',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
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
