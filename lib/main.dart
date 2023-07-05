import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:percent_indicator/percent_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(TemperatureMonitoringApp());
}

class TemperatureMonitoringApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Temperature Monitoring App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: TemperatureScreen(),
    );
  }
}

class TemperatureScreen extends StatefulWidget {
  @override
  _TemperatureScreenState createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen> {
  late DatabaseReference _databaseReference;
  String suhu = 'N/A';
  String kelembapan = 'N/A';
  bool isLedOn = false;
  bool isPumpOn = false;
  bool isMotionOn = false;
  String soilMoisture = 'N/A';

  bool isHighHumidityAlertShown = false;
  bool isRainDetectedAlertShown = false;

  @override
  void initState() {
    super.initState();
    _databaseReference = FirebaseDatabase.instance.ref().child('esiot-db');
    fetchData();
  }

  Future<void> fetchData() async {
    _databaseReference.onValue.listen((event) {
      DataSnapshot data = event.snapshot;
      Map<dynamic, dynamic>? values = data.value as Map<dynamic, dynamic>?;

      if (values != null) {
        setState(() {
          suhu = '${values['suhu']}°C';
          kelembapan = '${values['kelembapan']}%';
          soilMoisture = '${values['soil']}%';
          isLedOn = values['relay'] == 1;
          isPumpOn = values['relay'] == 1;
          isMotionOn = values['pir'] == 1;

          // Tampilkan alert hanya jika belum ditampilkan sebelumnya
          if (!isHighHumidityAlertShown &&
              double.parse(kelembapan.replaceAll('%', '')) > 80) {
            showHighHumidityAlert();
            isHighHumidityAlertShown =
                true; // Set variabel penanda menjadi true
          }

          // Tampilkan alert hanya jika belum ditampilkan sebelumnya
          // Tampilkan alert hanya jika belum ditampilkan sebelumnya
          if (!isRainDetectedAlertShown && values['rain'] == 1) {
            showRainDetectedAlert();
            isRainDetectedAlertShown =
                true; // Set variabel penanda menjadi true
          }

          if (isLedOn) {
            toggleLed(true); // Mengaktifkan water pump jika isLedOn = true
          } else if (!isLedOn) {
            toggleLed(false); // Mematikan water pump jika isLedOn = false
          }

          if (double.parse(soilMoisture.replaceAll('%', '')) <= 10) {
            togglePump(
                true); // Mengaktifkan water pump jika soil moisture < 20%
          }

          if (double.parse(soilMoisture.replaceAll('%', '')) >= 30) {
            togglePump(false); // Mematikan water pump jika soil moisture >= 20%
          }
        });
      }
    }, onError: (error) {
      print('Error: $error');
    });
  }

  Future<void> onRefresh() async {
    await fetchData();
  }

  void toggleLed(bool isTurnOn) {
    setState(() {
      isLedOn = isTurnOn;
    });

    int newLedValue = isTurnOn ? 1 : 0;
    _databaseReference.update({'relay': newLedValue}).catchError((error) {
      print('Error: $error');
    });
  }

  void toggleMotion(bool isTurnOn) {
    setState(() {
      isMotionOn = isTurnOn;
    });

    int newMotionValue = isTurnOn ? 1 : 0;
    _databaseReference.update({'pir': newMotionValue}).catchError((error) {
      print('Error: $error');
    });
  }

  void togglePump(bool isTurnOn) {
    setState(() {
      isPumpOn = isTurnOn;
    });

    int newLedValue = isTurnOn ? 1 : 0;
    _databaseReference.update({'relay': newLedValue}).catchError((error) {
      print('Error: $error');
    });
  }

  void showHighHumidityAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('High Humidity'),
          content: Text('PANAS BANGET NICH.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    ).then((value) {
      // Set variabel penanda menjadi false saat alert ditutup
      isHighHumidityAlertShown = false;
    });
  }

  void showRainDetectedAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rain Detected'),
          content: Text('HUJAN WOIII.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    ).then((value) {
      // Set variabel penanda menjadi false saat alert ditutup
      isRainDetectedAlertShown = false;
    });
  }

  double parseTemperature(String temperature) {
    try {
      return double.parse(temperature.replaceAll('°C', ''));
    } catch (e) {
      return 0.0; // Mengembalikan nilai default 0.0 jika data tidak tersedia
    }
  }

  double parseHumidity(String humidity) {
    try {
      return double.parse(humidity.replaceAll('%', ''));
    } catch (e) {
      return 0.0; // Mengembalikan nilai default 0.0 jika data tidak tersedia
    }
  }

  double parseSoil(String soilMoisture) {
    try {
      return double.parse(soilMoisture.replaceAll('%', ''));
    } catch (e) {
      return 0.0; // Mengembalikan nilai default 0.0 jika data tidak tersedia
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Smart System Monitoring",
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Temperature',
                            style: TextStyle(fontSize: 25),
                          ),
                          SizedBox(height: 20),
                          CircularPercentIndicator(
                            radius: 150.0,
                            lineWidth: 15.0,
                            circularStrokeCap: CircularStrokeCap.round,
                            progressColor: Colors.red,
                            percent: parseTemperature(suhu) / 100,
                            center: Text(
                              '$suhu',
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 20),
                      Column(
                        children: [
                          Text(
                            'Humidity',
                            style: TextStyle(fontSize: 25),
                          ),
                          SizedBox(height: 20),
                          CircularPercentIndicator(
                            radius: 150.0,
                            lineWidth: 15.0,
                            circularStrokeCap: CircularStrokeCap.round,
                            progressColor: Colors.blue,
                            percent: parseHumidity(kelembapan) / 100,
                            center: Text(
                              '$kelembapan',
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Soil Moisture',
                            style: TextStyle(fontSize: 25),
                          ),
                        ],
                      ),
                      SizedBox(width: 0),
                      Column(
                        children: [
                          Text(
                            'WaterPump: ${isLedOn ? 'On' : 'Off'}',
                            style: TextStyle(fontSize: 25),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          SizedBox(height: 20),
                          CircularPercentIndicator(
                            radius: 150.0,
                            lineWidth: 15.0,
                            circularStrokeCap: CircularStrokeCap.round,
                            progressColor: Colors.orange,
                            percent: parseSoil(soilMoisture) / 100,
                            center: Text(
                              '$soilMoisture',
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 100,
                      ),
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              toggleLed(isLedOn ? false : true);
                            },
                            child: Text(
                              isLedOn ? 'Turn Off Pump' : 'Turn On Pump',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      fetchData();
                    },
                    child: Text(
                      'Refresh',
                    ),
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  Column(
                    children: [
                      Text(
                        'Motion Detector: ${isMotionOn ? 'On' : 'Off'}',
                        style: TextStyle(fontSize: 25),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          toggleMotion(isMotionOn ? false : true);
                        },
                        child: Text(isMotionOn ? 'Turn Off' : 'Turn On'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
