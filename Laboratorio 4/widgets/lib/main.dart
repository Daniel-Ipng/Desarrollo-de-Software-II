import 'package:flutter/material.dart';

// ============================================================
// PRÁCTICA 04 - Guía Práctica de Widgets en Flutter
// Cubre: Layout, Display, Input, Navegación y Feedback
// ============================================================

// 1. Punto de entrada de la app
void main() {
  runApp(const MiApp());
}

// 2. Widget raíz sin estado: configuración global
class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Primera App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MiPantallaPrincipal(),
      routes: {'/detalle': (_) => const DetalleScreen()},
    );
  }
}

// 3. Pantalla principal: Scaffold + AppBar + BottomNavigationBar
class MiPantallaPrincipal extends StatefulWidget {
  const MiPantallaPrincipal({super.key});

  @override
  State<MiPantallaPrincipal> createState() => _MiPantallaPrincipalState();
}

class _MiPantallaPrincipalState extends State<MiPantallaPrincipal> {
  int _index = 0;

  static const List<Widget> _paginas = [
    LayoutPage(),
    DisplayPage(),
    InputPage(),
    NavegacionPage(),
    FeedbackPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('¡Hola, Flutter!'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Detalle (ruta nombrada)',
            onPressed: () => Navigator.pushNamed(context, '/detalle'),
          ),
        ],
      ),
      body: _paginas[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed, // necesario con más de 3 ítems
        selectedItemColor: cs.primary,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Layout'),
          BottomNavigationBarItem(icon: Icon(Icons.image), label: 'Display'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Input'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Navegación'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Feedback'),
        ],
      ),
    );
  }
}

// ============================================================
// COMPONENTES DE DISEÑO REUTILIZABLES (DRY)
// ============================================================

