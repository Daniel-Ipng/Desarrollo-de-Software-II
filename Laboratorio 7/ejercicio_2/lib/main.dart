import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ejercicio 2 - Inventario',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const InventarioScreen(),
    );
  }
}

/// Modelo de datos inmutable.
class Producto {
  final String id;
  final String nombre;
  final int cantidad;
  final double precio;
  final String categoria;

  const Producto({
    required this.id,
    required this.nombre,
    required this.cantidad,
    required this.precio,
    required this.categoria,
  });

  double get subtotal => cantidad * precio;
}

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  static const _categorias = ['Electrónica', 'Hogar', 'Alimentos', 'Ropa'];

  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();

  final List<Producto> _productos = [];
  String? _categoria;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cantidadCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  String? _validarNombre(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El nombre es obligatorio';
    if (v.length <= 3) return 'Debe tener más de 3 caracteres';
    return null;
  }

  String? _validarCantidad(String? value) {
    final n = int.tryParse(value?.trim() ?? '');
    if (n == null) return 'Ingrese una cantidad válida';
    if (n <= 0) return 'La cantidad debe ser mayor a cero';
    return null;
  }

  String? _validarPrecio(String? value) {
    final n = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (n == null) return 'Ingrese un precio válido';
    if (n <= 0) return 'El precio debe ser mayor a cero';
    return null;
  }

  void _agregarProducto() {
    if (!_formKey.currentState!.validate()) return;

    final producto = Producto(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      nombre: _nombreCtrl.text.trim(),
      cantidad: int.parse(_cantidadCtrl.text.trim()),
      precio: double.parse(_precioCtrl.text.trim().replaceAll(',', '.')),
      categoria: _categoria!,
    );

    FocusScope.of(context).unfocus();
    setState(() {
      _productos.add(producto);
      _categoria = null;
    });
    _formKey.currentState!.reset();
    _nombreCtrl.clear();
    _cantidadCtrl.clear();
    _precioCtrl.clear();
  }

  void _eliminarProducto(String id) {
    setState(() => _productos.removeWhere((p) => p.id == id));
  }

  @override
  Widget build(BuildContext context) {
    final alto = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('Inventario de productos')),
      body: SafeArea(
        child: Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: alto * 0.5),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildFormulario(),
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildLista()),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nombreCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nombre del producto',
              border: OutlineInputBorder(),
            ),
            validator: _validarNombre,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cantidadCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Cantidad en stock',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validarCantidad,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _precioCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*[.,]?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Precio unitario',
                    prefixText: 'S/ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validarPrecio,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _categoria,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
            ),
            items: _categorias
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _categoria = v),
            validator: (v) => v == null ? 'Seleccione una categoría' : null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _agregarProducto,
              icon: const Icon(Icons.add),
              label: const Text('Agregar Producto'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    if (_productos.isEmpty) {
      return const Center(child: Text('Aún no hay productos registrados'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _productos.length,
      itemBuilder: (context, index) {
        final p = _productos[index];
        return Card(
          child: ListTile(
            title: Text(p.nombre),
            subtitle: Text(
              '${p.categoria}\n'
              '${p.cantidad} × S/ ${p.precio.toStringAsFixed(2)}  =  '
              'S/ ${p.subtotal.toStringAsFixed(2)}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _eliminarProducto(p.id),
            ),
          ),
        );
      },
    );
  }
}