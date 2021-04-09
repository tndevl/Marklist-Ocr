import 'package:camera/camera.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:marklist_ocr/result.dart';
import 'package:marklist_ocr/widgets.dart';
import 'package:provider/provider.dart';
import 'template.dart';
import 'datafile.dart';
import 'filecontrol.dart';
import 'allow.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile.dart';
import 'store.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

List<CameraDescription> cameras;
main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var connectivityResult = await (Connectivity().checkConnectivity());

  InAppPurchaseConnection.enablePendingPurchases();
  cameras = await availableCameras();
  Bob().cameras = cameras;
  await Firebase.initializeApp();
  Wallet().create();
  runApp(MultiProvider(
      providers: [
        StreamProvider<User>.value(
          value: FirebaseAuth.instance.authStateChanges(),
        ),
        StreamProvider<Coins>.value(
          value: Wallet().real(),
          initialData: Coins.load(0),
        ),
        StreamProvider<ConnectivityResult>.value(
          value: Connectivity().onConnectivityChanged,
          initialData: connectivityResult,
        )
      ],
      child: MaterialApp(
        initialRoute: 'Home',
        routes: {
          'Home': (context) => Home(),
          'Profile': (context) => Profile(),
          'Store': (context) => Store(),
          'Template': (context) => PageViewer(),
          'Data': (context) => CamView(),
          'Result': (context) => Result(),
        },
      )));
}

class Home extends StatefulWidget with WidgetsBindingObserver {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var connection = Provider.of<ConnectivityResult>(context);
    if (connection != ConnectivityResult.none) {
      Allow().start();
    }
    return Scaffold(
      appBar: UniBar('Welcome'),
      body: Center(
        child: connection == ConnectivityResult.none
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [Icon(Icons.signal_wifi_off), Text('No connection')],
              )
            : Text('Welcome to Marklist Ocr'),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () async {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => PageViewer()));
      }),
    );
  }
}
