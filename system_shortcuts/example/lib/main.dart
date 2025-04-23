import 'package:flutter/material.dart';
import 'package:system_shortcuts/system_shortcuts.dart';

void main() => runApp(Main());

class Main extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(appBar: AppBar(title: const Text('System Shortcuts')), body: MyApp()));
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Body();
  }
}

class Body extends StatelessWidget {
  const Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
        children: <Widget>[
          ElevatedButton(
            child: Text("Home"),
            onPressed: () async {
              await SystemShortcuts.home();
            },
          ),
          ElevatedButton(
            child: Text("Back"),
            onPressed: () async {
              await SystemShortcuts.back();
            },
          ),
          ElevatedButton(
            child: Text("VolDown"),
            onPressed: () async {
              await SystemShortcuts.volDown();
            },
          ),
          ElevatedButton(
            child: Text("VolUp"),
            onPressed: () async {
              await SystemShortcuts.volUp();
            },
          ),
          ElevatedButton(
            child: Text("Landscape"),
            onPressed: () async {
              await SystemShortcuts.orientLandscape();
            },
          ),
          ElevatedButton(
            child: Text("Portrait"),
            onPressed: () async {
              await SystemShortcuts.orientPortrait();
            },
          ),
          ElevatedButton(
            child: Text("Wifi"),
            onPressed: () async {
              await SystemShortcuts.wifi();
            },
          ),
          ElevatedButton(
            child: Text("Check Wifi"),
            onPressed: () async {
              bool b = await SystemShortcuts.checkWifi;
              // Scaffold.of(context).showSnackBar(
              //   SnackBar(
              //     content: Text("Wifi Turned On Check - $b"),
              //     duration: Duration(seconds: 2),
              //   ),
              // );
            },
          ),
          ElevatedButton(
            child: Text("Bluetooth"),
            onPressed: () async {
              await SystemShortcuts.bluetooth();
            },
          ),
          ElevatedButton(
            child: Text("Check Bluetooth"),
            onPressed: () async {
              bool b = await SystemShortcuts.checkBluetooth;
              // Scaffold.of(context)(
              //   SnackBar(
              //     content: Text("Bluetooth Turned On Check - $b"),
              //     duration: Duration(seconds: 2),
              //   ),
              // );
            },
          ),
        ],
      ),
    );
  }
}
