import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/custom_bluetooth_service.dart';
import 'device_list_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bluetooth Messaging')),
      body: Center(
        child: ElevatedButton(
          child: Text('Search Nearby Devices'),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => DeviceListScreen()));
          },
        ),
      ),
    );
  }
}
