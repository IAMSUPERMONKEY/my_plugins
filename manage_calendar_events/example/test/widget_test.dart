import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manage_calendar_events/manage_calendar_events.dart';

import '../lib/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('manage_calendar_events');
  final List<MethodCall> log = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    log.clear();
  });

  testWidgets('Add Calendars requests permission before creating',
      (WidgetTester tester) async {
    messenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      switch (methodCall.method) {
        case 'hasPermissions':
          return false;
        case 'requestPermissions':
          return true;
        case 'getCalendar':
          return null;
        case 'createCalendar':
          return '42';
        default:
          return null;
      }
    });

    await tester.pumpWidget(MyApp());
    await tester.tap(find.text('Add Calendars'));
    await tester.pumpAndSettle();

    expect(log.map((call) => call.method), <String>[
      'hasPermissions',
      'requestPermissions',
      'getCalendar',
      'createCalendar',
    ]);
    expect(log.last.arguments, <String, Object?>{
      'id': 'supermonkey',
      'name': 'supermonkey',
      'accountName': null,
      'ownerName': null,
      'isReadOnly': null,
      'type': null,
      'displayName': 'supermonkey',
    });
  });

  testWidgets('Add Calendars skips create when calendar already exists',
      (WidgetTester tester) async {
    messenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      switch (methodCall.method) {
        case 'hasPermissions':
          return true;
        case 'getCalendar':
          return '{"id":"1","name":"supermonkey","accountName":"supermonkey","ownerName":"supermonkey","isReadOnly":false,"type":"local","displayName":"supermonkey"}';
        default:
          return null;
      }
    });

    await tester.pumpWidget(MyApp());
    await tester.tap(find.text('Add Calendars'));
    await tester.pumpAndSettle();

    expect(log.map((call) => call.method), <String>[
      'hasPermissions',
      'getCalendar',
    ]);
  });

  testWidgets('Add Calendars stops when permission is denied',
      (WidgetTester tester) async {
    messenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      switch (methodCall.method) {
        case 'hasPermissions':
          return false;
        case 'requestPermissions':
          return false;
        default:
          return null;
      }
    });

    await tester.pumpWidget(MyApp());
    await tester.tap(find.text('Add Calendars'));
    await tester.pumpAndSettle();

    expect(log.map((call) => call.method), <String>[
      'hasPermissions',
      'requestPermissions',
    ]);
  });
}
