import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share/share.dart';
//import 'package:share_plus/share_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Plugin must be initialized before using
  await FlutterDownloader.initialize(
      debug:
          true, // optional: set to false to disable printing logs to console (default: true)
      ignoreSsl:
          true // option: set to false to disable working with http links (default: false)
      );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String url =
      "https://img.freepik.com/free-vector/tropical-plant-transparent-background_1308-75692.jpg";
  ReceivePort _port = ReceivePort();
  int progress = 0;
  @override
  void initState() {
    super.initState();

    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = DownloadTaskStatus(data[1]);

      setState(() {
        progress = data[2];
      });

      Get.showSnackbar(GetSnackBar(
        title: "completed",
      ));
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send!.send([id, status, progress]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Column(
        children: [
          Stack(children: [
            Image(
              image: NetworkImage(url),
            ),
            IconButton(
                onPressed: () {
                  Get.bottomSheet(BottomSheet(
                    onClosing: () {
                      Get.back();
                    },
                    builder: (context) {
                      return Container(
                        child: Column(
                          children: [
                            ElevatedButton(
                                onPressed: () {
                                  // download(url: url);
                                  newdownloadtask(url: url);
                                },
                                child: Text("download")),
                            ElevatedButton(
                                onPressed: () async {
                                  Share.share(url);
                                },
                                child: Text("share"))
                          ],
                        ),
                      );
                    },
                  ));
                },
                icon: Icon(Icons.menu))
          ]),
          LinearProgressIndicator(
            value: progress.toDouble(),
          ),
        ],
      )),
    );
  }

  Future<bool> _requestWritePermission() async {
    //PermissionStatus permissionResult = await SimplePermissions.requestPermission(Permission. WriteExternalStorage);
    await Permission.storage.request();
    return await Permission.storage.request().isGranted;
  }

  void download({required String url}) async {
    bool hasPermission = await _requestWritePermission();
    if (!hasPermission) return;

    // gets the directory where we will download the file.
    var dir = await getApplicationDocumentsDirectory();

    // You should put the name you want for the file here.
    // Take in account the extension.
    String fileName = 'myFile';

    // downloads the file
    Dio dio = Dio();
    final result = await dio.download(url, "${dir.path}/$fileName");
    //print();
    final resultd = await ImageGallerySaver.saveFile(result.data);

    // opens the file
    OpenFile.open("${dir.path}/$fileName", type: 'application/image');
  }

  void newdownloadtask({required String url}) async {
    bool hasPermission = await _requestWritePermission();
    if (!hasPermission) return;
    final externaldir = await getExternalStorageDirectory();
    final taskId = await FlutterDownloader.enqueue(
      url: url,
      headers: {}, // optional: header send with url (auth token etc)
      savedDir: externaldir!.path,
      fileName: 'downloads',
      showNotification:
          true, // show download progress in status bar (for Android)
      openFileFromNotification:
          true, // click on notification to open downloaded file (for Android)
    );
  }
}
