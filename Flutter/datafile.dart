import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:marklist_ocr/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'filecontrol.dart';
import 'result.dart';

class CamView extends StatefulWidget {
  CamView({
    Key key,
  }) : super(key: key);
  @override
  CamViewState createState() => CamViewState();
}

class CamViewState extends State<CamView> with WidgetsBindingObserver {
  CameraController controller;
  int counter = 0;
  Bob worker = Bob();

  @override
  void initState() {
    super.initState();
    controller = CameraController(Bob().cameras[0], ResolutionPreset.high);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void choose() async {
    var filepicker = FileRoute();
    filepicker.pickImage().then((value) {
      worker.addimg(value);
    });
    counter++;
  }

  void cheese() async {
    if (!controller.value.isTakingPicture) {
      var dir = await getTemporaryDirectory();
      var place = dir.path + "/" + DateTime.now().toString();

      controller.takePicture(place).then((value) async {
        worker
            .addimg(
          place,
        )
            .then((_) {
          counter++;
        });
      });
    } else {
      return;
    }
  }

  void create() async {
    Bob().create();
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Result(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Scaffold(
        appBar: UniBar('Take Pictures'),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
            child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: CameraPreview(controller),
        )),
        floatingActionButton: FloatingActionButton(
          onPressed: cheese,
          heroTag: 'out',
          child: Icon(Icons.camera_alt),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
            notchMargin: 4.0,
            shape: const CircularNotchedRectangle(),
            child: Row(
              children: [
                Flexible(
                    child: FlatButton(
                  onPressed: choose,
                  color: Colors.blue.shade100,
                  child: Text('Gallery'),
                )),
                Flexible(
                    child: FloatingActionButton(
                  onPressed: create,
                  child: Icon(Icons.check),
                  heroTag: 'south',
                )),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
            )),
      );
    }
  }
}
