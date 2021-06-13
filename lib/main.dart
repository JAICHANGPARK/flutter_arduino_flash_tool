import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:filepicker_windows/filepicker_windows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:process_run/cmd_run.dart';

final runInShell = Platform.isWindows;

extension IntToString on int {
  String toHex() => '0x${toRadixString(16)}';

  String toPadded([int width = 3]) => toString().padLeft(width, '0');

  String toTransport() {
    switch (this) {
      case SerialPortTransport.usb:
        return 'USB';
      case SerialPortTransport.bluetooth:
        return 'Bluetooth';
      case SerialPortTransport.native:
        return 'Native';
      default:
        return 'Unknown';
    }
  }
}

void main() async {
  var cmd = ProcessCmd('echo', ['hello world'], runInShell: runInShell);
  await runCmd(cmd);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var availablePorts = [];

  int _counter = 0;

  String stdoutText = "";
  StreamController<List<int>>? _controller;

  void _incrementCounter() async {
    var cmd = ProcessCmd('echo', ['hello world'], runInShell: runInShell);
    await runCmd(cmd, verbose: true);

    // Calling dart
    cmd = DartCmd(['--version']);
    await runCmd(cmd, verbose: true);

    stdoutText = "";

    runCmd(PubCmd(['global', 'list']), verbose: true);

    // runCmd(
    //   ProcessCmd(
    //     'C:\\Users\\HOME613\\Desktop\\bossac.exe',
    //     [
    //       '-d',
    //       '--port=COM3',
    //       '-U',
    //       '-i',
    //       '-e',
    //       '-w',
    //       'C:\\Users\\HOME613\\AppData\\Local\\Temp\\arduino_build_168554/Blink.ino.bin',
    //       '-R'
    //     ],
    //   ),
    //   verbose: true,
    // ).asStream().listen((event) {
    //   print("");
    //   print(event.stdout.toString());
    //   setState(() {
    //     stdoutText += event.stdout.toString();
    //   });
    // });
    ProcessResult result =  await runCmd(
        ProcessCmd(
          'C:\\Users\\HOME613\\Desktop\\bossac.exe',
          [
            '-d',
            '--port=COM3',
            '-U',
            '-i',
            '-e',
            '-w',
            'C:\\Users\\HOME613\\AppData\\Local\\Temp\\arduino_build_168554/Blink.ino.bin',
            '-R'
          ],
        ),
        verbose: true,
      stdout: _controller?.sink
    );
    print(">>>>>>>>");
    print(result.stdout.toString());
    print(result.exitCode.toString());
    print(result.stderr.toString());

    setState(() {
      _counter++;

      stdoutText += result.stderr.toString();
      stdoutText += result.stdout.toString();
    });
  }

  void initPorts() {
    print(">> SerialPort.availablePorts ${SerialPort.availablePorts}");
    setState(() => availablePorts = SerialPort.availablePorts);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initPorts();

    _controller?.stream.listen((event) {
      print(">>> controller : $event");
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: Scrollbar(
                child: ListView(
                  children: [
                    for (final address in availablePorts)
                      Builder(builder: (context) {
                        final port = SerialPort(address);
                        return ExpansionTile(
                          title: Text(address),
                          children: [
                            CardListTile('Description', port.description),
                            CardListTile('Transport', port.transport.toTransport()),
                            CardListTile('USB Bus', port.busNumber?.toPadded()),
                            CardListTile('USB Device', port.deviceNumber?.toPadded()),
                            CardListTile('Vendor ID', port.vendorId?.toHex()),
                            CardListTile('Product ID', port.productId?.toHex()),
                            CardListTile('Manufacturer', port.manufacturer),
                            CardListTile('Product Name', port.productName),
                            CardListTile('Serial Number', port.serialNumber),
                            CardListTile('MAC Address', port.macAddress),
                          ],
                        );
                      }),
                  ],
                ),
              ),
            ),
            Expanded(
                child: ListView(
              children: [
                Text("${stdoutText}"),
              ],
            )),
            ButtonBar(
              children: [
                ElevatedButton(
                    onPressed: () async {
                      setState(() => availablePorts = SerialPort.availablePorts);
                    },
                    child: Text("새로고침")),
                ElevatedButton(
                    onPressed: () async {
                      final file = OpenFilePicker()
                        ..filterSpecification = {
                          'Word Document (*.doc)': '*.doc',
                          'Web Page (*.htm; *.html)': '*.htm;*.html',
                          'Text Document (*.txt)': '*.txt',
                          'All Files': '*.*'
                        }
                        ..defaultFilterIndex = 0
                        ..defaultExtension = 'doc'
                        ..title = 'Select a document';

                      final result = file.getFile();
                      if (result != null) {
                        print(result.path);
                      }
                    },
                    child: Text("파일선택"))
              ],
            )
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class CardListTile extends StatelessWidget {
  final String name;
  final String? value;

  CardListTile(this.name, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(value ?? 'N/A'),
        subtitle: Text(name),
      ),
    );
  }
}
