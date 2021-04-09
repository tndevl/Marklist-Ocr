import 'dart:io';

import 'package:marklist_ocr/widgets.dart';
import 'package:flutter/material.dart';
import 'filecontrol.dart';
import 'datafile.dart';
import 'widgets.dart' as widgets;

class PageViewer extends StatefulWidget {
  @override
  PageViewerState createState() => PageViewerState();
}

class PageViewerState extends State<PageViewer> with WidgetsBindingObserver {
  String file;
  int index = 0;
  Bob bob = Bob();
  int loaded = 0;
  List<Widget> selectors = [];
  bool selected = false;
  int documentLength = 0;

  @override
  initState() {
    super.initState();
    var pick = FileRoute();
    pick.pickFile().then((value) {
      Bob().setorgin(value).then((value) {
        setState(() {
          documentLength = value;
        });
        Bob().decode().listen((event) {
          setState(() {
            loaded = event;
          });
        }, onDone: () {});
      });
    });
  }

  selectPage() {
    bob.addpdf(index);
    setState(() {
      selected = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        appBar: UniBar('Select Template File'),
        body: Stack(children: [
          PageView.builder(
              controller:
                  PageController(initialPage: 1, viewportFraction: 0.45),
              onPageChanged: (v) {
                index = v;
              },
              scrollDirection: Axis.horizontal,
              itemCount: documentLength,
              itemBuilder: (context, i) {
                if (i <= loaded) {
                  return Image.file(File(Bob().tempdir.path +
                      '/pdfImages' +
                      i.toString() +
                      '.jpg'));
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              })
        ]),
        floatingActionButton: FloatingActionButton(
          onPressed: selectPage,
          child: Icon(Icons.check),
          heroTag: 'mob',
        ),
      );
    } else {
      return Scaffold(
        appBar: UniBar('Select Text Zones'),
        body: Stack(
          children: [
            Image.file(File(
                Bob().tempdir.path + '/pdfImages' + index.toString() + '.jpg')),
            Column(
              children: selectors,
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            selectors.add(widgets.Selector());
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              BottomButton(() {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => CamView()));
              }, 'Select Photos for Scanning', Icon(Icons.arrow_forward_ios)),
            ],
          ),
        ),
      );
    }
  }
}
