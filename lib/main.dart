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
import 'package:testapp/data.dart';
import 'package:testapp/file_listing_screen.dart';
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
  ValueNotifier _notifier = ValueNotifier(0);
  int progress = 0;
  int itemindex = 0;
  String url =
      "https://img.freepik.com/free-vector/tropical-plant-transparent-background_1308-75692.jpg";
  ReceivePort _port = ReceivePort();
  // int progress = 0;
  @override
  void initState() {
    super.initState();

    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      setState(() {
        String id = data[0];
        DownloadTaskStatus status = DownloadTaskStatus(data[1]);

        progress = data[2];
        print("progress$progress");

        _notifier.value = progress;
      });
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
          LinearProgressIndicator(
            valueColor: new AlwaysStoppedAnimation<Color>(Colors.red),
            value: progress / 100,
          ),
          ValueListenableBuilder(
            valueListenable: _notifier,
            builder: (context, value, _) {
              return Text("downloding....$progress");
            },
          ),
          Expanded(
              child: ListView.separated(
                  itemBuilder: (context, index) {
                    final data = dataList[index];
                    return InkWell(
                      onTap: () {
                        // newdownloadtask(url: data['url']!);
                      },
                      child: Card(
                        child: ListTile(
                            title: Text(data['title']!),
                            trailing: Container(
                              width: 150,
                              child: Row(
                                children: [
                                  itemindex == index
                                      ? CircularProgressIndicator(
                                          strokeWidth: 4,
                                          value: progress / 100,
                                        )
                                      : SizedBox(),
                                  IconButton(
                                    icon: Icon(Icons.download),
                                    onPressed: () {
                                      setState(() {
                                        itemindex = index;
                                      });

                                      newdownloadtask(url: data['url']!);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.share),
                                    onPressed: () {
                                      Share.share(data['url']!);
                                    },
                                  ),
                                ],
                              ),
                            )),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) {
                    return SizedBox(
                      height: 15,
                    );
                  },
                  itemCount: dataList.length))
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
    final externaldir = await getApplicationDocumentsDirectory();
    final taskId = await FlutterDownloader.enqueue(
      url: url,
      headers: {}, // optional: header send with url (auth token etc)
      savedDir: externaldir.path,
      saveInPublicStorage: true,
      showNotification:
          true, // show download progress in status bar (for Android)
      openFileFromNotification:
          true, // click on notification to open downloaded file (for Android)
    );
  }
}
