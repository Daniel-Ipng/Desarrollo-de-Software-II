import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ejercicio 1 - Registro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const RegistroScreen(),
    );
  }
}

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _ocultarPassword = true;
  bool _ocultarConfirm = true;

  static final _emailRegex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$');
  static final _passwordRegex =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validarEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El correo es obligatorio';
    if (!_emailRegex.hasMatch(v)) {
      return 'Ingrese un formato de correo electrónico válido';
    }
    return null;
  }

  String? _validarPassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
    if (!_passwordRegex.hasMatch(value)) {
      return 'Mínimo 8 caracteres, con mayúscula, minúscula y número';
    }
    return null;
  }

  String? _validarConfirmacion(String? value) {
    if (value == null || value.isEmpty) return 'Confirme su contraseña';
    if (value != _passwordCtrl.text) return 'Las contraseñas no coinciden';
    return null;
  }

  void _enviar() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registro exitoso para ${_emailCtrl.text.trim()}'),
        ),
      );
    }
  }

  InputDecoration _decoracion(String label, IconData icono, {Widget? sufijo}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icono),
      suffixIcon: sufijo,
      border: const OutlineInputBorder(),
    );
  }

  Widget _botonVisibilidad(bool oculto, VoidCallback onPressed) {
    return IconButton(
      tooltip: oculto ? 'Mostrar contraseña' : 'Ocultar contraseña',
      icon: Icon(oculto ? Icons.visibility_off : Icons.visibility),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de usuario')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration:
                          _decoracion('Correo electrónico', Icons.email_outlined),
                      validator: _validarEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _ocultarPassword,
                      textInputAction: TextInputAction.next,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: _decoracion(
                        'Contraseña',
                        Icons.lock_outline,
                        sufijo: _botonVisibilidad(
                          _ocultarPassword,
                          () => setState(
                              () => _ocultarPassword = !_ocultarPassword),
                        ),
                      ),
                      validator: _validarPassword,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _ocultarConfirm,
                      textInputAction: TextInputAction.done,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: _decoracion(
                        'Confirmar contraseña',
                        Icons.lock_reset,
                        sufijo: _botonVisibilidad(
                          _ocultarConfirm,
                          () => setState(
                              () => _ocultarConfirm = !_ocultarConfirm),
                        ),
                      ),
                      validator: _validarConfirmacion,
                    ),
                    const SizedBox(height: 8),
                    // CheckboxFormField no existe: se usa FormField<bool>.
                    FormField<bool>(
                      initialValue: false,
                      validator: (v) => v == true
                          ? null
                          : 'Debe aceptar los términos y condiciones',
                      builder: (state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: state.value ?? false,
                              onChanged: state.didChange,
                              title: const Text(
                                  'Acepto los términos y condiciones'),
                            ),
                            if (state.hasError)
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Text(
                                  state.errorText!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _enviar,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Registrarse'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}