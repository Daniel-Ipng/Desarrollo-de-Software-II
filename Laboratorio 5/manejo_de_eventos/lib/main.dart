// PRÁCTICA 05 - Manejo de Eventos e Interactividad en Flutter
// Desarrollo de Software II - UNSAAC
// Un solo archivo con los 9 ejercicios (reemplaza lib/main.dart)

import 'package:flutter/material.dart';

void main() => runApp(const MiApp());

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Práctica 05',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const MenuPage(),
    );
  }
}

// ---------------------------------------------------------------
// MENÚ PRINCIPAL
// ---------------------------------------------------------------
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_Ejercicio>[
      _Ejercicio('Básico', '1. Botón que cambia el color de fondo', const Ej1ColorFondo()),
      _Ejercicio('Básico', '2. Contador con + y -', const Ej2Contador()),
      _Ejercicio('Básico', '3. Capturar texto y mostrarlo', const Ej3Texto()),
      _Ejercicio('Intermedio', '4. Formulario con nombre y edad', const Ej4Formulario()),
      _Ejercicio('Intermedio', '5. Switch encendido/apagado', const Ej5Switch()),
      _Ejercicio('Intermedio', '6. Doble clic en un contenedor', const Ej6DobleTap()),
      _Ejercicio('Avanzado', '7. Lista dinámica', const Ej7Lista()),
      _Ejercicio('Avanzado', '8. Validación de formulario', const Ej8Validacion()),
      _Ejercicio('Avanzado', '9. Juego: contador de taps', const Ej9Juego()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Práctica 05 - Eventos en Flutter')),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final e = items[i];
          return ListTile(
            title: Text(e.titulo),
            subtitle: Text('Nivel ${e.nivel}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => e.pagina),
            ),
          );
        },
      ),
    );
  }
}

class _Ejercicio {
  final String nivel;
  final String titulo;
  final Widget pagina;
  _Ejercicio(this.nivel, this.titulo, this.pagina);
}

// ---------------------------------------------------------------
// 1. Botón que cambia el color de fondo (onPressed + setState)
// ---------------------------------------------------------------
class Ej1ColorFondo extends StatefulWidget {
  const Ej1ColorFondo({super.key});
  @override
  State<Ej1ColorFondo> createState() => _Ej1State();
}

class _Ej1State extends State<Ej1ColorFondo> {
  final List<Color> colores = [
    Colors.white,
    Colors.lightBlue.shade100,
    Colors.green.shade100,
    Colors.orange.shade100,
    Colors.pink.shade100,
  ];
  int indice = 0;

