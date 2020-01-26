import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:esense_flutter/esense.dart';

void main() {
  runApp(DiceRollingApp());
}

class DiceRollingApp extends StatefulWidget {
  @override
  _DiceRollingAppState createState() => _DiceRollingAppState();
}

class _DiceRollingAppState extends State<DiceRollingApp> {
  String _deviceName = 'Unknown';
  double _voltage = -1;
  String _deviceStatus = '';
  bool sampling = false;
  String _event = '';
  DateTime lastImageUpdate = new DateTime(2000);
  int changedPicture = 0;
  Image img;
  String _button = '';
  bool deviceConnected = false;
  bool playing = false;

  // the name of the eSense device to connect to -- change this to your own device.
  String eSenseName = 'eSense-0058';

//  @override
//  void initState() {
//    super.initState();
//    _connectToESense();
//  }
//
//  Future<void> _connectToESense() async {
//    bool con = false;
//
//    // if you want to get the connection events when connecting, set up the listener BEFORE connecting...
//    ESenseManager.connectionEvents.listen((event) {
//      print('CONNECTION event: $event');
//
//      // when we're connected to the eSense device, we can start listening to events from it
//      if (event.type == ConnectionType.connected) _listenToESenseEvents();
//
//      setState(() {
//        switch (event.type) {
//          case ConnectionType.connected:
//            _deviceStatus = 'connected';
//            break;
//          case ConnectionType.unknown:
//            _deviceStatus = 'unknown';
//            break;
//          case ConnectionType.disconnected:
//            _deviceStatus = 'disconnected';
//            break;
//          case ConnectionType.device_found:
//            _deviceStatus = 'device_found';
//            break;
//          case ConnectionType.device_not_found:
//            _deviceStatus = 'device_not_found';
//            break;
//        }
//      });
//    });
//
//    con = await ESenseManager.connect(eSenseName);
//
//    setState(() {
//      _deviceStatus = con ? 'connecting' : 'connection failed';
//    });
//  }
//
//  void _listenToESenseEvents() async {
//    ESenseManager.eSenseEvents.listen((event) {
//      print('ESENSE event: $event');
//
//      setState(() {
//        switch (event.runtimeType) {
//          case DeviceNameRead:
//            _deviceName = (event as DeviceNameRead).deviceName;
//            break;
//          case BatteryRead:
//            _voltage = (event as BatteryRead).voltage;
//            break;
//          case ButtonEventChanged:
//            _button = (event as ButtonEventChanged).pressed ? 'pressed' : 'not pressed';
//            break;
//          case AccelerometerOffsetRead:
//          // TODO
//            break;
//          case AdvertisementAndConnectionIntervalRead:
//          // TODO
//            break;
//          case SensorConfigRead:
//          // TODO
//            break;
//        }
//      });
//    });
//
//    _getESenseProperties();
//  }
//
//  void _getESenseProperties() async {
//    // get the battery level every 10 secs
//    Timer.periodic(Duration(seconds: 10), (timer) async => await ESenseManager.getBatteryVoltage());
//
//    // wait 2, 3, 4, 5, ... secs before getting the name, offset, etc.
//    // it seems like the eSense BTLE interface does NOT like to get called
//    // several times in a row -- hence, delays are added in the following calls
//    Timer(Duration(seconds: 2), () async => await ESenseManager.getDeviceName());
//    Timer(Duration(seconds: 3), () async => await ESenseManager.getAccelerometerOffset());
//    Timer(Duration(seconds: 4), () async => await ESenseManager.getAdvertisementAndConnectionInterval());
//    Timer(Duration(seconds: 5), () async => await ESenseManager.getSensorConfig());
//  }
//
//  StreamSubscription subscription;
//  void _startListenToSensorEvents() async {
//    // subscribe to sensor event from the eSense device
//    subscription = ESenseManager.sensorEvents.listen((event) {
//      print('SENSOR event: $event');
//      setState(() {
//        _event = event.toString();
//      });
//    });
//    setState(() {
//      sampling = true;
//    });
//  }
//
//  void _pauseListenToSensorEvents() async {
//    subscription.cancel();
//    setState(() {
//      sampling = false;
//    });
//  }
//
//  void dispose() {
//    _pauseListenToSensorEvents();
//    ESenseManager.disconnect();
//    super.dispose();
//  }




