import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share/share.dart';

class QRDialog extends StatefulWidget {

  final String data;
  QRDialog(this.data);

  @override
  State<StatefulWidget> createState() => GenerateScreenState();
}

class GenerateScreenState extends State<QRDialog> {

  bool isLoading = false;
  GlobalKey globalKey = new GlobalKey();

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      children: <Widget>[
        GestureDetector(
          onTap: _captureAndSharePng,
          child: isLoading ? new Center(
            child: new CircularProgressIndicator(),
          ) : RepaintBoundary(
            key: globalKey,
            child: QrImage(
              backgroundColor: Color.fromRGBO(255, 255, 255, 1.0),
              data: widget.data,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _captureAndSharePng() async {
    try {
      setState(() => isLoading = true);
      RenderRepaintBoundary boundary = globalKey.currentContext.findRenderObject();
      var image = await boundary.toImage();
      ByteData byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await new File('${tempDir.path}/${widget.data}.png').create();
      await file.writeAsBytes(pngBytes);

      /*final channel = const MethodChannel('channel:me.albie.share/share');
      channel.invokeMethod('shareFile', 'image.png');*/

      StorageReference ref = FirebaseStorage.instance
          .ref()
          .child('qr-codes')
          .child('${widget.data}.png');

      StorageUploadTask uploadTask = ref.putFile(file);

      setState(() => isLoading = false);

      await Share.share((await ref.getDownloadURL()));
    } catch(e) {
      print(e.toString());
    }
  }
}