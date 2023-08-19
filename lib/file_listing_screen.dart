import 'package:flutter/material.dart';

import 'package:testapp/file_download_screen.dart';

class FileListingScreen extends StatefulWidget {
  const FileListingScreen({super.key});

  @override
  State<FileListingScreen> createState() => _FileListingScreenState();
}

class _FileListingScreenState extends State<FileListingScreen> {
  /// [downloadLinks] contains all the links to be download.
  List<String> downloadLinks = [
    'https://download.pexels.com/vimeo/371817283/pexels-pressmaster-3195394.mp4?fps=25.0&width=1920',
    'https://engineering.letsnurture.com/wp-content/uploads/2018/07/flutter.png',
    'https://miro.medium.com/v2/resize:fit:1200/1*5JFH1YSl7NHZ4kPghfXfEg.jpeg',
    'https://fluttergeek.com/blog/assets/images/flutter_banner.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Flutter downloader",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView.builder(
          itemCount: downloadLinks.length,
          itemBuilder: (context, index) {
            return ListTile(
              onTap: () {
                onFileTileTap(
                  context: context,
                  index: index,
                  url: downloadLinks[index],
                );
              },
              title: Text("File ${index + 1}"),
              trailing: const Icon(
                Icons.download_rounded,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> onFileTileTap({
    required String url,
    required int index,
    required BuildContext context,
  }) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return FileDownloadScreen(
            url: url,
            index: index,
            context: context,
          );
        },
      ),
    );
  }
}
