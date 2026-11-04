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
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _ruta = [];
  StreamSubscription<Position>? _posStream;

  bool _rastreando = false;
  bool _ahorroBateria = false;
  double _distanciaTotal = 0; // metros
  String _direccion = '';
  String? _error;
  UbicacionError? _tipoError;

  @override
  void initState() {
    super.initState();
    _cargarPosicion();
  }

  Future<void> _cargarPosicion() async {
    setState(() {
      _error = null;
      _tipoError = null;
    });
    try {
      final pos = await _locationService.obtenerPosicion();
      final dir = await _locationService.coordenadasADireccion(
          pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _posActual = pos;
        _direccion = dir;
        _markers.add(Marker(
          markerId: const MarkerId('yo'),
          position: LatLng(pos.latitude, pos.longitude),
          infoWindow: InfoWindow(title: 'Mi ubicación', snippet: dir),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ));
      });
      _mapCtrl?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 15),
      ));
    } on UbicacionException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _tipoError = e.tipo;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo obtener la ubicación: $e');
    }
  }

  void _iniciarRastreo() {
    _posStream?.cancel();
    _posStream = _locationService
        .rastrearPosicion(ahorroBateria: _ahorroBateria)
        .listen((pos) async {
      final latlng = LatLng(pos.latitude, pos.longitude);
      if (_posActual != null) {
        _distanciaTotal += _locationService.calcularDistancia(_posActual!, pos);
      }
      if (!mounted) return;
      setState(() {
        _posActual = pos;
        _ruta.add(latlng);
        _polylines
          ..removeWhere((p) => p.polylineId.value == 'ruta')
          ..add(Polyline(
            polylineId: const PolylineId('ruta'),
            points: List.of(_ruta),
            color: Colors.teal,
            width: 4,
          ));
        _markers
          ..removeWhere((m) => m.markerId.value == 'yo')
          ..add(Marker(
            markerId: const MarkerId('yo'),
            position: latlng,
            infoWindow: const InfoWindow(title: 'Mi ubicación'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
          ));
      });
      _mapCtrl?.animateCamera(CameraUpdate.newLatLng(latlng));
    }, onError: (e) {
      if (!mounted) return;
      setState(() => _rastreando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error de rastreo: $e')));
    });
  }

  void _toggleRastreo() {
    if (_rastreando) {
      _posStream?.cancel();
      setState(() => _rastreando = false);
    } else {
      _iniciarRastreo();
      setState(() => _rastreando = true);
    }
  }

  void _toggleBateria() {
    setState(() => _ahorroBateria = !_ahorroBateria);
    if (_rastreando) _iniciarRastreo(); // reinicia con el nuevo perfil
  }

  void _limpiarRuta() {
    setState(() {
      _ruta.clear();
      _polylines.clear();
      _distanciaTotal = 0;
      _markers.removeWhere((m) => m.markerId.value != 'yo');
    });
  }

  @override
  void dispose() {
    _posStream?.cancel();
    _mapCtrl?.dispose();
    super.dispose();
  }

  Widget _vistaError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.location_off, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          if (_tipoError == UbicacionError.denegadoPermanente)
            ElevatedButton(
                onPressed: _locationService.abrirAjustesApp,
                child: const Text('Abrir ajustes de la app')),
          if (_tipoError == UbicacionError.gpsApagado)
            ElevatedButton(
                onPressed: _locationService.abrirAjustesGps,
                child: const Text('Activar GPS')),
          TextButton(onPressed: _cargarPosicion, child: const Text('Reintentar')),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_error != null) {
      body = _vistaError();
    } else if (_posActual == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = Stack(children: [
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
          onLongPress: (latlng) {
            setState(() => _markers.add(Marker(
                  markerId: MarkerId(latlng.toString()),
                  position: latlng,
                  infoWindow: InfoWindow(title: latlng.toString()),
                )));
          },
        ),
        Positioned(
          top: 8, left: 8, right: 8,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_direccion, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  'Lat ${_posActual!.latitude.toStringAsFixed(5)}  '
                  'Lng ${_posActual!.longitude.toStringAsFixed(5)}  '
                  '· Recorrido: ${_distanciaTotal.toStringAsFixed(0)} m',
                  style: const TextStyle(fontSize: 12),
                ),
              ]),
            ),
          ),
        ),
      ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Ubicación'),
        actions: [
          IconButton(
            tooltip: _ahorroBateria ? 'Modo ahorro de batería' : 'Alta precisión',
            icon: Icon(_ahorroBateria ? Icons.battery_saver : Icons.gps_fixed),
            onPressed: _toggleBateria,
          ),
          IconButton(
              tooltip: 'Limpiar ruta',
              icon: const Icon(Icons.delete_outline),
              onPressed: _limpiarRuta),
        ],
      ),
      body: body,
      floatingActionButton: _posActual == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _toggleRastreo,
              icon: Icon(_rastreando ? Icons.stop : Icons.play_arrow),
              label: Text(_rastreando ? 'Detener' : 'Rastrear Ruta'),
              backgroundColor: _rastreando ? Colors.red : Colors.teal,
            ),
    );
  }
}
