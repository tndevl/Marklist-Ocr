import 'dart:typed_data';
import 'dart:math';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:native_pdf_renderer/native_pdf_renderer.dart' as ipdf;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class FileRoute {
  final picker = ImagePicker();
  File file;

  Future<String> pickImage() async {
    String path;
    var file = await picker.getImage(source: ImageSource.gallery);
    path = file.path;
    print(path);
    return path;
  }

  Future<String> pickFile() async {
    String path;
    FilePickerResult result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

    if (result != null) {
      file = File(result.files.single.path);
    } else {}
    path = file.path;
    print(path);
    return path;
  }

  retrieve(String image) async {
    var path;
    LostData data = await picker.getLostData();
    if (data.isEmpty != true) {
      path = data.file.path;
      return path;
    }
  }
}

class Bob {
  List bounds = [];
  String origin;
  List pdfImages = [];
  List<String> titles = [];
  final pdf = pw.Document();
  String file;
  Bob._internal();
  String name;
  String dir;
  List<CameraDescription> cameras;
  Directory tempdir;
  setorgin(String str) async {
    origin = str;
    sleep(Duration(seconds: 1));
    ipdf.PdfDocument document = await ipdf.PdfDocument.openFile(origin);
    tempdir = await getTemporaryDirectory();
    return document.pagesCount;
  }

  static final Bob _singleton = Bob._internal();

  factory Bob() {
    return _singleton;
  }
  Stream<int> decode() async* {
    Directory tempstore = await getTemporaryDirectory();
    final fil = origin;
    ipdf.PdfDocument document = await ipdf.PdfDocument.openFile(fil);
    for (var i = 1; i <= document.pagesCount; i++) {
      var page = await document.getPage(i);
      Uint8List byte;
      await page
          .render(
              width: page.width,
              height: page.height,
              format: ipdf.PdfPageFormat.JPEG)
          .then((value) async {
        byte = await FlutterImageCompress.compressWithList(value.bytes);
        final imageFile =
            File('${tempstore.path}/pdfImages' + (i -1).toString() + '.jpg');
        imageFile.writeAsBytesSync(byte);
      });
      page.close();
      yield i;
      if (i == document.pagesCount) break;
    }
  }

  create() async {
    tempdir = await getTemporaryDirectory();
    name = genName(10);
    var file = File(tempdir.path + "/" + name + ".pdf");
    file.writeAsBytes(pdf.save());
    this.file = file.path;
  }

  save() {}
  retrieve() {}
  String genName(int length) {
    var rand = new Random();
    var codeUnits = new List.generate(length, (index) {
      return rand.nextInt(25) + 96 + 1;
    });
    this.dir = String.fromCharCodes(codeUnits);
    return String.fromCharCodes(codeUnits);
  }

  addpdf(int i) async {
    final file = origin;
    ipdf.PdfDocument document = await ipdf.PdfDocument.openFile(file);
    var page = await document.getPage(i + 1);
    Uint8List byte;
    await page
        .render(
            width: page.width,
            height: page.height,
            format: ipdf.PdfPageFormat.JPEG)
        .then((value) {
      byte = value.bytes;
    });

    page.close();
    PdfImage img = PdfImage.jpeg(
      pdf.document,
      image: byte,
    );
    pdf.addPage(pw.Page(build: (pw.Context context) {
      return pw.Center(
        child: pw.Image(img),
      ); // Center
    }));
  }

  addimg(String path) async {
    File(path).readAsBytes().then((value) {
      final image = PdfImage.jpeg(pdf.document, image: value);
      pdf.addPage(pw.Page(build: (pw.Context context) {
        return pw.Center(
          child: pw.Expanded(child: pw.Image(image)),
        ); // Center
      }));
    });
  }
}
