/// this is not part of the demo app. this file is for personal use.

import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';

/// [DownloadsController] is used to control the download process.
/// It handles the initialization, registering [SendPort], enqueue the download task, pause, resume and cancel the download task, track the status of the task, etc.
class DownloadsController {
  /// [_port] is used to communicate with the isolates.
  static final ReceivePort _port = ReceivePort();

  /// [downloadTaskId] variable is used to store the id of the download task created when the [FlutterDownloader.enqueue] method is called.
  static String? downloadTaskId;

  /// [downloadTaskStatus] is used to store the task status.
  static ValueNotifier<int>? downloadTaskStatus = ValueNotifier(0);

  /// [downloadTaskProgress] store the progress of the download task. ranging between 1 to 100.
  static ValueNotifier<int>? downloadTaskProgress = ValueNotifier(0);

  /// [isDownloading] is set to true if the file is being downloaded.
  static ValueNotifier<bool> isDownloading = ValueNotifier(false);

  /// [initDownloadController] method will initialize the downloader controller and perform certain operations like registering the port, initializing the register callback etc.
  static initDownloadController() {
    log('DownloadsController - initDownloadController called');
    _bindBackgroundIsolate();
  }

  /// [disposeDownloadController] is used to unbind the isolates and dispose the controller
  static disposeDownloadController() {
    _unbindBackgroundIsolate();
  }

  /// [_bindBackgroundIsolate] is used to register the [SendPort] with the name [downloader_send_port].
  /// If the registration is successful then it will return true else it will return false.
  static _bindBackgroundIsolate() {
    log('DownloadsController - _bindBackgroundIsolate called');
    final isSuccess = IsolateNameServer.registerPortWithName(
      _port.sendPort,
      'downloader_send_port',
    );

    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    } else {
      FlutterDownloader.registerCallback(_registerCallback);
    }
  }

  /// [_unbindBackgroundIsolate] is used to remove the registered [SendPort] [downloader_send_port]'s mapping.
  static void _unbindBackgroundIsolate() {
    log('DownloadsController - _unbindBackgroundIsolate called');
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  /// [_registerCallback] is used to update the download progress
  @pragma('vm:entry-point')
  static _registerCallback(String id, int status, int progress) {
    log("DownloadsController - _registerCallback - task id = $id, status = $status, progress = $progress");

    downloadTaskId = id;
    downloadTaskStatus = ValueNotifier(status);
    downloadTaskProgress = ValueNotifier(progress);

    if (status == 2) {
      isDownloading.value = true;
    } else {
      isDownloading.value = false;
    }

    final SendPort? send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send!.send([id, status, progress]);
  }

  /// [downloadFile] method is used to download the enqueue the file to be downloaded using the [url].
  static Future<void> downloadFile({required String url}) async {
    log('DownloadsController - downloadFile called');
    log('DownloadsController - downloadFile - url = $url');

    isDownloading.value = true;

    /// [downloadDirPath] var stores the path of device's download directory path.
    late String downloadDirPath;
    if (Platform.isIOS) {
      downloadDirPath = (await getDownloadsDirectory())!.path;
    } else {
      downloadDirPath = (await getApplicationDocumentsDirectory()).path;
    }
    downloadTaskId = await FlutterDownloader.enqueue(
      url: url,
      headers: {}, // optional: header send with url (auth token etc)
      savedDir: downloadDirPath,
      saveInPublicStorage: true,
      showNotification:
          true, // show download progress in status bar (for Android)
      openFileFromNotification:
          true, // click on notification to open downloaded file (for Android)
    );
  }

  /// [pauseDownload] pauses the current download task
  static Future pauseDownload() async {
    await FlutterDownloader.pause(taskId: downloadTaskId ?? '');
  }

  /// [resumeDownload] resumes the paused download task
  static Future resumeDownload() async {
    await FlutterDownloader.resume(taskId: downloadTaskId ?? '');
  }

  /// [cancelDownload] cancels the current download task
  static Future cancelDownload() async {
    await FlutterDownloader.cancel(taskId: downloadTaskId ?? '');
    isDownloading.value = false;
  }

  /// [getDownloadStatusString] returns the status of the download task in string format to show on screen.
  static String getDownloadStatusString() {
    late String downloadStatus;

    switch (downloadTaskStatus?.value ?? 0) {
      case 0:
        downloadStatus = 'Undefined';
        break;
      case 1:
        downloadStatus = 'Enqueued';
        break;
      case 2:
        downloadStatus = 'Downloading';
        break;
      case 3:
        downloadStatus = 'Failed';
        break;
      case 4:
        downloadStatus = 'Canceled';
        break;
      case 5:
        downloadStatus = 'Paused';
        break;
      default:
        downloadStatus = "Error";
    }

    return downloadStatus;
  }
}
