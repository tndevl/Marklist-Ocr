import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marklist_ocr/widgets.dart';
import 'filecontrol.dart';
import 'scanner.dart';
import 'widgets.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

class Result extends StatefulWidget {
  @override
  _ResultState createState() => _ResultState();
}

class _ResultState extends State<Result> with WidgetsBindingObserver {
  void save() async {
    Bob().save();
  }

  List<String> title = Bob().titles;
  List<Map> data = [];
  bool started = false;
  bool received = false;
  @override
  Widget build(BuildContext context) {
    var connection = Provider.of<ConnectivityResult>(context);
    var currency = Provider.of<Coins>(context, listen: false).money;
    if (started && connection != ConnectivityResult.none) {
      scan(bucket: 'testocr-1100.appspot.com').then((val) {
        setState(() {
          data = val.data;
          received = true;
        });
        FirebaseDatabase.instance
            .reference()
            .child('users/' + FirebaseAuth.instance.currentUser.uid + '/scans')
            .set(currency - 1);
      });
      if (received) {
        return Scaffold(
          appBar: UniBar('Results:'),
          body: SingleChildScrollView(
              child: DataTable(
            columns: List<DataColumn>.generate(title.length, (index) {
              var column = DataColumn(label: Text(title[index]));
              return column;
            }),
            rows: List<DataRow>.generate(
                data.length,
                (index) => DataRow(
                        cells: List.generate(title.length, (i) {
                      return data[index][title[i]];
                    }))),
          )),
        );
      } else {
        return Scaffold(
          appBar: UniBar('Wait'),
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
    } else {
      return Scaffold(
        appBar: UniBar('Get Results or Save for Later'),
        body: Center(
            child: connection == ConnectivityResult.none
                ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Icon(Icons.signal_wifi_off),
                    Text('No connection')
                  ])
                : Container()),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            children: [
              BottomButton(save, 'Save For Later', Icon(Icons.add_box_rounded)),
              Spacer(),
              BottomButton(() {
                print(currency);
                if (currency > 0) {
                  setState(() {
                    started = true;
                  });
                } else {
                  showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (_) => AlertDialog(
                              title: Text('Out of scans'),
                              content: Text('Purchase more to continue'),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text('No')),
                                TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, 'Store');
                                    },
                                    child: Text('Yes'))
                              ]));
                }
              }, 'Scan', Icon(Icons.crop_free_rounded))
            ],
          ),
        ),
      );
    }
  }
}
