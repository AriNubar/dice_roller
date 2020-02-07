import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:esense_flutter/esense.dart';
import 'dart:math';

///
/// Entry Point of the Program
///
void main() => runApp(MainApp());


///
/// Introduces MaterialLocalizations
/// Needed for the AlertView --> https://stackoverflow.com/questions/54035175/flutter-showdialog-alertdialog-no-materiallocalizations-found
///
class MainApp extends StatelessWidget {
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dice Roller',
      home: DiceApp(),
    );
  }
}

///
/// Parent Widget
///
class DiceApp extends StatefulWidget {
  @override
  _DiceAppState createState() => _DiceAppState();
}

///
/// State of the Parent Widget
///
class _DiceAppState extends State<DiceApp> {
  String _deviceName = 'Unknown';
  double _voltage = -1;
  String _deviceStatus = '';
  bool sampling = false;
  String _event = '';

  // the name of the eSense device to connect to -- change this to your own device.
  String eSenseName = 'eSense-0058';
  String _button = '';
  bool deviceConnected = false;
  bool playing = false;

  bool _rollMode = false;
  bool _swiped = false;

  var newDiceImage = Image.asset('assets/dice_images/1.png');
  var newDice2Image = Image.asset('assets/dice_images/1.png');

  int oldDiceFace;
  int oldDice2Face;

  int newDiceFace = 1;
  int newDice2Face = 1;

  var oldGyroX = 0.0;
  var oldGyroY = 0.0;
  var oldGyroZ = 0.0;

  ///
  // / Initializes the State of the app at the start
  ///
  @override
  void initState() {
    super.initState();
    _connectToESense();
  }

  ///f
  /// Method which connects to the ESense Device and
  /// starts the process of listening to Events coming from the device
  Future<void> _connectToESense() async {
    bool con = false;

    // if you want to get the connection events when connecting, set up the listener BEFORE connecting...
    ESenseManager.connectionEvents.listen((event) {
      //print('CONNECTION event: $event');

      // when we're connected to the eSense device, we can start listening to events from it
      if (event.type == ConnectionType.connected) {
        _listenToESenseEvents();
        deviceConnected = true;
      }

      setState(() {
        switch (event.type) {
          case ConnectionType.connected:
            _deviceStatus = 'connected';
            deviceConnected = true;
            break;
          case ConnectionType.unknown:
            _deviceStatus = 'unknown';
            deviceConnected = false;
            break;

          case ConnectionType.disconnected:
            _deviceStatus = 'disconnected';
            deviceConnected = false;
            break;

          case ConnectionType.device_found:
            _deviceStatus = 'device_found';
            break;

          case ConnectionType.device_not_found:
            _deviceStatus = 'device_not_found';
            deviceConnected = false;

            break;
        }
      });
    });

    con = await ESenseManager.connect(eSenseName);

    setState(() {
      print(con);
      _deviceStatus = con ? 'connecting' : 'connection failed';

      print(con);
    });
  }

  ///
  /// This method reads out all events from the connected ESense device
  ///
  void _listenToESenseEvents() async {
    ESenseManager.eSenseEvents.listen((event) {
      //print('ESENSE event: $event');

      setState(() {
        switch (event.runtimeType) {
          case DeviceNameRead:
            _deviceName = (event as DeviceNameRead).deviceName;
            break;
          case BatteryRead:
            _voltage = (event as BatteryRead).voltage;
            break;
          case ButtonEventChanged:
            _button = (event as ButtonEventChanged).pressed
                ? 'pressed'
                : 'not pressed';
            break;

            // don't use these
          case AccelerometerOffsetRead:
            break;
          case AdvertisementAndConnectionIntervalRead:
            break;
          case SensorConfigRead:
            break;
        }
      });
    });

    _getESenseProperties();
  }

  ///
  /// method reads out all the Properties from the Esense device
  ///
  void _getESenseProperties() async {
    // get the battery level every 10 secs
    Timer.periodic(Duration(seconds: 10),
            (timer) async => await ESenseManager.getBatteryVoltage());

    // wait 2, 3, 4, 5, ... secs before getting the name, offset, etc.
    // it seems like the eSense BTLE interface does NOT like to get called
    // several times in a row -- hence, delays are added in the following calls
    Timer(
        Duration(seconds: 2), () async => await ESenseManager.getDeviceName());
    Timer(Duration(seconds: 3),
            () async => await ESenseManager.getAccelerometerOffset());
    Timer(
        Duration(seconds: 4),
            () async =>
        await ESenseManager.getAdvertisementAndConnectionInterval());
    Timer(Duration(seconds: 5),
            () async => await ESenseManager.getSensorConfig());
  }


  StreamSubscription subscription;

