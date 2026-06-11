import 'package:flutter/material.dart';
import 'package:manage_calendar_events/manage_calendar_events.dart';

import 'screens/calendar_list.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  MyApp({super.key, CalendarPlugin? plugin})
      : _plugin = plugin ?? CalendarPlugin();

  final CalendarPlugin _plugin;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: CalendarPluginCheck(plugin: _plugin));
  }
}

class CalendarPluginCheck extends StatelessWidget {
  CalendarPluginCheck({super.key, CalendarPlugin? plugin})
      : _myPlugin = plugin ?? CalendarPlugin();

  final CalendarPlugin _myPlugin;

  Future<bool> _ensurePermissions() async {
    final hasPermission = await _myPlugin.hasPermissions() ?? false;
    if (hasPermission) {
      return true;
    }
    return _myPlugin.requestPermissions();
  }

  Future<void> _showCalendars(BuildContext context) async {
    final granted = await _ensurePermissions();
    if (!granted || !context.mounted) {
      return;
    }
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => CalendarList()));
  }

  Future<void> _addCalendar() async {
    final granted = await _ensurePermissions();
    if (!granted) {
      return;
    }

    final existingCalendar = await _myPlugin.getCalendar(name: 'supermonkey');
    if (existingCalendar != null) {
      return;
    }

    await _myPlugin.createCalendar(
      Calendar(
        id: 'supermonkey',
        name: 'supermonkey',
        displayName: 'supermonkey',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(),
          ElevatedButton(
            onPressed: () => _showCalendars(context),
            child: Text('Show Calendars'),
          ),
          ElevatedButton(
            onPressed: _addCalendar,
            child: Text('Add Calendars'),
          ),
        ],
      ),
    );
  }
}
