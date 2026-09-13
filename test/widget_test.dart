// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:multi_phone_sync/app/app.dart';

void main() {
  testWidgets('shows the Phase 1 home foundation', (WidgetTester tester) async {
    await tester.pumpWidget(const MultiPhoneSyncApp());

    expect(find.text('MultiPhone Sync'), findsOneWidget);
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Create Room'), findsOneWidget);
    expect(find.text('Join Room'), findsOneWidget);
  });

  testWidgets('navigates from Home to Create Room', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MultiPhoneSyncApp());
    await tester.tap(find.text('Create Room'));
    await tester.pumpAndSettle();

    expect(find.text('Room Name'), findsOneWidget);
    expect(find.text('Device Limit'), findsOneWidget);
  });

  testWidgets('creates a room with its Phase 2 room code', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MultiPhoneSyncApp());
    await tester.tap(find.text('Create Room'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('4827'), findsOneWidget);
    expect(find.text('Host'), findsOneWidget);
    expect(find.text('Connected Devices'), findsOneWidget);
  });

  testWidgets('requires a four-digit room code before joining', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MultiPhoneSyncApp());
    await tester.tap(find.text('Join Room'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('Enter a 4-digit room code.'), findsOneWidget);
    expect(find.text('Client Room'), findsNothing);
  });
}
