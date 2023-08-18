import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

void main() {
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

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key});
  String url =
      "https://img.freepik.com/free-vector/tropical-plant-transparent-background_1308-75692.jpg";
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
                                  download(url: url);
                                },
                                child: Text("download")),
                            ElevatedButton(
                                onPressed: () async {
                                  final result = await Share.shareXFiles(
                                      [XFile(url)],
                                      text: 'picture');
                                  if (result.status ==
                                      ShareResultStatus.dismissed) {
                                    print('Did you not like the pictures?');
                                  } else {
                                    print("picture shared");
                                  }
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
    await dio.download(url, "${dir.path}/$fileName");

    // opens the file
    OpenFile.open("${dir.path}/$fileName", type: 'application/pdf');
  }
}