  void cambiarColor() {
    setState(() => indice = (indice + 1) % colores.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colores[indice],
      appBar: AppBar(title: const Text('Ejercicio 1')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: cambiarColor,
          icon: const Icon(Icons.color_lens),
          label: const Text('Cambiar color'),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// 2. Contador con botones + y -
// ---------------------------------------------------------------
class Ej2Contador extends StatefulWidget {
  const Ej2Contador({super.key});
  @override
  State<Ej2Contador> createState() => _Ej2State();
}

class _Ej2State extends State<Ej2Contador> {
  int contador = 0;

  void incrementar() => setState(() => contador++);
  void decrementar() => setState(() => contador--);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ejercicio 2')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Valor: $contador', style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'menos',
                  onPressed: decrementar,
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(width: 24),
                FloatingActionButton(
                  heroTag: 'mas',
                  onPressed: incrementar,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// 3. Capturar texto y mostrarlo (onChanged + TextEditingController)
// ---------------------------------------------------------------
class Ej3Texto extends StatefulWidget {
  const Ej3Texto({super.key});
  @override
  State<Ej3Texto> createState() => _Ej3State();
}

class _Ej3State extends State<Ej3Texto> {
  final TextEditingController controlador = TextEditingController();
  String texto = '';

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ejercicio 3')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controlador,
              decoration: const InputDecoration(
                labelText: 'Escribe algo',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => texto = value),
            ),
            const SizedBox(height: 24),
            Text('Escribiste: $texto', style: const TextStyle(fontSize: 22)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// 4. Formulario con nombre y edad
// ---------------------------------------------------------------
class Ej4Formulario extends StatefulWidget {
  const Ej4Formulario({super.key});
  @override
  State<Ej4Formulario> createState() => _Ej4State();
}

class _Ej4State extends State<Ej4Formulario> {
  final nombreCtrl = TextEditingController();
  final edadCtrl = TextEditingController();
  String resultado = '';

  @override
  void dispose() {
    nombreCtrl.dispose();
    edadCtrl.dispose();
    super.dispose();
  }

  void mostrar() {
    setState(() {
      resultado = 'Hola, ${nombreCtrl.text}. Tienes ${edadCtrl.text} años.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ejercicio 4')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: edadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Edad',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: mostrar, child: const Text('Enviar')),
            const SizedBox(height: 24),
            Text(resultado, style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// 5. Switch (encendido/apagado)
// ---------------------------------------------------------------
class Ej5Switch extends StatefulWidget {
  const Ej5Switch({super.key});
  @override
  State<Ej5Switch> createState() => _Ej5State();
}

class _Ej5State extends State<Ej5Switch> {
  bool encendido = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ejercicio 5')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              encendido ? Icons.lightbulb : Icons.lightbulb_outline,
              size: 100,
              color: encendido ? Colors.amber : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(encendido ? 'Encendido' : 'Apagado',
                style: const TextStyle(fontSize: 24)),
            Switch(
              value: encendido,
              onChanged: (v) => setState(() => encendido = v),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// 6. Detectar doble clic en un contenedor (GestureDetector)
// ---------------------------------------------------------------
class Ej6DobleTap extends StatefulWidget {
  const Ej6DobleTap({super.key});
  @override
  State<Ej6DobleTap> createState() => _Ej6State();
}

class _Ej6State extends State<Ej6DobleTap> {
  String mensaje = 'Toca el cuadro';
  Color color = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ejercicio 6')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => setState(() => mensaje = 'Tap simple'),
              onDoubleTap: () => setState(() {
                mensaje = '¡Doble tap detectado!';
                color = color == Colors.blue ? Colors.red : Colors.blue;
              }),
              onLongPress: () => setState(() => mensaje = 'Presión larga'),
              child: Container(width: 150, height: 150, color: color),
            ),
            const SizedBox(height: 20),
            Text(mensaje, style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// 7. Lista dinámica donde se agregan elementos
// ---------------------------------------------------------------
class Ej7Lista extends StatefulWidget {
  const Ej7Lista({super.key});
  @override
  State<Ej7Lista> createState() => _Ej7State();
}

class _Ej7State extends State<Ej7Lista> {
  final controlador = TextEditingController();
  final List<String> elementos = [];

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  void agregar() {
    final texto = controlador.text.trim();
    if (texto.isEmpty) return;
    setState(() => elementos.add(texto));
    controlador.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ejercicio 7')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controlador,
                    decoration: const InputDecoration(
                      labelText: 'Nuevo elemento',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => agregar(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: agregar, icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: elementos.isEmpty
                  ? const Center(child: Text('La lista está vacía'))
                  : ListView.builder(
                      itemCount: elementos.length,
                      itemBuilder: (context, i) => ListTile(
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text(elementos[i]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => setState(() => elementos.removeAt(i)),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// 8. Validación de formulario (Form + GlobalKey + validator)
// ---------------------------------------------------------------
class Ej8Validacion extends StatefulWidget {
  const Ej8Validacion({super.key});
  @override
  State<Ej8Validacion> createState() => _Ej8State();
}

class _Ej8State extends State<Ej8Validacion> {
  final _formKey = GlobalKey<FormState>();
  final nombreCtrl = TextEditingController();
  final correoCtrl = TextEditingController();
  final edadCtrl = TextEditingController();

  @override
  void dispose() {
    nombreCtrl.dispose();
    correoCtrl.dispose();
    edadCtrl.dispose();
    super.dispose();
  }

  void enviar() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registro válido: ${nombreCtrl.text}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ejercicio 8')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nombre', border: OutlineInputBorder()),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'El nombre es obligatorio';
                  if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: correoCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Correo', border: OutlineInputBorder()),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'El correo es obligatorio';
                  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
                  return ok ? null : 'Correo no válido';
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: edadCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Edad', border: OutlineInputBorder()),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null) return 'Ingresa un número';
                  if (n < 1 || n > 120) return 'Edad entre 1 y 120';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: enviar, child: const Text('Registrar')),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// 9. Juego simple: contador de taps en 10 segundos
// ---------------------------------------------------------------
class Ej9Juego extends StatefulWidget {
  const Ej9Juego({super.key});
  @override
  State<Ej9Juego> createState() => _Ej9State();
}

class _Ej9State extends State<Ej9Juego> {
  static const int duracion = 10;
  int taps = 0;
  int record = 0;
  int tiempo = duracion;
  bool jugando = false;

  void iniciar() {
    setState(() {
      taps = 0;
      tiempo = duracion;
      jugando = true;
    });
    _tick();
  }

  Future<void> _tick() async {
    while (jugando && tiempo > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => tiempo--);
    }
    if (!mounted) return;
    setState(() {
      jugando = false;
      if (taps > record) record = taps;
    });
  }

  void tocar() {
    if (jugando) setState(() => taps++);
  }

  @override
  void dispose() {
    jugando = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ejercicio 9 - Contador de taps')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tiempo: $tiempo s', style: const TextStyle(fontSize: 24)),
            Text('Taps: $taps', style: const TextStyle(fontSize: 40)),
            Text('Récord: $record'),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: tocar,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: jugando ? 180 : 150,
                height: jugando ? 180 : 150,
                decoration: BoxDecoration(
                  color: jugando ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(jugando ? '¡TOCA!' : 'Inactivo',
                    style: const TextStyle(color: Colors.white, fontSize: 22)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: jugando ? null : iniciar,
              child: Text(taps == 0 && record == 0 ? 'Iniciar' : 'Jugar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}