import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:io';
import 'dart:async';
import 'filecontrol.dart';

Future<HttpsCallableResult> scan({String bucket}) async {
  var outcome;
  Reference storageReference =
      FirebaseStorage.instanceFor(bucket: bucket).ref().child(Bob().name);

  UploadTask uploadTask = storageReference.putFile(File(Bob().file));
  final StreamSubscription<TaskSnapshot> streamSubscription =
      uploadTask.snapshotEvents.listen(
    (event) {
      print(event);
    },
    onError: (error) {
      print(error.toString());
    },
    cancelOnError: false,
  );
  await uploadTask;
  streamSubscription.cancel();

  Map<String, dynamic> body = {'file': Bob().name, "bounds": Bob().bounds};
  HttpsCallable func = FirebaseFunctions.instance.httpsCallable('scanner');
  await func.call(body).then((value) => outcome = value);

  return outcome;
}