/// Banner con gradiente que encabeza cada pantalla.
class Encabezado extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;

  const Encabezado({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0x33FFFFFF),
            child: Icon(icono, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitulo, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta que agrupa la demo de un widget con título y descripción.
class Seccion extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final Widget child;

  const Seccion({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
            ),
            const SizedBox(height: 2),
            Text(
              descripcion,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

/// Caja de color para demostrar layouts.
class Caja extends StatelessWidget {
  final String texto;
  final Color color;

  const Caja(this.texto, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Image.network con indicador de carga y fallback si no hay internet.
class ImagenRed extends StatelessWidget {
  const ImagenRed({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Image.network(
      'https://picsum.photos/600/300',
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(child: CircularProgressIndicator(color: cs.primary));
      },
      errorBuilder: (context, error, stack) => Container(
        color: cs.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported, color: cs.onSurfaceVariant, size: 40),
      ),
    );
  }
}

// ============================================================
// 1) LAYOUT
// ============================================================
class LayoutPage extends StatelessWidget {
  const LayoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Encabezado(
          titulo: 'Layout',
          subtitulo: 'Organización espacial de la UI',
          icono: Icons.dashboard,
        ),

        // --- Container ---
        Seccion(
          titulo: 'Container',
          descripcion: 'Caja con padding, margen, decoración y tamaño.',
          child: Container(
            width: 200,
            height: 100,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Color(0x44000000), blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: const Text(
              'Hola',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),

        // --- Row ---
        const Seccion(
          titulo: 'Row',
          descripcion: 'Hijos en horizontal. mainAxisAlignment: spaceAround.',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.amber, size: 32),
              Text('Texto'),
              Icon(Icons.favorite, color: Colors.red, size: 32),
            ],
          ),
        ),

        // --- Column ---
        Seccion(
          titulo: 'Column',
          descripcion: 'Hijos en vertical. mainAxisSize.min ocupa solo lo necesario.',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Título', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('Subtítulo'),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: () {}, child: const Text('Botón')),
            ],
          ),
        ),

        // --- Stack ---
        Seccion(
          titulo: 'Stack + Positioned',
          descripcion: 'Widgets superpuestos en el eje Z.',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ImagenRed(),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x99000000),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Overlay', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // --- Expanded & Flexible ---
        Seccion(
          titulo: 'Expanded & Flexible',
          descripcion: 'flex 2 : 1 reparte el espacio. Flexible no obliga a llenarlo.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Expanded (flex 2 y flex 1)'),
              const SizedBox(height: 6),
              Row(
                children: const [
                  Expanded(flex: 2, child: Caja('flex: 2', Colors.blue)),
                  SizedBox(width: 8),
                  Expanded(flex: 1, child: Caja('flex: 1', Colors.red)),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Flexible (fit: loose) vs Expanded'),
              const SizedBox(height: 6),
              Row(
                children: const [
                  Flexible(
                    fit: FlexFit.loose,
                    child: Caja('Flexible', Colors.teal),
                  ),
                  SizedBox(width: 8),
                  Expanded(child: Caja('Expanded', Colors.orange)),
                ],
              ),
            ],
          ),
        ),

        // --- Padding & SizedBox ---
        Seccion(
          titulo: 'Padding & SizedBox',
          descripcion: 'Padding da espacio interno; SizedBox separa o fija tamaño.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: cs.primaryContainer,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Con espacio (Padding)'),
                ),
              ),
              const SizedBox(height: 16), // separador vertical
              Row(
                children: [
                  const Text('A'),
                  const SizedBox(width: 8), // separador horizontal
                  const Text('B'),
                ],
              ),
            ],
          ),
        ),

        // --- Consejos: MediaQuery, FittedBox, Theme ---
        Seccion(
          titulo: 'Layout adaptativo',
          descripcion: 'MediaQuery, FittedBox y Theme.of(context).colorScheme.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pantalla: ${size.width.toStringAsFixed(0)} x ${size.height.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 8),
              Container(
                width: 160,
                padding: const EdgeInsets.all(8),
                color: cs.secondaryContainer,
                child: const FittedBox(
                  child: Text('Texto escalado con FittedBox'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 2) DISPLAY
// ============================================================
class DisplayPage extends StatelessWidget {
  const DisplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = List.generate(3, (i) => 'Elemento ${i + 1}');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Encabezado(
          titulo: 'Display',
          subtitulo: 'Presentación de datos y contenido',
          icono: Icons.image,
        ),

        // --- Text ---
        Seccion(
          titulo: 'Text',
          descripcion: 'style, maxLines, overflow y textAlign.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hola Flutter',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              const Text(
                'Este texto es muy largo y se corta con puntos suspensivos '
                'cuando supera el máximo de líneas permitido por maxLines.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Estilo del tema (textTheme)',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // --- Image ---
        Seccion(
          titulo: 'Image',
          descripcion: 'Image.network (internet) e Image.asset (assets locales).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: const SizedBox(height: 160, child: ImagenRed()),
              ),
              const SizedBox(height: 8),
              Image.asset(
                'assets/logo.png',
                height: 48,
                errorBuilder: (context, error, stack) => Text(
                  'Image.asset: falta assets/logo.png (declararlo en pubspec.yaml)',
                  style: TextStyle(color: cs.error, fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'BoxFit.cover recorta la imagen para llenar el contenedor sin deformar.\n'
                'Para assets: Image.asset(\'assets/logo.png\') y declarar la carpeta en pubspec.yaml.',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),

        // --- Card ---
        Seccion(
          titulo: 'Card',
          descripcion: 'Superficie elevada; elevation: 0 para versión plana.',
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(width: double.infinity, child: Text('Card con elevation: 4')),
                ),
              ),
              Card(
                elevation: 0,
                color: cs.primaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(width: double.infinity, child: Text('Card plana (elevation: 0)')),
                ),
              ),
            ],
          ),
        ),

        // --- CircleAvatar ---
        Seccion(
          titulo: 'CircleAvatar',
          descripcion: 'Con iniciales o con backgroundImage.',
          child: Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.purple,
                child: Text('AB', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              const SizedBox(width: 16),
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.purple,
                backgroundImage: const NetworkImage('https://picsum.photos/200'),
                onBackgroundImageError: (_, __) {},
                child: const Text('AB', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text('La imagen cubre el child; si falla la carga se ven las iniciales.'),
              ),
            ],
          ),
        ),

        // --- ListView ---
        Seccion(
          titulo: 'ListView.builder',
          descripcion: 'Lista lazy: solo construye los ítems visibles.',
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: Text(items[index]),
                trailing: const Icon(Icons.chevron_right),
              );
            },
          ),
        ),

        // --- GridView ---
        Seccion(
          titulo: 'GridView.builder',
          descripcion: 'crossAxisCount define el número de columnas.',
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.2,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => Card(
              color: cs.secondaryContainer,
              elevation: 0,
              child: Center(child: Text('Celda ${index + 1}')),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 3) INPUT
// ============================================================
class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isOn = false;
  bool _checked = false;
  String? _selected;
  double _value = 30;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Encabezado(
          titulo: 'Input',
          subtitulo: 'Captura de entrada del usuario',
          icono: Icons.edit,
        ),

        // --- ElevatedButton ---
        Seccion(
          titulo: 'ElevatedButton',
          descripcion: 'Si onPressed es null, el botón queda deshabilitado.',
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('¡Botón presionado!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Aceptar'),
              ),
              const ElevatedButton(
                onPressed: null, // deshabilitado
                child: Text('Presióname'),
              ),
            ],
          ),
        ),

        // --- TextField ---
        Seccion(
          titulo: 'TextField',
          descripcion: 'TextEditingController para leer y limpiar el valor.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  hintText: 'usuario@email.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (val) => setState(() {}),
              ),
              const SizedBox(height: 12),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text('Escribiste: ${_controller.text}')),
                  TextButton(
                    onPressed: () {
                      _controller.clear();
                      setState(() {});
                    },
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // --- Switch & Checkbox ---
        Seccion(
          titulo: 'Switch & Checkbox',
          descripcion: 'Valores booleanos; el estado se guarda con setState.',
          child: Column(
            children: [
              Row(
                children: [
                  Switch(
                    value: _isOn,
                    activeColor: Colors.green,
                    onChanged: (val) => setState(() => _isOn = val),
                  ),
                  Text(_isOn ? 'Switch activado' : 'Switch apagado'),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: _checked,
                    activeColor: Colors.indigo,
                    onChanged: (val) => setState(() => _checked = val!),
                  ),
                  Text(_checked ? 'Checkbox marcado' : 'Checkbox sin marcar'),
                ],
              ),
            ],
          ),
        ),

        // --- DropdownButton ---
        Seccion(
          titulo: 'DropdownButton',
          descripcion: 'Selector tipado; isExpanded ocupa todo el ancho.',
          child: DropdownButton<String>(
            value: _selected,
            hint: const Text('Elige una opción'),
            isExpanded: true,
            items: ['Opción A', 'Opción B', 'Opción C']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) => setState(() => _selected = val),
          ),
        ),

        // --- Slider ---
        Seccion(
          titulo: 'Slider',
          descripcion: 'divisions crea pasos discretos; label muestra el valor.',
          child: Slider(
            value: _value,
            min: 0.0,
            max: 100.0,
            divisions: 10,
            label: _value.round().toString(),
            onChanged: (val) => setState(() => _value = val),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 4) NAVEGACIÓN
// ============================================================
class NavegacionPage extends StatelessWidget {
  const NavegacionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Encabezado(
          titulo: 'Navegación',
          subtitulo: 'Flujo entre pantallas',
          icono: Icons.explore,
        ),

        // --- AppBar ---
        Seccion(
          titulo: 'AppBar',
          descripcion: 'title, leading, actions y backgroundColor.',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 80,
              child: Scaffold(
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(80),
                  child: AppBar(
                primary: false,
                title: const Text('Mi App'),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
                actions: [
                  IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                ],
              ),
                ),
              ),
            ),
          ),
        ),

        // --- BottomNavigationBar ---
        Seccion(
          titulo: 'BottomNavigationBar',
          descripcion: 'La barra inferior de esta pantalla es el ejemplo en vivo.',
          child: Row(
            children: [
              Icon(Icons.arrow_downward, color: cs.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'currentIndex + onTap controlan la pestaña activa. '
                  'Con más de 3 ítems se usa type: fixed.',
                ),
              ),
            ],
          ),
        ),

        // --- TabBar ---
        Seccion(
          titulo: 'TabBar + TabBarView',
          descripcion: 'DefaultTabController sincroniza las pestañas sin gestor de estado.',
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  labelColor: cs.primary,
                  indicatorColor: cs.primary,
                  tabs: const [
                    Tab(text: 'A', icon: Icon(Icons.looks_one)),
                    Tab(text: 'B', icon: Icon(Icons.looks_two)),
                    Tab(text: 'C', icon: Icon(Icons.looks_3)),
                  ],
                ),
                SizedBox(
                  height: 100,
                  child: TabBarView(
                    children: [
                      Center(child: Text('Panel A', style: Theme.of(context).textTheme.titleMedium)),
                      Center(child: Text('Panel B', style: Theme.of(context).textTheme.titleMedium)),
                      Center(child: Text('Panel C', style: Theme.of(context).textTheme.titleMedium)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // --- Navigator & Routes ---
        Seccion(
          titulo: 'Navigator & Routes',
          descripcion: 'push, pop, pushNamed y pushReplacement.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Navigator.push'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DetalleScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.alt_route),
                label: const Text('Navigator.pushNamed(\'/detalle\')'),
                onPressed: () => Navigator.pushNamed(context, '/detalle'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Navigator.pushReplacement'),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const PantallaReemplazo()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 5) FEEDBACK
// ============================================================
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  double _progreso = 0.65;
  bool _dart = false;
  int _choice = 0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Encabezado(
          titulo: 'Feedback',
          subtitulo: 'Notificaciones y estados del sistema',
          icono: Icons.notifications,
        ),

        // --- SnackBar ---
        Seccion(
          titulo: 'SnackBar',
          descripcion: 'Notificación temporal; behavior: floating.',
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Guardado correctamente'),
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(label: 'Deshacer', onPressed: () {}),
                ),
              );
            },
          ),
        ),

        // --- Progress ---
        Seccion(
          titulo: 'CircularProgressIndicator & LinearProgressIndicator',
          descripcion: 'value: null = giratorio; 0.0 a 1.0 = progreso exacto.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircularProgressIndicator(color: Colors.indigo, strokeWidth: 3),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _progreso,
                      backgroundColor: Colors.grey[200],
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${(_progreso * 100).round()}%'),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    final siguiente = _progreso >= 1.0 ? 0.0 : _progreso + 0.1;
                    _progreso = siguiente.clamp(0.0, 1.0).toDouble();
                  });
                },
                child: const Text('Avanzar 10%'),
              ),
            ],
          ),
        ),

        // --- AlertDialog ---
        Seccion(
          titulo: 'AlertDialog',
          descripcion: 'Diálogo modal; barrierDismissible: false impide cerrar tocando fuera.',
          child: ElevatedButton.icon(
            icon: const Icon(Icons.warning_amber),
            label: const Text('Mostrar diálogo'),
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Confirmar'),
                  content: const Text('¿Estás seguro?'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Aceptar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // --- Chip ---
        Seccion(
          titulo: 'Chip, FilterChip y ChoiceChip',
          descripcion: 'Etiquetas compactas, con opción de eliminar o seleccionar.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: const Text('Flutter'),
                avatar: const CircleAvatar(child: Text('F')),
                onDeleted: () {},
              ),
              FilterChip(
                label: const Text('Dart'),
                selected: _dart,
                onSelected: (v) => setState(() => _dart = v),
              ),
              for (int i = 0; i < 2; i++)
                ChoiceChip(
                  label: Text('Opción ${i + 1}'),
                  selected: _choice == i,
                  onSelected: (_) => setState(() => _choice = i),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PANTALLAS SECUNDARIAS
// ============================================================
class DetalleScreen extends StatelessWidget {
  const DetalleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flutter_dash, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 12),
            const Text('Mi primer widget en acción!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context), // volver atrás
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla a la que se llega con pushReplacement: reemplaza a la actual
/// en el stack, por eso no hay flecha de "atrás".
class PantallaReemplazo extends StatelessWidget {
  const PantallaReemplazo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantalla reemplazada'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_horiz, size: 64, color: Colors.deepPurple),
              const SizedBox(height: 12),
              const Text(
                'pushReplacement elimina la pantalla anterior del stack.\n'
                'Útil para login -> home.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MiPantallaPrincipal()),
                  );
                },
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}