import 'package:flutter/material.dart';

import '../exceptions/api_exceptions.dart';

/// Mensaje amigable para cualquier error (nunca muestra stack traces).
String friendlyMessage(Object error) =>
    error is ApiException ? error.message : 'Ocurrió un error inesperado.';

IconData errorIcon(Object error) => switch (error) {
      NetworkException() => Icons.wifi_off,
      TimeoutException() => Icons.timer_off_outlined,
      UnauthorizedException() => Icons.lock_outline,
      ServerException() => Icons.cloud_off,
      ValidationException() => Icons.report_gmailerrorred,
      _ => Icons.error_outline,
    };

/// Vista de error con botón "Reintentar".
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(errorIcon(error), size: 72, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(friendlyMessage(error), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
