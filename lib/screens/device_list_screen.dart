import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import '../services/custom_bluetooth_service.dart';
import '../widget/message_input.dart';
import 'messaging_screen.dart';

class DeviceListScreen extends StatefulWidget {
  @override
  _DeviceListScreenState createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  final CustomBluetoothService _bluetoothService = CustomBluetoothService();
  List<BluetoothDevice> _devices = [];
  TextEditingController _messageController = TextEditingController();
  bool _isConnected = false; // Track connection status

  @override
  void initState() {
    super.initState();
    startScan(); // Start scanning for devices
  }

  Future<void> startScan() async {
    try {
      await _bluetoothService.startScan(context);
      _bluetoothService.getScanResults().listen(
            (devices) {
          if (mounted) {
            setState(() {
              _devices = devices;
            });
          }
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error during scanning: $error')),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start scan: $e')),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _bluetoothService.stopScan();
    super.dispose();
  }

  void _sendMessage() {
    // Implement your message sending logic here
    print('Sending message: ${_messageController.text}');
    _messageController.clear();
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      await _bluetoothService.connectToDevice(device);
      if (mounted) {
        setState(() {
          _isConnected = true; // Update connection status on successful connection
        });
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagingScreen(device: device),
        ),
      );
    } catch (error) {
      print('Error connecting to device: $error'); // Handle connection errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to device: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Devices'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _devices.isEmpty // Check if devices list is empty
                ? Center(
              child: Text(
                'No devices found. Please ensure Bluetooth is enabled.',
                textAlign: TextAlign.center,
              ),
            )
                : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                print('Discovered device: ${device.name} (${device.id})');
                return ListTile(
                  title: Text(device.name.isNotEmpty ? device.name : 'Unknown device'),
                  subtitle: Text(device.id.toString()),
                  onTap: () {
                    if (device != null) {
                      _connectToDevice(device); // Connect to the selected device
                    } else {
                      print('Selected device is null or invalid');
                    }
                  },
                );
              },
            ),
          ),
          if (_isConnected) // Only show input field if connected
            MessageInput(controller: _messageController, onSend: _sendMessage),
        ],
      ),
    );
  }
}
