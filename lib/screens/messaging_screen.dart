import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class MessagingScreen extends StatefulWidget {
  final BluetoothDevice device;

  MessagingScreen({required this.device});

  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  BluetoothCharacteristic? characteristic;
  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;
  TextEditingController messageController = TextEditingController();
  List<String> messages = [];

  @override
  void initState() {
    super.initState();
    _connectToDevice();
  }

  Future<void> _connectToDevice() async {
    try {
      await widget.device.connect(autoConnect: false);
      widget.device.state.listen((state) {
        setState(() {
          deviceState = state;
        });
        if (state == BluetoothDeviceState.connected) {
          _discoverServices(); // Discover services when connected
        }
      });
    } catch (e) {
      print('Error connecting to device: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to device: $e')),
      );
    }
  }

  Future<void> _discoverServices() async {
    if (deviceState == BluetoothDeviceState.connected) {
      try {
        List<BluetoothService> services = await widget.device.discoverServices();
        for (var service in services) {
          for (var char in service.characteristics) {
            if (char.properties.write && char.properties.notify) {
              setState(() {
                characteristic = char;
              });
              _listenToCharacteristic(); // Start listening to the characteristic
            }
          }
        }
      } catch (e) {
        print('Error discovering services: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error discovering services: $e')),
        );
      }
    } else {
      print("Device is not connected.");
    }
  }

  // Listen to incoming messages
  void _listenToCharacteristic() {
    if (characteristic != null) {
      characteristic!.value.listen((value) {
        String receivedMessage = String.fromCharCodes(value);
        setState(() {
          messages.add("Them: $receivedMessage");
        });
      });
      characteristic!.setNotifyValue(true); // Enable notifications to receive data
    }
  }

  // Send a message to the other device
  Future<void> _sendMessage(String message) async {
    if (characteristic != null) {
      try {
        await characteristic!.write(message.codeUnits); // Write message as bytes
        setState(() {
          messages.add("Me: $message"); // Show the message in the chat log
        });
      } catch (e) {
        print('Error sending message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with ${widget.device.name}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(messages[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      labelText: 'Enter message',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    String message = messageController.text;
                    if (message.isNotEmpty) {
                      _sendMessage(message); // Send the message
                      messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.device.disconnect().catchError((e) {
      print('Error disconnecting: $e'); // Log any disconnection error
    });
    super.dispose();
  }
}
