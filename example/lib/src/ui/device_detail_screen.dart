import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_reactive_ble_example/src/ble/ble_device_connector.dart';
import 'package:provider/provider.dart';

class DeviceDetailScreen extends StatelessWidget {
  final DiscoveredDevice device;

  const DeviceDetailScreen({@required this.device}) : assert(device != null);

  @override
  Widget build(BuildContext context) =>
      Consumer2<BleDeviceConnector, ConnectionStateUpdate>(
        builder: (_, deviceConnector, connectionStateUpdate, __) =>
            _DeviceDetail(
          device: device,
          connectionUpdate: connectionStateUpdate != null &&
                  connectionStateUpdate.deviceId == device.id
              ? connectionStateUpdate
              : ConnectionStateUpdate(
                  deviceId: device.id,
                  connectionState: DeviceConnectionState.disconnected,
                  failure: null,
                ),
          connect: deviceConnector.connect,
          disconnect: deviceConnector.disconnect,
          deviceConnector: deviceConnector,
        ),
      );
}

class _DeviceDetail extends StatelessWidget {
  const _DeviceDetail({
    @required this.device,
    @required this.connectionUpdate,
    @required this.connect,
    @required this.disconnect,
    this.deviceConnector,
    Key key,
  })  : assert(device != null),
        assert(connectionUpdate != null),
        assert(connect != null),
        assert(disconnect != null),
        super(key: key);
  final BleDeviceConnector deviceConnector;
  final DiscoveredDevice device;
  final ConnectionStateUpdate connectionUpdate;
  final void Function(String deviceId) connect;
  final void Function(String deviceId) disconnect;

  bool _deviceConnected() =>
      connectionUpdate.connectionState == DeviceConnectionState.connected;

  void _readCharacteristics() {
    deviceConnector.flutter_ble.subscribeToCharacteristic(QualifiedCharacteristic(
      deviceId: device.id,
      serviceId: Uuid.parse("0000fff0-0000-1000-8000-00805f9b34fb"),
      characteristicId: Uuid.parse("0000fff1-0000-1000-8000-00805f9b34fb"),
    )).listen((data) {
      var value = int.parse((data[1].toRadixString(16)+data[2].toRadixString(16)).toString(), radix: 16);
//      var value = double.parse((data[1].toRadixString(16)+data[2].toRadixString(16)).toString());
      // then div by 10 -> run C to F formula
      // trigger cam capture, timestamp
      print(value);

    });

  }

  @override
  Widget build(BuildContext context) {
    if (_deviceConnected()) {
      _readCharacteristics();
    }
    return WillPopScope(
      onWillPop: () async {
        disconnect(device.id);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(device.name ?? "unknown"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "ID: ${connectionUpdate.deviceId}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Status: ${connectionUpdate.connectionState}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              StreamBuilder<ConnectionStateUpdate>(
                  stream: deviceConnector.flutter_ble.connectedDeviceStream,
                  builder: (context, snapshot) {
                    return Container(
                      child: snapshot.data!=null?Text(snapshot.data.toString()):Container(),
                    );
                  }),
              StreamBuilder<CharacteristicValue>(
                  stream: deviceConnector.flutter_ble.characteristicValueStream,
                  builder: (context, snapshot) {
                    return Container(
                      child: snapshot.data!=null?Text(snapshot.data.toString()):Container(),
                    );
                  }),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RaisedButton(
                      onPressed:
                          !_deviceConnected() ? () => connect(device.id) : null,
                      child: const Text("Connect"),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RaisedButton(
                      onPressed: _deviceConnected()
                          ? () => disconnect(device.id)
                          : null,
                      child: const Text("Disconnect"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
