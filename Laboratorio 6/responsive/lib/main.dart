// Práctica 06 – Diseño Responsivo y Accesible en Flutter
// Desarrollo de Software II – UNSAAC
//
// App demo "Tienda accesible": catálogo + carrito + formulario.
// Aplica: LayoutBuilder/MediaQuery.sizeOf, FractionallySizedBox, Expanded/flex,
// Breakpoints centralizados, grid adaptable, NavigationRail/NavigationBar,
// texto escalable, foco/teclado, touch targets, Semantics, MergeSemantics,
// ExcludeSemantics, SemanticsService.announce y liveRegion.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

void main() => runApp(const App());

// ───────────────────────── 2. Breakpoints centralizados ─────────────────────────
class Breakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double wide = 1440;

  static bool isMobile(BuildContext ctx) => MediaQuery.sizeOf(ctx).width < mobile;

  static bool isTablet(BuildContext ctx) {
    final w = MediaQuery.sizeOf(ctx).width;
    return w >= mobile && w < desktop;
  }

  static bool isDesktop(BuildContext ctx) => MediaQuery.sizeOf(ctx).width >= desktop;

  /// Riel lateral desde tablet (>= 768). Así nunca queda una pantalla sin
  /// navegación (en la guía, entre 480 y 1024 no aparecía ninguna).
  static bool useRail(BuildContext ctx) => MediaQuery.sizeOf(ctx).width >= tablet;
}

// ───────────────────────── Modelo ─────────────────────────
class Product {
  final String name;
  final double price;
  final IconData icon;
  final bool inStock;
  const Product(this.name, this.price, this.icon, {this.inStock = true});
}

const kProducts = <Product>[
  Product('Cuaderno A4', 8.50, Icons.menu_book),
  Product('Mochila', 79.90, Icons.backpack),
  Product('Lapicero', 1.50, Icons.edit),
  Product('Audífonos', 45.00, Icons.headphones, inStock: false),
  Product('Calculadora', 35.00, Icons.calculate),
  Product('Botella', 18.00, Icons.water_drop),
];

// ───────────────────────── App ─────────────────────────
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Práctica 06',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Azul oscuro: contraste alto con texto blanco/negro (>= 4.5:1).
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B4F9C)),
      ),
      // 3. Texto escalable: se respeta la escala del usuario; solo se pone un
      // tope muy alto (2.0) para cubrir el mínimo exigido de 1.5x.
      builder: (context, child) {
        final scaler = MediaQuery.textScalerOf(context)
            .clamp(minScaleFactor: 0.8, maxScaleFactor: 2.0);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scaler),
          child: child!,
        );
      },
      home: const HomeShell(),
    );
  }
}

