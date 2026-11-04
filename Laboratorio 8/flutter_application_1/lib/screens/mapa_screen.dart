import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final _locationService = LocationService();
  GoogleMapController? _mapCtrl;
  Position? _posActual;
  Position? _ultimaPos;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _ruta = [];
  StreamSubscription<Position>? _posStream;
  bool _rastreando = false;
  bool _ahorroBateria = false;
  double _distanciaM = 0;
  String _direccion = '';

  @override
  void initState() {
    super.initState();
    _cargarPosicion();
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _cargarPosicion() async {
    try {
      final pos = await _locationService.obtenerPosicion();
      if (!mounted) return;
      setState(() {
        _posActual = pos;
        _ultimaPos = pos;
        _markers.add(Marker(
          markerId: const MarkerId('yo'),
          position: LatLng(pos.latitude, pos.longitude),
          infoWindow: const InfoWindow(title: 'Mi ubicación'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ));
      });
      _mapCtrl?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 15),
      ));
      final dir = await _locationService.coordenadasADireccion(pos.latitude, pos.longitude);
      if (mounted) setState(() => _direccion = dir);
    } catch (e) {
      _mensaje(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _iniciarRastreo() {
    _posStream?.cancel();
    _posStream = _locationService
        .rastrearPosicion(ahorroBateria: _ahorroBateria)
        .listen((pos) {
      final latlng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        if (_ultimaPos != null) {
          _distanciaM += _locationService.calcularDistancia(_ultimaPos!, pos);
        }
        _ultimaPos = pos;
        _ruta.add(latlng);
        // Polyline se compara por polylineId: hay que quitar la anterior
        // para que el Set tome la versión actualizada.
        _polylines
          ..clear()
          ..add(Polyline(
            polylineId: const PolylineId('ruta'),
            points: List.from(_ruta),
            color: Colors.teal,
            width: 4,
          ));
        _markers
          ..removeWhere((m) => m.markerId.value == 'yo')
          ..add(Marker(
            markerId: const MarkerId('yo'),
            position: latlng,
            infoWindow: const InfoWindow(title: 'Mi ubicación'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ));
      });
      _mapCtrl?.animateCamera(CameraUpdate.newLatLng(latlng));
    }, onError: (e) => _mensaje('Error de GPS: $e'));
  }

  Future<void> _toggleRastreo() async {
    if (_rastreando) {
      await _posStream?.cancel();
      setState(() => _rastreando = false);
    } else {
      try {
        await _locationService.verificarPermisos();
      } catch (e) {
        _mensaje(e.toString().replaceFirst('Exception: ', ''));
        return;
      }
      _iniciarRastreo();
      setState(() => _rastreando = true);
    }
  }

  void _toggleAhorro() {
    setState(() => _ahorroBateria = !_ahorroBateria);
    if (_rastreando) _iniciarRastreo(); // reinicia con el nuevo perfil
    _mensaje(_ahorroBateria
        ? 'Modo ahorro de batería (precisión baja, 50 m)'
        : 'Modo alta precisión (10 m)');
  }

  @override
  void dispose() {
    _posStream?.cancel();
    _mapCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Ubicación'),
        actions: [
          IconButton(
            tooltip: 'Ahorro de batería',
            icon: Icon(_ahorroBateria ? Icons.battery_saver : Icons.gps_fixed),
            onPressed: _toggleAhorro,
          ),
        ],
      ),
      body: _posActual == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_posActual!.latitude, _posActual!.longitude),
                    zoom: 15,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapType: MapType.normal,
                  onMapCreated: (ctrl) => _mapCtrl = ctrl,
                  onLongPress: (latlng) async {
                    final dir = await _locationService
                        .coordenadasADireccion(latlng.latitude, latlng.longitude);
                    if (!mounted) return;
                    setState(() => _markers.add(Marker(
                          markerId: MarkerId(latlng.toString()),
                          position: latlng,
                          infoWindow: InfoWindow(title: dir),
                        )));
                  },
                ),
                Positioned(
                  top: 8, left: 8, right: 8,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '${_direccion.isEmpty ? "Obteniendo dirección..." : _direccion}\n'
                        'Distancia recorrida: ${_distanciaM.toStringAsFixed(0)} m',
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleRastreo,
        icon: Icon(_rastreando ? Icons.stop : Icons.play_arrow),
        label: Text(_rastreando ? 'Detener' : 'Rastrear Ruta'),
        backgroundColor: _rastreando ? Colors.red : Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }
}
