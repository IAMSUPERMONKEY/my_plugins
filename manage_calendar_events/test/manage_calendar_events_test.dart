import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manage_calendar_events/manage_calendar_events.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('manage_calendar_events');
  final List<MethodCall> log = <MethodCall>[];
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      if (methodCall.method == 'getCalendars') {
        return '[{"id":"1","name":"Work","accountName":"local","ownerName":"me","isReadOnly":false,"type":"local","displayName":"Work"}]';
      }
      if (methodCall.method == 'getDefaultCalendar' || methodCall.method == 'getCalendar') {
        return '{"id":"1","name":"Work","accountName":"local","ownerName":"me","isReadOnly":false,"type":"local","displayName":"Work"}';
      }
      if (methodCall.method == 'deleteCalendar') {
        return true;
      }
      return '42';
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    log.clear();
  });

  test('getPlatformVersion', () async {
    expect(await CalendarPlugin.platformVersion, '42');
  });

  test('getCalendars decodes channel payload', () async {
    final calendars = await CalendarPlugin().getCalendars();

    expect(calendars, isNotNull);
    expect(calendars, hasLength(1));
    expect(calendars!.single.name, 'Work');
    expect(calendars.single.type, 'local');
    expect(log.single.method, 'getCalendars');
  });

  test('getDefaultCalendar decodes single calendar payload', () async {
    final calendar = await CalendarPlugin().getDefaultCalendar();

    expect(calendar, isNotNull);
    expect(calendar!.displayName, 'Work');
    expect(log.single.method, 'getDefaultCalendar');
  });

  test('getCalendar sends lookup arguments', () async {
    final calendar = await CalendarPlugin().getCalendar(name: 'Work', type: 'local');

    expect(calendar, isNotNull);
    expect(calendar!.accountName, 'local');
    expect(log.single.method, 'getCalendar');
    expect(log.single.arguments, <String, Object?>{
      'name': 'Work',
      'type': 'local',
    });
  });

  test('deleteCalendar sends calendar id', () async {
    final deleted = await CalendarPlugin().deleteCalendar(calendarId: '1');

    expect(deleted, isTrue);
    expect(log.single.method, 'deleteCalendar');
    expect(log.single.arguments, <String, Object?>{'calendarId': '1'});
  });
}