// ───────────────────────── Shell con navegación adaptable ─────────────────────────
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _labels = ['Catálogo', 'Carrito', 'Mis datos'];
  static const _icons = [
    Icons.storefront_outlined,
    Icons.shopping_cart_outlined,
    Icons.person_outline,
  ];

  int _index = 0;
  final Map<String, int> _cart = {};

  int get _count => _cart.values.fold(0, (a, b) => a + b);

  void _add(Product p) {
    setState(() => _cart.update(p.name, (v) => v + 1, ifAbsent: () => 1));
    final msg = '${p.name} añadido al carrito';
    // 4. Anuncio dinámico para lectores de pantalla.
    SemanticsService.announce(msg, TextDirection.ltr);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _remove(Product p) {
    setState(() {
      final n = (_cart[p.name] ?? 0) - 1;
      if (n <= 0) {
        _cart.remove(p.name);
      } else {
        _cart[p.name] = n;
      }
    });
  }

  Widget _icon(int i) {
    final icon = Icon(_icons[i]);
    if (i != 1) return icon;
    return Badge(
      isLabelVisible: _count > 0,
      label: Text('$_count'),
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rail = Breakpoints.useRail(context);
    final extended = Breakpoints.isDesktop(context);

    final pages = <Widget>[
      CatalogPage(onAdd: _add),
      CartPage(cart: _cart, onRemove: _remove),
      const OrderFormPage(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Tienda accesible')),
      body: SafeArea(
        child: Row(
          children: [
            if (rail) ...[
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                extended: extended,
                // Con extended = true la etiqueta ya va al lado del icono.
                labelType: extended ? null : NavigationRailLabelType.all,
                destinations: [
                  for (var i = 0; i < _labels.length; i++)
                    NavigationRailDestination(
                      icon: _icon(i),
                      label: Text(_labels[i]),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
            ],
            Expanded(
              // Contenido centrado y con ancho máximo en pantallas muy anchas.
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Breakpoints.wide),
                  child: IndexedStack(index: _index, children: pages),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: rail
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (var i = 0; i < _labels.length; i++)
                  NavigationDestination(icon: _icon(i), label: _labels[i]),
              ],
            ),
    );
  }
}

// ───────────────────────── Página 1: Catálogo ─────────────────────────
class CatalogPage extends StatefulWidget {
  final void Function(Product) onAdd;
  const CatalogPage({super.key, required this.onAdd});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _search() => setState(() => _query = _ctrl.text.trim());

  @override
  Widget build(BuildContext context) {
    final filtered = kProducts
        .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    // La altura de la celda crece con la escala de texto para no desbordar.
    final scale =
        (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1.0, 2.0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          // Expanded + flex: 2/3 campo, 1/3 botón.
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _ctrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: const InputDecoration(
                    labelText: 'Buscar producto',
                    border: OutlineInputBorder(),
                    prefixIcon: ExcludeSemantics(child: Icon(Icons.search)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _search,
                    child: const Text('Buscar'),
                  ),
                ),
              ),
            ],
          ),
        ),
        // liveRegion: el lector anuncia el cambio del número de resultados.
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${filtered.length} productos'),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Sin resultados'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  // Grid adaptable: las columnas dependen del ancho disponible.
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisExtent: 240 * scale,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) =>
                      ProductCard(product: filtered[i], onAdd: widget.onAdd),
                ),
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final void Function(Product) onAdd;
  const ProductCard({super.key, required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // MergeSemantics: se lee como un solo elemento.
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono decorativo: fuera del árbol semántico.
                  ExcludeSemantics(child: Icon(p.icon, size: 40)),
                  const SizedBox(height: 8),
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text('S/ ${p.price.toStringAsFixed(2)}'),
                  // No solo color: icono + texto para el estado.
                  Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          p.inStock ? Icons.check_circle : Icons.cancel,
                          size: 16,
                        ),
                      ),
                      Text(p.inStock ? 'Disponible' : 'Agotado'),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: p.inStock ? () => onAdd(p) : null,
                // El texto visible es corto; el lector dice la etiqueta completa.
                child: Semantics(
                  label: 'Añadir ${p.name} al carrito',
                  excludeSemantics: true,
                  child: const Text('Añadir'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Página 2: Carrito ─────────────────────────
class CartPage extends StatelessWidget {
  final Map<String, int> cart;
  final void Function(Product) onRemove;
  const CartPage({super.key, required this.cart, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final items = kProducts.where((p) => (cart[p.name] ?? 0) > 0).toList();
    final total =
        items.fold<double>(0, (sum, p) => sum + p.price * cart[p.name]!);

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Semantics(
            liveRegion: true,
            child: Text(
              'Tu carrito está vacío',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            'Total: S/ ${total.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 8),
        for (final p in items)
          Card(
            child: ListTile(
              leading: ExcludeSemantics(child: Icon(p.icon)),
              title: Text(p.name),
              subtitle: Text('${cart[p.name]} × S/ ${p.price.toStringAsFixed(2)}'),
              trailing: IconButton(
                tooltip: 'Quitar ${p.name}',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.remove_circle_outline, size: 24),
                onPressed: () => onRemove(p),
              ),
            ),
          ),
      ],
    );
  }
}

// ───────────────────────── Página 3: Formulario ─────────────────────────
class OrderFormPage extends StatefulWidget {
  const OrderFormPage({super.key});

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _remember = false;
  String? _nameError;
  String? _emailError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _nameError = _name.text.trim().isEmpty ? 'Escribe tu nombre completo' : null;
      _emailError = _email.text.contains('@')
          ? null
          : 'Escribe un correo válido, por ejemplo nombre@correo.com';
    });
    final ok = _nameError == null && _emailError == null;
    final msg = ok ? 'Datos guardados correctamente' : 'Hay errores en el formulario';
    SemanticsService.announce(msg, TextDirection.ltr);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Orden de foco explícito para navegación con teclado (Tab).
        FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FocusTraversalOrder(
                order: const NumericFocusOrder(1),
                child: TextField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    border: const OutlineInputBorder(),
                    errorText: _nameError,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FocusTraversalOrder(
                order: const NumericFocusOrder(2),
                child: TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    border: const OutlineInputBorder(),
                    errorText: _emailError,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FocusTraversalOrder(
                order: const NumericFocusOrder(3),
                // Se lee: "Recordar mis datos, casilla de verificación".
                child: MergeSemantics(
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _remember,
                    onChanged: (v) => setState(() => _remember = v ?? false),
                    title: const Text('Recordar mis datos'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FocusTraversalOrder(
                order: const NumericFocusOrder(4),
                // 80 % del ancho disponible, sin ancho fijo.
                child: FractionallySizedBox(
                  widthFactor: 0.8,
                  child: FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: _submit,
                    child: const Text('Continuar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}