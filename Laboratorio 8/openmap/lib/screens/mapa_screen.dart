// lib/screens/mapa_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final _locationService = LocationService();
  final _mapCtrl = MapController();

  Position? _posActual;
  final List<Marker> _markersUsuario = []; // marcadores añadidos con long-press
  final List<LatLng> _ruta = [];
  StreamSubscription<Position>? _posStream;

  bool _rastreando = false;
  bool _ahorroBateria = false;
  double _distanciaTotal = 0; // metros
  String _direccion = '';

  @override
  void initState() {
    super.initState();
    _cargarPosicion();
  }

  Future<void> _cargarPosicion() async {
    try {
      final pos = await _locationService.obtenerPosicion();
      if (!mounted) return;
      setState(() => _posActual = pos);
      _mapCtrl.move(LatLng(pos.latitude, pos.longitude), 16);
      _actualizarDireccion(pos.latitude, pos.longitude);
    } on LocationException catch (e) {
      _mostrarError(e);
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _actualizarDireccion(double lat, double lng) async {
    final d = await _locationService.coordenadasADireccion(lat, lng);
    if (mounted) setState(() => _direccion = d);
  }

  Future<void> _toggleRastreo() async {
    if (_rastreando) {
      await _posStream?.cancel();
      setState(() => _rastreando = false);
      return;
    }

    try {
      final stream = await _locationService.rastrearPosicion(
          ahorroBateria: _ahorroBateria);
      _ruta.clear();
      _distanciaTotal = 0;

      _posStream = stream.listen((pos) {
        final punto = LatLng(pos.latitude, pos.longitude);
        setState(() {
          if (_ruta.isNotEmpty) {
            final ult = _ruta.last;
            _distanciaTotal += _locationService.distanciaEntre(
                ult.latitude, ult.longitude, punto.latitude, punto.longitude);
          }
          _ruta.add(punto);
          _posActual = pos;
        });
        // La cámara sigue al usuario
        _mapCtrl.move(punto, _mapCtrl.camera.zoom);
      });
      setState(() => _rastreando = true);
    } on LocationException catch (e) {
      _mostrarError(e);
    }
  }

  void _mostrarError(LocationException e) {
    if (!mounted) return;
    SnackBarAction? accion;
    switch (e.tipo) {
      case LocationError.gpsDesactivado:
        accion = SnackBarAction(
            label: 'Activar GPS', onPressed: _locationService.abrirAjustesGps);
        break;
      case LocationError.permisoDenegadoPermanente:
        accion = SnackBarAction(
            label: 'Ajustes', onPressed: _locationService.abrirAjustesApp);
        break;
      case LocationError.permisoDenegado:
        accion = SnackBarAction(label: 'Reintentar', onPressed: _cargarPosicion);
        break;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(e.mensaje),
      action: accion,
      duration: const Duration(seconds: 6),
    ));
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _agregarMarcador(LatLng punto) {
    setState(() {
      _markersUsuario.add(Marker(
        point: punto,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ));
    });
  }

  @override
  void dispose() {
    _posStream?.cancel();
    _mapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = _posActual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Ubicación'),
        actions: [
          Row(children: [
            const Text('Ahorro', style: TextStyle(fontSize: 12)),
            Switch(
              value: _ahorroBateria,
              // El cambio se aplica al iniciar el siguiente rastreo
              onChanged: _rastreando
                  ? null
                  : (v) => setState(() => _ahorroBateria = v),
            ),
          ]),
        ],
      ),
      body: pos == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    initialCenter: LatLng(pos.latitude, pos.longitude),
                    initialZoom: 16,
                    onLongPress: (tapPos, latlng) => _agregarMarcador(latlng),
                  ),
                  children: [
                    // Tiles de OpenStreetMap
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      // Reemplaza por tu applicationId (android/app/build.gradle)
                      userAgentPackageName: 'com.example.mi_app',
                    ),
                    // Ruta recorrida
                    PolylineLayer(polylines: [
                      Polyline(
                        points: List.of(_ruta),
                        strokeWidth: 4,
                        color: Colors.teal,
                      ),
                    ]),
                    // Marcadores
                    MarkerLayer(markers: [
                      ..._markersUsuario,
                      Marker(
                        point: LatLng(pos.latitude, pos.longitude),
                        width: 48,
                        height: 48,
                        child: const Icon(Icons.my_location,
                            color: Colors.blue, size: 36),
                      ),
                    ]),
                    // Atribución obligatoria de OSM
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('© OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
                // Panel de información
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              'Lat: ${pos.latitude.toStringAsFixed(6)}  '
                              'Lng: ${pos.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (_direccion.isNotEmpty) Text(_direccion),
                          Text(
                              'Distancia recorrida: '
                              '${_distanciaTotal.toStringAsFixed(0)} m'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (pos != null)
            FloatingActionButton.small(
              heroTag: 'centrar',
              onPressed: () => _mapCtrl.move(
                  LatLng(pos.latitude, pos.longitude), _mapCtrl.camera.zoom),
              child: const Icon(Icons.gps_fixed),
            ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'rastreo',
            onPressed: _toggleRastreo,
            icon: Icon(_rastreando ? Icons.stop : Icons.play_arrow),
            label: Text(_rastreando ? 'Detener' : 'Rastrear Ruta'),
            backgroundColor: _rastreando ? Colors.red : Colors.teal,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
