import 'dart:async';
import 'dart:io';

import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class ThermalPrinterDevice {
  final String id;
  final String name;
  final String address;
  final bool isConnected;

  const ThermalPrinterDevice({
    required this.id,
    required this.name,
    required this.address,
    this.isConnected = false,
  });

  factory ThermalPrinterDevice.fromBluetoothDevice(
    BluetoothDevice device, {
    required String id,
  }) {
    final rawName = (device.name ?? '').trim();
    final rawAddress = (device.address ?? '').trim();

    final normalizedName = rawName.isEmpty ? 'Sem nome' : rawName;
    final normalizedAddress = rawAddress.isEmpty ? id : rawAddress;

    return ThermalPrinterDevice(
      id: id,
      name: normalizedName,
      address: normalizedAddress,
      isConnected: device.connected ?? false,
    );
  }
}

enum PrinterConnectionStatus { disconnected, connecting, connected, error }

class PrinterConnectionUpdate {
  final PrinterConnectionStatus status;
  final ThermalPrinterDevice? device;
  final String? message;

  const PrinterConnectionUpdate({
    required this.status,
    this.device,
    this.message,
  });
}

class ThermalPrinterService {
  ThermalPrinterService({BluetoothPrint? bluetoothPrint})
      : _bluetoothPrint = bluetoothPrint ?? BluetoothPrint.instance {
    _scanSubscription =
        _bluetoothPrint.scanResults.listen(_handleScanResults);

    _stateSubscription = _bluetoothPrint.state.listen((state) async {
      if (state == BluetoothPrint.CONNECTED) {
        final device = _currentDevice;
        _connectionController.add(
          PrinterConnectionUpdate(
            status: PrinterConnectionStatus.connected,
            device: device != null
                ? ThermalPrinterDevice.fromBluetoothDevice(
                    device,
                    id: _currentDeviceId ?? _deviceKey(device),
                  )
                : null,
          ),
        );
      } else if (state == BluetoothPrint.DISCONNECTED) {
        _currentDevice = null;
        _currentDeviceId = null;
        _connectionController.add(
          const PrinterConnectionUpdate(
              status: PrinterConnectionStatus.disconnected),
        );
      } else {
        final device = _currentDevice;
        if (device != null) {
          _connectionController.add(
            PrinterConnectionUpdate(
              status: PrinterConnectionStatus.connecting,
              device: ThermalPrinterDevice.fromBluetoothDevice(
                device,
                id: _currentDeviceId ?? _deviceKey(device),
              ),
            ),
          );
        }
      }
    });
  }

  final BluetoothPrint _bluetoothPrint;
  final _devicesController =
      StreamController<List<ThermalPrinterDevice>>.broadcast();
  final _connectionController =
      StreamController<PrinterConnectionUpdate>.broadcast();
  final _scanningController = StreamController<bool>.broadcast();

  late final StreamSubscription<List<BluetoothDevice>> _scanSubscription;
  late final StreamSubscription<int> _stateSubscription;

  final Map<String, BluetoothDevice> _lastScanDevices = {};
  final Map<String, BluetoothDevice> _bondedDevices = {};
  BluetoothDevice? _currentDevice;
  String? _currentDeviceId;
  Timer? _scanTimer;
  bool _isScanning = false;

  Stream<List<ThermalPrinterDevice>> get devicesStream =>
      _devicesController.stream;

  Stream<PrinterConnectionUpdate> get connectionStream =>
      _connectionController.stream;

  bool get isScanning => _isScanning;

  Stream<bool> get scanningStream => _scanningController.stream;

  ThermalPrinterDevice? get connectedDevice => _currentDevice == null
      ? null
      : ThermalPrinterDevice.fromBluetoothDevice(
          _currentDevice!,
          id: _currentDeviceId ?? _deviceKey(_currentDevice!),
        );

  Future<bool> ensurePermissions() async {
    if (Platform.isAndroid) {
      final bluetoothStatuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ].request();

      final allBluetoothGranted = bluetoothStatuses.values
          .every((status) => status == PermissionStatus.granted);

      if (!allBluetoothGranted) {
        return false;
      }

      final locationStatus = await Permission.location.status;
      if (locationStatus.isDenied || locationStatus.isRestricted) {
        final requested = await Permission.location.request();
        if (!requested.isGranted) {
          return false;
        }
      } else if (locationStatus.isPermanentlyDenied) {
        return false;
      }
    }

