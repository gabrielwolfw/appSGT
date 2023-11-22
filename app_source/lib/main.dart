import 'package:app_source/utils/util_googlemap.dart';
import 'package:flutter/material.dart';

// "debugPrint" Gestión de prints

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'StraviaTEC',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StraviaTEC'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: GoogleMapScreen(key: mapKey),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      mapKey.currentState?.startTracking();
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (mapKey.currentState?.isTracking ?? false)
                            return Colors.green;
                          return Colors.white;
                        },
                      ),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.black),
                    ),
                    child: const Text('Iniciar ruta'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      mapKey.currentState?.resetTimeAndDistance();
                    },
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                      ),
                    ),
                    child: const Text('Restablecer'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      mapKey.currentState?.stopTracking();
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (!(mapKey.currentState?.isTracking ?? true))
                            return Colors.green;
                          return Colors.white;
                        },
                      ),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.black),
                    ),
                    child: const Text('Detener ruta'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
