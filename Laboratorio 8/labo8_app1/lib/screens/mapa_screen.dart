import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';

/// Mapa gratuito con flutter_map + teselas de OpenStreetMap (sin API key).
class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final _locationService = LocationService();
  final MapController _mapCtrl = MapController();

  Position? _posActual;
  Position? _ultimaPos;
  String? _error;
  String _direccion = '';
  double _distanciaTotal = 0; // metros

  final List<LatLng> _ruta = [];
  final List<LatLng> _marcadores = [];
  StreamSubscription<Position>? _posStream;
  bool _rastreando = false;
  bool _ahorroBateria = false;

  @override
  void initState() {
    super.initState();
    _cargarPosicion();
  }

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> _cargarPosicion() async {
    setState(() => _error = null);
    try {
      final pos = await _locationService.obtenerPosicion();
      if (!mounted) return;
      setState(() {
        _posActual = pos;
        _ultimaPos = pos;
      });
      _actualizarDireccion(pos);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _msg(e));
    }
  }

  Future<void> _actualizarDireccion(Position pos) async {
    try {
      final dir = await _locationService.coordenadasADireccion(
          pos.latitude, pos.longitude);
      if (mounted) setState(() => _direccion = dir);
    } catch (_) {
      // Sin internet o sin servicio de geocodificación: no es crítico.
    }
  }

  void _centrar() {
    final p = _posActual;
    if (p == null) return;
    _mapCtrl.move(LatLng(p.latitude, p.longitude), 16);
    _actualizarDireccion(p);
  }

  Future<void> _toggleRastreo() async {
    if (_rastreando) {
      await _posStream?.cancel();
      setState(() => _rastreando = false);
      return;
    }
    try {
      await _locationService.verificarPermisos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_msg(e))));
      }
      return;
    }

    if (_posActual != null && _ruta.isEmpty) {
      _ruta.add(LatLng(_posActual!.latitude, _posActual!.longitude));
    }

    _posStream = _locationService
        .rastrearPosicion(ahorroBateria: _ahorroBateria)
        .listen((pos) {
      final latlng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        if (_ultimaPos != null) {
          _distanciaTotal += _locationService.calcularDistancia(_ultimaPos!, pos);
        }
        _ultimaPos = pos;
        _posActual = pos;
        _ruta.add(latlng);
      });
      _mapCtrl.move(latlng, _mapCtrl.camera.zoom); // la cámara sigue al usuario
    }, onError: (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_msg(e))));
      }
    });
    setState(() => _rastreando = true);
  }

  void _limpiar() {
    setState(() {
      _ruta.clear();
      _marcadores.clear();
      _distanciaTotal = 0;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Ubicación'),
        actions: [
          Tooltip(
            message: 'Ahorro de batería',
            child: Row(children: [
              const Icon(Icons.battery_saver),
              Switch(
                value: _ahorroBateria,
                // Solo se puede cambiar antes de iniciar el rastreo
                onChanged: _rastreando
                    ? null
                    : (v) => setState(() => _ahorroBateria = v),
              ),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Limpiar ruta y marcadores',
            onPressed: _limpiar,
          ),
        ],
      ),
      body: _cuerpo(),
      floatingActionButton: _posActual == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'centrar',
                  onPressed: _centrar,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 12),
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

  Widget _cuerpo() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _cargarPosicion,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_posActual == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final yo = LatLng(_posActual!.latitude, _posActual!.longitude);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: yo,
            initialZoom: 16,
            onLongPress: (tapPos, punto) =>
                setState(() => _marcadores.add(punto)),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              // Debe coincidir con el applicationId de tu app
              userAgentPackageName: 'com.example.practica08',
            ),
            if (_ruta.length >= 2)
              PolylineLayer(polylines: [
                Polyline(points: _ruta, color: Colors.teal, strokeWidth: 4),
              ]),
            MarkerLayer(markers: [
              // Marcadores agregados con pulsación larga (toque = eliminar)
              for (final m in _marcadores)
                Marker(
                  point: m,
                  width: 40,
                  height: 40,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () => setState(() => _marcadores.remove(m)),
                    child: const Icon(Icons.location_on,
                        color: Colors.red, size: 40),
                  ),
                ),
              // Mi ubicación
              Marker(
                point: yo,
                width: 40,
                height: 40,
                child: const Icon(Icons.navigation,
                    color: Colors.blue, size: 34),
              ),
            ]),
            const SimpleAttributionWidget(
              source: Text('© OpenStreetMap contributors'),
            ),
          ],
        ),
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
                    'Lat: ${yo.latitude.toStringAsFixed(5)}   '
                    'Lng: ${yo.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_direccion.isNotEmpty)
                    Text(_direccion,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text('Recorrido: ${_distanciaTotal.toStringAsFixed(0)} m  •  '
                      'Puntos: ${_ruta.length}  •  '
                      '${_ahorroBateria ? "Ahorro batería" : "Alta precisión"}'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
