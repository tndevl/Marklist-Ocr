import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: FuncTest()));
}

class FuncTest extends StatefulWidget {
  _FuncTest createState() => _FuncTest();
}

class _FuncTest extends State<FuncTest> {
  var auth;
  var cred;

  @override
  void initState() {
    super.initState();
    //FirebaseAuth.instance.signInAnonymously().then((value) => cred = value);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          CircleAvatar(
            backgroundColor: Colors.white,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () async {
        var result = await FilePicker.platform
            .pickFiles(type: FileType.custom, allowedExtensions: ['']);
        print(result.files.single.path);
        /*FirebaseFunctions functions = FirebaseFunctions.instance;
        HttpsCallable callable = functions.httpsCallable('helloWorld');
        callable.call({"text": "llanfairlushwingogooch"}).then(
            (value) => print(value.data));*/
      }),
    );
  }
}