    return true;
  }

  Future<void> startScan(
      {Duration timeout = const Duration(seconds: 6)}) async {
    if (_isScanning) return;
    _isScanning = true;
    _scanningController.add(true);
    _scanTimer?.cancel();
    try {
      await _bluetoothPrint.startScan(timeout: timeout);

      _scanTimer = Timer(timeout + const Duration(milliseconds: 500), () {
        _isScanning = false;
        _scanningController.add(false);
      });
    } catch (e) {
      _isScanning = false;
      _scanningController.add(false);
      rethrow;
    } finally {
      await _loadBondedDevices();
    }
  }

  Future<void> stopScan() async {
    _scanTimer?.cancel();
    _isScanning = false;
    _scanningController.add(false);
    await _bluetoothPrint.stopScan();
  }

  Future<void> connect(ThermalPrinterDevice device) async {
    final target = _resolveDevice(device.id);

    if (target == null) {
      _connectionController.add(
        PrinterConnectionUpdate(
          status: PrinterConnectionStatus.error,
          device: device,
          message: 'Impressora não encontrada. Tente buscar novamente.',
        ),
      );
      return;
    }

    _currentDevice = target;
    _currentDeviceId = device.id;
    _connectionController.add(
      PrinterConnectionUpdate(
        status: PrinterConnectionStatus.connecting,
        device: ThermalPrinterDevice.fromBluetoothDevice(
          target,
          id: device.id,
        ),
      ),
    );

    try {
      final result = await _bluetoothPrint.connect(target);
      if (result != true) {
        _currentDevice = null;
        _currentDeviceId = null;
        _connectionController.add(
          PrinterConnectionUpdate(
            status: PrinterConnectionStatus.error,
            device: ThermalPrinterDevice.fromBluetoothDevice(
              target,
              id: device.id,
            ),
            message: 'Não foi possível conectar à impressora.',
          ),
        );
      }
    } catch (e) {
      _currentDevice = null;
      _currentDeviceId = null;
      _connectionController.add(
        PrinterConnectionUpdate(
          status: PrinterConnectionStatus.error,
          device: ThermalPrinterDevice.fromBluetoothDevice(
            target,
            id: device.id,
          ),
          message: 'Erro ao conectar: $e',
        ),
      );
    }
  }

  Future<void> disconnect() async {
    await _bluetoothPrint.disconnect();
    _currentDevice = null;
    _currentDeviceId = null;
    _connectionController.add(
      const PrinterConnectionUpdate(
          status: PrinterConnectionStatus.disconnected),
    );
  }

  Future<bool> isConnected() async {
    final isConnected = await _bluetoothPrint.isConnected;
    return isConnected == true;
  }

  Future<void> printLines(
    List<LineText> lines, {
    Map<String, dynamic>? config,
  }) async {
    final connected = await isConnected();
    if (!connected) {
      throw StateError('Nenhuma impressora conectada.');
    }

    await _bluetoothPrint.printReceipt(config ?? <String, dynamic>{}, lines);
  }

  void dispose() {
    _scanTimer?.cancel();
    _scanSubscription.cancel();
    _stateSubscription.cancel();
    _devicesController.close();
    _connectionController.close();
    _scanningController.close();
  }

  void _handleScanResults(List<BluetoothDevice> devices) {
    _lastScanDevices
      ..clear()
      ..addEntries(
        devices.map((device) {
          final key = _deviceKey(device);
          return MapEntry(key, device);
        }),
      );

    _emitDevices();
  }

  Future<void> _loadBondedDevices() async {
    try {
      final bondedDevices = await _bluetoothPrint.getBondedDevices();
      _bondedDevices
        ..clear()
        ..addEntries(
          bondedDevices.map((device) {
            final key = _deviceKey(device);
            return MapEntry(key, device);
          }),
        );
      _emitDevices();
    } catch (_) {
      // Ignore failures when fetching bonded devices; scanning remains primary.
    }
  }

  BluetoothDevice? _resolveDevice(String id) {
    return _lastScanDevices[id] ?? _bondedDevices[id];
  }

  void _emitDevices() {
    final seen = <String>{};
    final devices = <ThermalPrinterDevice>[];

    void addFrom(Map<String, BluetoothDevice> source) {
      for (final entry in source.entries) {
        if (!seen.add(entry.key)) {
          continue;
        }
        devices.add(
          ThermalPrinterDevice.fromBluetoothDevice(
            entry.value,
            id: entry.key,
          ),
        );
      }
    }

    addFrom(_lastScanDevices);
    addFrom(_bondedDevices);

    if (_devicesController.isClosed) {
      return;
    }

    _devicesController.add(List.unmodifiable(devices));
  }
}

String _deviceKey(BluetoothDevice device) {
  final address = device.address;
  if (address != null && address.trim().isNotEmpty) {
    return address.trim();
  }

  final name = device.name;
  if (name != null && name.trim().isNotEmpty) {
    return name.trim();
  }

  return device.hashCode.toString();
}

final thermalPrinterServiceProvider = Provider<ThermalPrinterService>((ref) {
  final service = ThermalPrinterService();
  ref.onDispose(service.dispose);
  return service;
});
