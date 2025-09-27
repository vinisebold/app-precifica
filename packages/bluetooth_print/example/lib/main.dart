
import 'dart:async';
import 'dart:convert';

import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BluetoothPrint bluetoothPrint = BluetoothPrint.instance;

  bool _connected = false;
  BluetoothDevice? _device;
  String tips = 'no device connect';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => initBluetooth());
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initBluetooth() async {
    bluetoothPrint.startScan(timeout: const Duration(seconds: 4));

    bool isConnected=await bluetoothPrint.isConnected??false;

    bluetoothPrint.state.listen((state) {
      print('******************* cur device status: $state');

      switch (state) {
        case BluetoothPrint.CONNECTED:
          setState(() {
            _connected = true;
            tips = 'connect success';
          });
          break;
        case BluetoothPrint.DISCONNECTED:
          setState(() {
            _connected = false;
            tips = 'disconnect success';
          });
          break;
        default:
          break;
      }
    });

    if (!mounted) return;

    if(isConnected) {
      setState(() {
        _connected=true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('BluetoothPrint example app'),
          ),
          body: RefreshIndicator(
            onRefresh: () =>
                bluetoothPrint.startScan(timeout: const Duration(seconds: 4)),
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        child: Text(tips),
                      ),
                    ],
                  ),
                  const Divider(),
                  StreamBuilder<List<BluetoothDevice>>(
                    stream: bluetoothPrint.scanResults,
                    initialData: const [],
                    builder: (c, snapshot) => Column(
                      children: snapshot.data!.map((d) => ListTile(
                        title: Text(d.name??''),
                        subtitle: Text(d.address??''),
                        onTap: () async {
                          setState(() {
                            _device = d;
                          });
                        },
                        trailing: _device!=null && _device!.address == d.address?const Icon(
                          Icons.check,
                          color: Colors.green,
                        ):null,
                      )).toList(),
                    ),
                  ),
                  const Divider(),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            OutlinedButton(
                              onPressed:  _connected?null:() async {
                                if(_device!=null && _device!.address !=null){
                                  setState(() {
                                    tips = 'connecting...';
                                  });
                                  await bluetoothPrint.connect(_device!);
                                }else{
                                  setState(() {
                                    tips = 'please select device';
                                  });
                                  print('please select device');
                                }
                              },
                              child: const Text('connect'),
                            ),
                            const SizedBox(width: 10.0),
                            OutlinedButton(
                              onPressed:  _connected?() async {
                                setState(() {
                                  tips = 'disconnecting...';
                                });
                                await bluetoothPrint.disconnect();
                              }:null,
                              child: const Text('disconnect'),
                            ),
                          ],
                        ),
                        const Divider(),
                        OutlinedButton(
                          onPressed:  _connected?() async {
                            Map<String, dynamic> config = {};

                            List<LineText> list = [];

                            list.add(LineText(type: LineText.TYPE_TEXT, content: '**********************************************', weight: 1, align: LineText.ALIGN_CENTER,linefeed: 1));
                            list.add(LineText(type: LineText.TYPE_TEXT, content: '打印单据头', weight: 1, align: LineText.ALIGN_CENTER, fontZoom: 2, linefeed: 1));
                            list.add(LineText(linefeed: 1));

                            list.add(LineText(type: LineText.TYPE_TEXT, content: '----------------------明细---------------------', weight: 1, align: LineText.ALIGN_CENTER, linefeed: 1));
                            list.add(LineText(type: LineText.TYPE_TEXT, content: '物资名称规格型号', weight: 1, align: LineText.ALIGN_LEFT, x: 0,relativeX: 0, linefeed: 0));
                            list.add(LineText(type: LineText.TYPE_TEXT, content: '单位', weight: 1, align: LineText.ALIGN_LEFT, x: 350, relativeX: 0, linefeed: 0));
                            list.add(LineText(type: LineText.TYPE_TEXT, content: '数量', weight: 1, align: LineText.ALIGN_LEFT, x: 500, relativeX: 0, linefeed: 1));

                            list.add(LineText(type: LineText.TYPE_TEXT, content: '混凝土C30', align: LineText.ALIGN_LEFT, x: 0,relativeX: 0, linefeed: 0));
                            list.add(LineText(type: LineText.TYPE_TEXT, content: '吨', align: LineText.ALIGN_LEFT, x: 350, relativeX: 0, linefeed: 0));
                            list.add(LineText(type: LineText.TYPE_TEXT, content: '12.0', align: LineText.ALIGN_LEFT, x: 500, relativeX: 0, linefeed: 1));

                            list.add(LineText(type: LineText.TYPE_TEXT, content: '**********************************************', weight: 1, align: LineText.ALIGN_CENTER,linefeed: 1));
                            list.add(LineText(linefeed: 1));

                            ByteData data = await rootBundle.load("assets/images/bluetooth_print.png");
                            List<int> imageBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
                            String base64Image = base64Encode(imageBytes);
                            // list.add(LineText(type: LineText.TYPE_IMAGE, content: base64Image, align: LineText.ALIGN_CENTER, linefeed: 1));

                            await bluetoothPrint.printReceipt(config, list);
                          }:null,
                          child: const Text('print receipt(esc)'),
                        ),
                        OutlinedButton(
                          onPressed:  _connected?() async {
                            Map<String, dynamic> config = {};
                            config['width'] = 40; // 标签宽度，单位mm
                            config['height'] = 70; // 标签高度，单位mm
                            config['gap'] = 2; // 标签间隔，单位mm

                            // x、y坐标位置，单位dpi，1mm=8dpi
                            List<LineText> list = [];
                            list.add(LineText(type: LineText.TYPE_TEXT, x:10, y:10, content: 'A Title'));
                            list.add(LineText(type: LineText.TYPE_TEXT, x:10, y:40, content: 'this is content'));
                            list.add(LineText(type: LineText.TYPE_QRCODE, x:10, y:70, content: 'qrcode i\n'));
                            list.add(LineText(type: LineText.TYPE_BARCODE, x:10, y:190, content: 'qrcode i\n'));

                            List<LineText> list1 = [];
                            ByteData data = await rootBundle.load("assets/images/guide3.png");
                            List<int> imageBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
                            String base64Image = base64Encode(imageBytes);
                            list1.add(LineText(type: LineText.TYPE_IMAGE, x:10, y:10, content: base64Image,));

                            await bluetoothPrint.printLabel(config, list);
                            await bluetoothPrint.printLabel(config, list1);
                          }:null,
                          child: const Text('print label(tsc)'),
                        ),
                        OutlinedButton(
                          onPressed:  _connected?() async {
                            await bluetoothPrint.printTest();
                          }:null,
                          child: const Text('print selftest'),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        floatingActionButton: StreamBuilder<bool>(
          stream: bluetoothPrint.isScanning,
          initialData: false,
          builder: (c, snapshot) {
            if (snapshot.data == true) {
              return FloatingActionButton(
                onPressed: () => bluetoothPrint.stopScan(),
                backgroundColor: Colors.red,
                child: const Icon(Icons.stop),
              );
            } else {
              return FloatingActionButton(
                  child: const Icon(Icons.search),
                  onPressed: () => bluetoothPrint.startScan(timeout: const Duration(seconds: 4)));
            }
          },
        ),
      ),
    );
  }
}
