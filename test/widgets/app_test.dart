import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/main.dart';

void main() {
  group('App Widget Tests', () {
    testWidgets('SplashScreen displays CircularProgressIndicator', (WidgetTester tester) async {
      // Set up test rendering
      tester.binding.window.physicalSizeTestValue = const Size(800, 600);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      
      // Build the app
      await tester.pumpWidget(const MyApp());
      
      // Brief pump to render
      await tester.pump(const Duration(milliseconds: 10));
      
      // Verify progress indicator is present
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('MyApp has MaterialApp with correct config', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800, 600);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      
      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 10));

      // Verify MaterialApp
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Get MaterialApp widget
      final materialApp = find.byType(MaterialApp).evaluate().first.widget as MaterialApp;
      
      // Verify configuration
      expect(materialApp.debugShowCheckedModeBanner, false);
      expect(materialApp.title, 'Flutter POS');
    });

    testWidgets('Splash screen is shown on app start', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800, 600);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      
      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 10));

      // Verify scaffold is displayed
      expect(find.byType(Scaffold), findsWidgets);
      
      // Verify progress indicator (loading indicator)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
