import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomBluetoothService {
  FlutterBlue flutterBlue = FlutterBlue.instance;

  Future<void> startScan(BuildContext context) async {
    try {
      await checkPermissions();
      await checkBluetoothStatus(context);
      await flutterBlue.startScan(timeout: Duration(seconds: 10));

      // Listening to scan results
      flutterBlue.scanResults.listen((results) {
        try {
          processScanResults(results);
        } catch (e) {
          print('Error processing scan results: $e');
        }
      });
    } catch (e) {
      print('Error starting scan: $e');
    }
  }

  void processScanResults(List<ScanResult> results) {
    for (ScanResult r in results) {
      // Simply print the device information
      print('${r.device.name.isNotEmpty ? r.device.name : "Unnamed Device"} found! rssi: ${r.rssi}');
      // Further processing of the device can happen here
    }
  }

  // Remove the UUID validation method
  // bool isValidDevice(ScanResult result) {
  //   return true; // Allow all devices
  // }

  Stream<List<BluetoothDevice>> getScanResults() {
    return flutterBlue.scanResults.map(
          (scanResults) => scanResults
          .map((result) => result.device) // Include all devices
          .toList(),
    ).asBroadcastStream();
  }

  Future<void> stopScan() async {
    try {
      await flutterBlue.stopScan();
    } catch (e) {
      print("Error stopping scan: $e");
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await stopScan(); // Ensure scanning is stopped before connecting
    try {
      await device.connect(autoConnect: false);
      print("Connected to ${device.name}");
    } catch (e) {
      print("Error connecting to ${device.name}: $e");
    }
  }

  Future<void> disconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      print("Disconnected from ${device.name}");
    } catch (e) {
      print("Error disconnecting from ${device.name}: $e");
    }
  }

  Future<void> checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
        statuses[Permission.bluetoothConnect] != PermissionStatus.granted ||
        statuses[Permission.location] != PermissionStatus.granted) {
      throw Exception("Bluetooth permissions not granted");
    }
  }

  Future<void> checkBluetoothStatus(BuildContext context) async {
    if (!(await flutterBlue.isOn)) {
      _showBluetoothEnableDialog(context);
    }
  }

  void _showBluetoothEnableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Bluetooth Disabled"),
          content: Text("Please enable Bluetooth to scan for devices."),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text("Open Settings"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                openBluetoothSettings(); // Open Bluetooth settings
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> openBluetoothSettings() async {
    await Permission.bluetooth.request(); // Request Bluetooth permission (could prompt system dialog)
    // Alternatively, use other methods to open settings manually.
  }
}
