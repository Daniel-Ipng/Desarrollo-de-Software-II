import 'dart:async' show Timer;

import 'package:flutter/material.dart';

import 'weather.dart';
import 'weather_constants.dart';
import 'weather_controller.dart';
import 'weather_exceptions.dart';
import 'weather_service.dart';
import 'weather_storage.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _service = WeatherService();
  late final WeatherController _controller;
  final _textController = TextEditingController();
  Timer? _debounce;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _controller = WeatherController(service: _service, storage: WeatherStorage());
    _loadLastCity();
  }

  /// Carga la última ciudad guardada al iniciar y la consulta.
  Future<void> _loadLastCity() async {
    final saved = await _controller.restoreLastCity();
    if (!mounted || saved == null) return;
    _textController.text = saved;
    await _controller.search(saved);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    _controller.dispose();
    _service.dispose();
    super.dispose();
  }

  String? _validate(String city) {
    if (city.isEmpty) return null;
    if (city.length < WeatherConfig.minCityLength) {
      return WeatherStrings.minLengthError;
    }
    return null;
  }

  /// Búsqueda automática con debounce de 500 ms y validación (mín. 3 caracteres).
  void _onChanged(String value) {
    _debounce?.cancel();
    final city = value.trim();
    final error = _validate(city);
    setState(() => _validationError = error);
    if (city.isEmpty || error != null) return;
    _debounce = Timer(
      WeatherConfig.debounceDuration,
      () => _controller.search(city),
    );
  }

  /// Búsqueda inmediata (Enter o botón de lupa).
  void _onSubmit(String value) {
    _debounce?.cancel();
    final city = value.trim();
    final error = city.isEmpty ? WeatherStrings.emptyInputError : _validate(city);
    setState(() => _validationError = error);
    if (error == null) _controller.search(city);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(WeatherStrings.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: _onSubmit,
              decoration: InputDecoration(
                labelText: WeatherStrings.cityLabel,
                hintText: WeatherStrings.cityHint,
                errorText: _validationError,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_city),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _onSubmit(_textController.text),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => switch (_controller.state) {
                  WeatherEmpty() => const _EmptyView(),
                  WeatherLoading(:final city) => _LoadingView(city: city),
                  final WeatherSuccess s => _SuccessView(
                      state: s,
                      isSavedCity: _isSavedCity(s),
                      onRefresh: (city) =>
                          _controller.search(city, forceRefresh: true),
                    ),
                  final WeatherError e => _ErrorView(
                      state: e,
                      onRetry: _controller.retry,
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSavedCity(WeatherSuccess s) =>
      _controller.lastCity?.toLowerCase() == s.query.toLowerCase();
}

// ---------------------------------------------------------------- Vistas

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.travel_explore, size: 72, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(WeatherStrings.emptyTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(WeatherStrings.emptyMessage, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.city});
  final String city;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('${WeatherStrings.loading} $city...'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.state, required this.onRetry});
  final WeatherError state;
  final VoidCallback onRetry;

  IconData get _icon => switch (state.error) {
        NetworkException() => Icons.wifi_off,
        TimeoutException() => Icons.timer_off_outlined,
        ApiKeyException() => Icons.vpn_key_off_outlined,
        CityNotFoundException() => Icons.location_off_outlined,
        ServerException() => Icons.cloud_off,
        ParseException() => Icons.data_object,
        UnknownException() => Icons.error_outline,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 72, color: scheme.error),
            const SizedBox(height: 12),
            Text(state.error.message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text(WeatherStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.state,
    required this.isSavedCity,
    required this.onRefresh,
  });

  final WeatherSuccess state;
  final bool isSavedCity;
  final void Function(String city) onRefresh;

  @override
  Widget build(BuildContext context) {
    final Weather w = state.weather;
    final text = Theme.of(context).textTheme;
    final place = w.country.isEmpty ? w.cityName : '${w.cityName}, ${w.country}';

    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (isSavedCity)
                const Chip(
                  avatar: Icon(Icons.bookmark, size: 18),
                  label: Text(WeatherStrings.savedCity),
                ),
              Image.network(
                w.iconUrl,
                width: 100,
                height: 100,
                errorBuilder: (_, __, ___) => const Icon(Icons.cloud, size: 80),
              ),
              Text(place, style: text.headlineSmall),
              Text('${w.temperature.toStringAsFixed(1)} °C', style: text.displaySmall),
              Text(_capitalize(w.description), style: text.titleMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _Detail(Icons.thermostat, 'Sensación', '${w.feelsLike.toStringAsFixed(1)} °C'),
                  _Detail(Icons.water_drop_outlined, 'Humedad', '${w.humidity}%'),
                  _Detail(Icons.air, 'Viento', '${w.windSpeed.toStringAsFixed(1)} m/s'),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => onRefresh(state.query),
                icon: const Icon(Icons.refresh),
                label: const Text(WeatherStrings.refresh),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _Detail extends StatelessWidget {
  const _Detail(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
