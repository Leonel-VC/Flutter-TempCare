import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MyBluetoothService {
  static final MyBluetoothService _instance = MyBluetoothService._internal();
  factory MyBluetoothService() => _instance;
  MyBluetoothService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _characteristic;

  // Stream to broadcast data received from the ESP32
  final _dataStreamController = StreamController<String>.broadcast();
  Stream<String> get dataStream => _dataStreamController.stream;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;

  Future<bool> checkBluetooth() async {
    return await FlutterBluePlus.isSupported;
  }

  Future<void> enableBluetooth() async {
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
    }
  }

  Future<List<BluetoothDevice>> scanDevices() async {
    List<BluetoothDevice> devices = [];
    bool isScanning = false;

    try {
      var subscription = FlutterBluePlus.scanResults.listen((results) {
        devices = results.map((r) => r.device).toList();
      });

      isScanning = true;
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        androidUsesFineLocation: false,
      );

      await Future.delayed(const Duration(seconds: 4));
      subscription.cancel();
      return devices;
    } finally {
      if (isScanning) {
        await FlutterBluePlus.stopScan();
      }
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect(autoConnect: false);
    _connectedDevice = device;

    List<BluetoothService> services = await device.discoverServices();

    for (var service in services) {
      for (var characteristic in service.characteristics) {
        // Tu UUID característico
        if (characteristic.uuid.toString() == "beb5483e-36e1-4688-b7f5-ea07361b26a8") {
          _characteristic = characteristic;

          await _characteristic!.setNotifyValue(true);
          _characteristic!.lastValueStream.listen((value) {
            if (value.isNotEmpty) {
              String receivedData = utf8.decode(value);
              _dataStreamController.add(receivedData);
            }
          });
          break;
        }
      }
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _characteristic = null;
    }
  }
}