  var newDiceImage = Image.asset('assets/dice_images/1.png');
  var newDice2Image = Image.asset('assets/dice_images/1.png');

  int oldDiceFace = 1;
  int oldDice2Face = 1;

  int newDiceFace = 1;
  int newDice2Face = 1;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          backgroundColor: Colors.greenAccent,
          appBar: AppBar(
            elevation: 10.0,
            backgroundColor: Colors.teal,
            title: Center(child: Text('Dice Rolling App')),
          ),
          body: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: newDiceImage,
                              //child: nextDiceImage = Image.asset('assets/dice_images/$nextDiceFace.png'),
                            )
                        ),
                    Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: newDice2Image,
                              //Image.asset('assets/dice_images/$nextDice2Image.png'),
                            )
                        )
                  ],
                ),

                Expanded(

                  child: GestureDetector(onPanUpdate: (details) {
                    if (details.delta.dx < -5) {
                      print('left');

                      oldDiceFace = newDiceFace;
                      newDiceFace = Random().nextInt(6) + 1;
                      print('oldDiceFace: ' + oldDiceFace.toString() + ' nextDiceFace: ' + newDiceFace.toString());

                      setState(() {

                        newDiceImage = Image.asset('assets/dice_images/roll.gif');
                        Future.delayed(Duration(milliseconds: 500)).then((_) {
                          setState(() {
                            newDiceImage = Image.asset('assets/dice_images/$newDiceFace.png');
                          }); // second function
                        });





                            //Image(image: new AssetImage('assets/dice_images/roll.gif'));
                        //sleep(const Duration(milliseconds:300));
                        //nextDiceImage = Image.asset('assets/dice_images/$nextDiceFace.png');
                      });
                    } else if (details.delta.dx > 5) {
                      print('right');

                      oldDice2Face = newDice2Face;
                      newDice2Face = Random().nextInt(6) + 1;
                      print('oldDice2Face: ' + oldDice2Face.toString() + ' nextDice2Face: ' + newDice2Face.toString());
                      setState(() {
                        newDice2Image = Image.asset('assets/dice_images/roll.gif');
                        Future.delayed(Duration(milliseconds: 500)).then((_) {
                          setState(() {
                            newDice2Image = Image.asset('assets/dice_images/$newDice2Face.png');
                          }); // second function
                        });
                        //sleep(const Duration(milliseconds:300));
                        //nextDice2Image = Image.asset('assets/dice_images/$nextDice2Face.png');
                      });
                    }
                  }),
                ),

//              IconButton(
//                onPressed: (!ESenseManager.connected)
//                    ? null
//                    : (!sampling)
//                    ? _startListenToSensorEvents
//                    : _pauseListenToSensorEvents,
//                icon: (!sampling) ? Icon(Icons.play_arrow) : Icon(Icons.pause),
//                iconSize: 80,
//                color: Colors.blueGrey[900],
//              ),
              ],
            ),
          )),
    );
  }

//  Widget build(BuildContext context) {
//    return MaterialApp(
//      home: Scaffold(
//        appBar: AppBar(
//          title: const Text('eSense Demo App'),
//        ),
//        body: Align(
//          alignment: Alignment.topLeft,
//          child: ListView(
//            children: [
//              Text('eSense Device Status: \t$_deviceStatus'),
//              Text('eSense Device Name: \t$_deviceName'),
//              Text('eSense Battery Level: \t$_voltage'),
//              Text('eSense Button Event: \t$_button'),
//              Text(''),
//              Text('$_event'),
//            ],
//          ),
//        ),
//        floatingActionButton: new FloatingActionButton(
//          // a floating button that starts/stops listening to sensor events.
//          // is disabled until we're connected to the device.
//          onPressed:
//          (!ESenseManager.connected) ? null : (!sampling) ? _startListenToSensorEvents : _pauseListenToSensorEvents,
//          tooltip: 'Listen to eSense sensors',
//          child: (!sampling) ? Icon(Icons.play_arrow) : Icon(Icons.pause),
//        ),
//      ),
//    );
//  }
}
