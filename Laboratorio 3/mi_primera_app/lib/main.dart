import 'package:flutter/material.dart';

void main() {
  runApp(const CalculadoraApp());
}

class CalculadoraApp extends StatelessWidget {
  const CalculadoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const PantallaCalculadora(),
    );
  }
}

class PantallaCalculadora extends StatefulWidget {
  const PantallaCalculadora({super.key});

  @override
  State<PantallaCalculadora> createState() => _PantallaCalculadoraState();
}

class _PantallaCalculadoraState extends State<PantallaCalculadora> {
  // Variables de estado
  String _display = '0';
  double? _primerNumero;
  String? _operacion;
  bool _debeLimpiarPantalla = false; // Nos dice si el próximo número debe borrar la pantalla

  // Lógica principal de la calculadora
  void _presionarBoton(String valor) {
    setState(() {
      if (valor == 'C') {
        // Reiniciar todo
        _display = '0';
        _primerNumero = null;
        _operacion = null;
      } else if (valor == '+' || valor == '-' || valor == '×' || valor == '÷') {
        // Guardar el primer número y la operación
        _primerNumero = double.tryParse(_display);
        _operacion = valor;
        _debeLimpiarPantalla = true;
      } else if (valor == '=') {
        // Calcular el resultado
        _calcularResultado();
      } else {
        // Ingreso de números y punto decimal
        if (_debeLimpiarPantalla) {
          _display = (valor == '.') ? '0.' : valor;
          _debeLimpiarPantalla = false;
        } else {
          if (_display == '0' && valor != '.') {
            _display = valor; // Reemplazar el 0 inicial
          } else if (valor == '.' && _display.contains('.')) {
            return; // Evitar poner dos puntos decimales
          } else {
            _display += valor;
          }
        }
      }
    });
  }

  void _calcularResultado() {
    if (_primerNumero == null || _operacion == null) return;

    double segundoNumero = double.tryParse(_display) ?? 0.0;
    double resultado = 0.0;

    switch (_operacion) {
      case '+': resultado = _primerNumero! + segundoNumero; break;
      case '-': resultado = _primerNumero! - segundoNumero; break;
      case '×': resultado = _primerNumero! * segundoNumero; break;
      case '÷':
        resultado = (segundoNumero == 0) ? 0.0 : _primerNumero! / segundoNumero;
        break;
    }

    // Formatear el resultado para quitar decimales si es entero (ej. 5.0 -> 5)
    if (resultado == resultado.toInt()) {
      _display = resultado.toInt().toString();
    } else {
      _display = resultado.toString();
    }

    _primerNumero = null;
    _operacion = null;
    _debeLimpiarPantalla = true;
  }

  // Lógica para el color del display
  Color get _colorDelDisplay {
    double valorActual = double.tryParse(_display) ?? 0.0;
    if (valorActual > 0) return Colors.blue;
    if (valorActual < 0) return Colors.red;
    return Colors.grey; // Para el 0
  }

  // Método auxiliar para construir botones y ahorrar código
  Widget _construirBoton(String texto, {Color? colorFondo, Color? colorTexto, double ancho = 1.0}) {
    return Expanded(
      flex: ancho.toInt(), // Permite que botones como el "=" sean más anchos
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorFondo ?? Colors.grey.shade200,
            foregroundColor: colorTexto ?? Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            padding: const EdgeInsets.all(24),
          ),
          onPressed: () => _presionarBoton(texto),
          child: Text(
            texto,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Pantalla de la calculadora
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(24),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 70,
                  fontWeight: FontWeight.bold,
                  color: _colorDelDisplay, // Aquí aplicamos el color dinámico
                ),
                child: Text(_display),
              ),
            ),
          ),
          // Teclado numérico
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    _construirBoton('7'),
                    _construirBoton('8'),
                    _construirBoton('9'),
                    _construirBoton('÷', colorFondo: Colors.orange, colorTexto: Colors.white),
                  ],
                ),
                Row(
                  children: [
                    _construirBoton('4'),
                    _construirBoton('5'),
                    _construirBoton('6'),
                    _construirBoton('×', colorFondo: Colors.orange, colorTexto: Colors.white),
                  ],
                ),
                Row(
                  children: [
                    _construirBoton('1'),
                    _construirBoton('2'),
                    _construirBoton('3'),
                    _construirBoton('-', colorFondo: Colors.orange, colorTexto: Colors.white),
                  ],
                ),
                Row(
                  children: [
                    _construirBoton('C', colorFondo: Colors.red.shade400, colorTexto: Colors.white),
                    _construirBoton('0'),
                    _construirBoton('.'),
                    _construirBoton('+', colorFondo: Colors.orange, colorTexto: Colors.white),
                  ],
                ),
                Row(
                  children: [
                    // Botón "=" ocupa todo el ancho inferior
                    _construirBoton('=', colorFondo: Colors.green.shade600, colorTexto: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}