import 'dart:async';
import 'dart:io';

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

class ArduinoFlashApp extends StatelessWidget {
  const ArduinoFlashApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arduino Flash App Demo',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const ArduinoFlashHomePage(title: 'Angel Ankle Module Flash App'),
    );
  }
}

class ArduinoFlashHomePage extends StatefulWidget {
  const ArduinoFlashHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<ArduinoFlashHomePage> createState() => _ArduinoFlashHomePageState();
}

class _ArduinoFlashHomePageState extends State<ArduinoFlashHomePage> {
  var availablePorts = [];

  int _counter = 0;

  String stdoutText = "";
  StreamController<List<int>>? _controller;
  String bossacToolPath = "";
  String binFilePath = "";
  String selectedCom = "";

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
    ProcessResult result = await runCmd(
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
        stdout: _controller?.sink);
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

  void _burn() async {
    var cmd = ProcessCmd('echo', ['hello world'], runInShell: runInShell);
    await runCmd(cmd, verbose: true);

    // Calling dart
    cmd = DartCmd(['--version']);
    await runCmd(cmd, verbose: true);

    stdoutText = "";

    runCmd(PubCmd(['global', 'list']), verbose: true);

    ProcessResult result = await runCmd(
        ProcessCmd(
          '${bossacToolPath}',
          [
            '-d',
            '--port=${selectedCom}',
            '-U',
            '-i',
            '-e',
            '-w',
            '${binFilePath}',
            '-R'
          ],
        ),
        verbose: true);
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: Text("프로덕트"),
              subtitle: Text("엔젤앵클"),
            ),
            ListTile(
              title: Text("부서"),
              subtitle: Text("로봇연구개발팀"),
            ),
            ListTile(
              title: Text("개발"),
              subtitle: Text("박제창"),
            ),
            ListTile(
              title: Text("(주)엔젤로보틱스"),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Com"),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final address in availablePorts)
                          Builder(builder: (context) {
                            final port = SerialPort(address);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCom = address;
                                });
                              },
                              child: ExpansionTile(
                                onExpansionChanged: (v) {
                                  setState(() {
                                    selectedCom = address;
                                  });
                                },
                                title: Text(address),
                                children: [
                                  CardListTile('Description', port.description),
                                  CardListTile('Transport',
                                      port.transport.toTransport()),
                                  CardListTile(
                                      'USB Bus', port.busNumber?.toPadded()),
                                  CardListTile('USB Device',
                                      port.deviceNumber?.toPadded()),
                                  CardListTile(
                                      'Vendor ID', port.vendorId?.toHex()),
                                  CardListTile(
                                      'Product ID', port.productId?.toHex()),
                                  CardListTile(
                                      'Manufacturer', port.manufacturer),
                                  CardListTile(
                                      'Product Name', port.productName),
                                  CardListTile(
                                      'Serial Number', port.serialNumber),
                                  CardListTile('MAC Address', port.macAddress),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ButtonBar(
              children: [
                ElevatedButton(
                    onPressed: () async {
                      setState(
                          () => availablePorts = SerialPort.availablePorts);
                    },
                    child: Text("포트 새로고침")),
              ],
            ),
            Divider(color: Colors.black),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Output"),
                Expanded(
                  child: ListView(
                    children: [
                      Text("${stdoutText}"),
                    ],
                  ),
                ),
              ],
            )),
            Divider(color: Colors.black),
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("선택한 포트: $selectedCom"),
                  Text("선택한 툴 경로: $bossacToolPath"),
                  Text("선택한 Bin 파일: $binFilePath"),
                ],
              ),
            ),
            ButtonBar(
              children: [
                ElevatedButton(
                    onPressed: () async {
                      final file = OpenFilePicker()
                        ..filterSpecification = {
                          'All Files': '*.*',
                          'Word Document (*.doc)': '*.doc',
                          'Web Page (*.htm; *.html)': '*.htm;*.html',
                          'Text Document (*.txt)': '*.txt',
                        }
                        ..defaultFilterIndex = 0
                        ..defaultExtension = '*.*'
                        ..title = 'Select a Flash Tool';

                      final result = file.getFile();
                      if (result != null) {
                        print(result.path);
                        setState(() {
                          bossacToolPath = result.path;
                        });
                      }
                    },
                    child: Text("툴 선택")),
                ElevatedButton(
                    onPressed: () async {
                      final file = OpenFilePicker()
                        ..filterSpecification = {
                          'All Files': '*.*',
                          'Word Document (*.doc)': '*.doc',
                          'Web Page (*.htm; *.html)': '*.htm;*.html',
                          'Text Document (*.txt)': '*.txt',
                        }
                        ..defaultFilterIndex = 0
                        ..defaultExtension = '*.*'
                        ..title = 'Select a bin file';

                      final result = file.getFile();
                      if (result != null) {
                        print(result.path);
                        setState(() {
                          binFilePath = result.path;
                        });
                      }
                    },
                    child: Text("파일선택")),
                ElevatedButton(onPressed: _burn, child: Text("Burn"))
              ],
            )
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        backgroundColor: Colors.red,
        tooltip: 'Flash Test',
        child: const Icon(Icons.upload_file),
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
