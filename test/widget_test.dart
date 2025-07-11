import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_app/screens/home_page.dart';
import 'package:camera/camera.dart';

void main() {
  testWidgets('App should load with fake camera', (WidgetTester tester) async {
    final fakeCamera = CameraDescription(
      name: 'FakeCamera',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    );

    await tester.pumpWidget(MaterialApp(home: HomePage(camera: fakeCamera)));

    expect(find.byType(HomePage), findsOneWidget);
  });
}
