import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../../tasks/presentation/tasks_screen.dart';
import 'auth_provider.dart';
import 'login_screen.dart';

/// Decide qué pantalla mostrar según el estado de la sesión.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return auth.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          error: error,
          onRetry: () => ref.invalidate(authControllerProvider),
        ),
      ),
      data: (user) => user == null ? const LoginScreen() : const TasksScreen(),
    );
  }
}