  ///
  /// Method to continuously read the data from the ESense device
  /// Interprets the gyro data to find out in which direction the head was moving
  ///
  void _startListenToSensorEvents() async {
    // subscribe to sensor event from the eSense device
    subscription = ESenseManager.sensorEvents.listen((event) {
      //print('SENSOR event: $event');
      setState(() {
        _event = event.toString();

        var accX = event.accel[0] / 16384.0;
        var accY = event.accel[1] / 16384.0;
        var accZ = event.accel[2] / 16384.0;

        var accAngleX = (atan(accY / sqrt(pow(accX, 2) + pow(accZ, 2))) * 180 / pi); // accError;
        var accAngleY = (atan(-1 * accX / sqrt(pow(accY, 2) + pow(accZ, 2))) * 180 * pi);



        var gyroX = event.gyro[0] / 131.0;
        var gyroY = event.gyro[1] / 131.0;
        var gyroZ = event.gyro[2] / 131.0;


        var previousTime = new DateTime.now().millisecondsSinceEpoch;
        var currentTime = new DateTime.now().millisecondsSinceEpoch;
        var eplasedTime = (currentTime - previousTime) / 1000;

        var gyroAngleX = gyroX * eplasedTime;
        var gyroAngleY = gyroY * eplasedTime;
        var gyroAngleZ = gyroZ * eplasedTime;

        // var yaw = gyroZ * eplasedTime;

        //var roll = 0.96 * gyroAngleX + 0.04 * accAngleX;
        var pitch = 0.96 * gyroAngleY + 0.04 * accAngleY;
        //var yaw = 0.96 * gyroAngleZ + 0.04 * accAngleZ;


        var accDiffX = ((oldGyroX - gyroX) / gyroX);
        var accDiffY = ((oldGyroX - gyroY) / gyroY);
        var accDiffZ = ((oldGyroX - gyroZ) / gyroZ);

        if (_rollMode) {

          if ((accDiffX.abs() >= 0.7) && (accDiffY.abs() >= 0.7) && (accDiffZ.abs() >= 0.7)){
              _roll("both");
              oldGyroX = gyroX;
          }
        }
        else if(_button == 'not pressed'){
          if (pitch <= 18) {
            _roll("up");
          }
          else if(pitch >= 26){
            _roll("down");
          }
        } else { // pressed
          _roll("both");
        }
      });
    });

    setState(() {
      sampling = true;
    });
  }


  ///
  /// Method for changing the face of a dice and printing it onto the screen.
  ///
  void _roll(String which){
    switch (which){
      case "up":
        oldDiceFace = newDiceFace;
        oldDice2Face = newDice2Face;
        newDiceFace = Random().nextInt(6) + 1;

        setState(() {
          newDiceImage = Image.asset('assets/dice_images/roll.gif');
          Future.delayed(Duration(milliseconds: 500)).then((_) {
            setState(() {
              newDiceImage = Image.asset('assets/dice_images/$newDiceFace.png');
            }); // second function
          });
        });
        break;
      case "down":
        oldDiceFace = newDiceFace;
        oldDice2Face = newDice2Face;
        newDice2Face = Random().nextInt(6) + 1;
        setState(() {
          newDice2Image = Image.asset('assets/dice_images/roll.gif');
          Future.delayed(Duration(milliseconds: 500)).then((_) {
            setState(() {
              newDice2Image = Image.asset('assets/dice_images/$newDice2Face.png');
            }); // second function
          });
        });
        break;
      case "both":
        oldDiceFace = newDiceFace;
        newDiceFace = Random().nextInt(6) + 1;

        oldDice2Face = newDice2Face;
        newDice2Face = Random().nextInt(6) + 1;

        setState(() {
          newDiceImage = Image.asset('assets/dice_images/roll.gif');
          newDice2Image = Image.asset('assets/dice_images/roll.gif');
          Future.delayed(Duration(milliseconds: 500)).then((_) {
            setState(() {
              newDiceImage = Image.asset('assets/dice_images/$newDiceFace.png');
              newDice2Image = Image.asset('assets/dice_images/$newDice2Face.png');
            }); // second function
          });
        });
        break;
    }

  }


  ///
  /// pauses the continuously data reading
  ///
  void _pauseListenToSensorEvents() async {
    subscription.cancel();
    setState(() {
      sampling = false;
    });
  }

  ///
  /// disconnects the device
  ///
  void dispose() {
    _pauseListenToSensorEvents();
    ESenseManager.disconnect();
    super.dispose();
  }

  ///FUNCTIONS
  ///-------------------------------------------------------------------------
  ///VIEWS


  ///
  /// Builds the app layout
  ///
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: myAppBar(),
          backgroundColor: Colors.greenAccent,
          body: myColumn(),
          bottomNavigationBar: myBottomBar(),
        )
    );
  }


  ///
  /// Builds the AppBar of the app
  Widget myAppBar() {
    return AppBar(
      backgroundColor: Colors.teal,
      title: Text('Dice Roller'),
      actions: <Widget>[bluetoothStatus()],
    );
  }


  /// Creates the bluetooth icon with
  /// the bluetooth settings
  ///
  Widget bluetoothStatus() {
    return IconButton(
      icon: deviceConnected
          ? Icon(
        Icons.bluetooth_connected,
        color: Colors.green,
      )
          : Icon(
        Icons.bluetooth,
        color: Colors.white,
      ),
      onPressed: () {
        showBluetoothConnection();
      },
    );
  }


