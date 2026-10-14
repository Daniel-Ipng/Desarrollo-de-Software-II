import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Cambia "practica06" por el nombre de tu paquete (campo name en pubspec.yaml).
import '../lib/main.dart';

void setScreen(WidgetTester tester, double width, double height,
    {double textScale = 1.0}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearAllTestValues();
  });
}

void main() {
  testWidgets('Móvil (360px): barra inferior y sin riel', (tester) async {
    setScreen(tester, 360, 740);
    await tester.pumpWidget(const App());
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tablet (800px): riel lateral y sin barra inferior', (tester) async {
    setScreen(tester, 800, 1000);
    await tester.pumpWidget(const App());
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Escritorio (1440px): riel y sin desbordes', (tester) async {
    setScreen(tester, 1440, 900);
    await tester.pumpWidget(const App());
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320px con textScale 1.5 no desborda', (tester) async {
    setScreen(tester, 320, 640, textScale: 1.5);
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Botón Añadir tiene etiqueta semántica completa', (tester) async {
    final handle = tester.ensureSemantics();
    setScreen(tester, 400, 800);
    await tester.pumpWidget(const App());
    expect(find.bySemanticsLabel('Añadir Cuaderno A4 al carrito'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Añadir al carrito actualiza el total', (tester) async {
    setScreen(tester, 400, 800);
    await tester.pumpWidget(const App());
    await tester.tap(find.text('Añadir').first);
    await tester.pump();
    await tester.tap(find.text('Carrito'));
    await tester.pumpAndSettle();
    expect(find.text('Total: S/ 8.50'), findsOneWidget);
  });
}