// Wrapped with Gesture Detector
  Widget myColumn() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanUpdate: (details) {
        if (!_swiped) {

          if (details.delta.dx < -15) {
            _swiped = true;

            oldDiceFace = newDiceFace;
            oldDice2Face = newDice2Face;
            newDiceFace = Random().nextInt(6) + 1;
            setState(() {
              newDiceImage = Image.asset('assets/dice_images/roll.gif');
              Future.delayed(Duration(milliseconds: 500)).then((_) {
                setState(() {
                  newDiceImage =
                      Image.asset('assets/dice_images/$newDiceFace.png');
                  _swiped = false;
                }); // second function
              });
            });
          } else if (details.delta.dx > 15) {
            _swiped = true;
            oldDiceFace = newDiceFace;
            oldDice2Face = newDice2Face;
            newDice2Face = Random().nextInt(6) + 1;

            setState(() {
              newDice2Image = Image.asset('assets/dice_images/roll.gif');
              Future.delayed(Duration(milliseconds: 500)).then((_) {
                setState(() {
                  newDice2Image =
                      Image.asset('assets/dice_images/$newDice2Face.png');
                  _swiped = false;
                }); // second function
              });
            });
          } else if (details.delta.dy > 10) {
            _swiped = true;
            oldDiceFace = newDiceFace;
            oldDice2Face = newDice2Face;
            newDiceFace = Random().nextInt(6) + 1;
            newDice2Face = Random().nextInt(6) + 1;

            setState(() {
              newDiceImage = Image.asset('assets/dice_images/roll.gif');
              newDice2Image = Image.asset('assets/dice_images/roll.gif');
              Future.delayed(Duration(milliseconds: 500)).then((_) {
                setState(() {
                  newDiceImage =
                      Image.asset('assets/dice_images/$newDiceFace.png');
                  newDice2Image =
                      Image.asset('assets/dice_images/$newDice2Face.png');
                  _swiped = false;
                }); // second function
              });
            });
          } else {
            Future.delayed(Duration(milliseconds: 500)).then((_) {
              setState(() {
                _swiped = false;
              }); // second function
            });
          }
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[

          Container(
            margin: const EdgeInsets.only(top: 25.0),
          ),


          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(deviceConnected ?
            sampling ? _rollMode ? "Roll your earable" : 'Heads Up / Down' : 'Press the Play Icon'
                : 'Connect Your Earables',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
          ),


          Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: newDiceImage,
              )
          ),
          Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: newDice2Image,
              )
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                onPressed: (!ESenseManager.connected)
                    ? null
                    : (!sampling)
                    ? _startListenToSensorEvents
                    : _pauseListenToSensorEvents,
                icon: (!sampling) ? Icon(Icons.play_arrow) : Icon(Icons.pause),
                iconSize: 70,
                color: Colors.blueGrey[900],
              ),
              IconButton(
                onPressed: (!ESenseManager.connected)
                    ? null
                    : (!sampling)
                    ? null
                    : () => _rollMode = !_rollMode,
                icon: (sampling && _rollMode) ? Icon(Icons.grid_on) : Icon(Icons.grid_off) ,
                iconSize: 70,
                color: Colors.blueGrey[900],
              ),
            ],
          )


        ],
      ),
    );
  }


  ///
  /// Build the BottomBar of the app
  ///
  Widget myBottomBar() {
    return BottomAppBar(
        color: Colors.green[900],
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Last Roll: ',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              Container(
                  width: 20,
                  child: oldDiceFace == null ?  Text("") : Image.asset("assets/dice_images/$oldDiceFace.png")
              ),
              Container(
                  width: 20,
                  child: oldDice2Face == null ?  Text("") : Image.asset("assets/dice_images/$oldDice2Face.png")
              )

            ],
          ),


        ));
  }

  ///
  /// creates the alerts that displays
  /// the bluetooth connection details
  ///
  void showBluetoothConnection() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text('Connection status'),
          content: new Container(
            height: 230,
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: new ListView(
                    children: <Widget>[
                      new ListTile(
                        title: new Text(
                            deviceConnected ? 'Connected to $_deviceName' : 'No device connected.'),
                      ),

                      Divider(),

                      Center(
                        child: Text(
                          'How to connect:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      Text(
                        '\n1. Check if bluetooth is turned on your device.\n\n'
                            '2. Hold down the button on both earplugs until they blink blue and red.\n\n'
                            '3. Press Connect.',

                        textAlign: TextAlign.left,
                        style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 12.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
                onPressed: () {
                  if (deviceConnected) {
                    Navigator.of(context).pop();
                  } else {
                    _connectToESense();
                    Navigator.of(context).pop();
                  }
                },
                child: Text(deviceConnected ? 'Close' : 'Connect'))
          ],
        );
      },
    );
  }
}




