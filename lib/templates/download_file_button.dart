import 'dart:io';

import 'package:cool_alert/cool_alert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/ProgressDialog.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../mixpanel.dart';
import '../system/RestDataSource.dart';

class DownloadFileButton extends StatefulWidget {
  final String pdfPath;
  final String buttonTitle;
  DownloadFileButton({required this.pdfPath, required this.buttonTitle});

  @override
  State<DownloadFileButton> createState() => _DownloadFileButtonState();
}

class _DownloadFileButtonState extends State<DownloadFileButton> {
  late Dio _dio;
  RestDataSource _request = new RestDataSource();
  bool _isLoading = false;
  String _progress = "";
  bool _allowWriteFile = false;

  _requestWritePermission() async {
    var storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) {
      setState(() {
        _allowWriteFile = true;
      });
    }
  }

  Future<String> _getDirectoryPath() async {
    dynamic path = await getLocalPath('reports');
    return path;
  }

  Future<void> _openFile({required String pdfPath}) async {
    String fileName = pdfPath.substring(pdfPath.lastIndexOf("/"));
    _getDirectoryPath().then(
      (path) async {
        var fileFullPath = "$path$fileName";
        File f = File(fileFullPath);
        if (f.existsSync()) {
          OpenFile.open(f.path, type: "application/pdf", uti: "com.adobe.pdf");
          return;
        }
        String fileUrl;
        if (pdfPath.contains("generate-payment-receipt")) {
          fileUrl = Endpoints.report_requests + pdfPath;
          setState(() {
            _isLoading = true;
          });
          var request = await _request.getRaw(context, url: fileUrl);
          var response = request['response'];
          var fileName = response['response'];
          fileUrl = Endpoints.public + fileName;
          _downloadFile(fileUrl, fileFullPath, actualPath: fileName);
          setState(() {
            _isLoading = false;
          });
          //mixpanel?.track('View Payment Receipt', properties: {"fileUrl": fileUrl});
        } else {
          fileUrl = Endpoints.public + pdfPath;
          _downloadFile(fileUrl, fileFullPath, actualPath: pdfPath);
          mixpanel?.track('View Bill', properties: {"fileUrl": fileUrl});
        }
      },
    );
  }

  Future _downloadFile(String url, path, {actualPath}) async {
    _dio = Dio();
    if (!_allowWriteFile) {
      _requestWritePermission();
    }

    ProgressDialog progressDialog = ProgressDialog(context, type: ProgressDialogType.Normal);
    try {
      progressDialog.style(
        message: "Downloading File",
        messageTextStyle: TextStyle(
          fontFamily: Constants.kFontLight,
        ),
      );
      progressDialog.show();
      await _dio.download(url, path, onReceiveProgress: (rec, total) {
        setState(() {
          _progress = ((rec / total) * 100).toStringAsFixed(0) + "%";
          progressDialog.update(message: "Downloading $_progress");
        });
      });
      progressDialog.hide();
      _openFile(pdfPath: actualPath);
    } catch (e) {
      progressDialog.hide();
      CoolAlert.show(
        context: context,
        type: CoolAlertType.error,
        text: "Unable to download file. Please try again later",
        title: "Download Receipt",
      );

      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(18.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        foregroundColor: Colors.white,
      ),
      label: Text(widget.buttonTitle),
      onPressed: () {
        _openFile(pdfPath: widget.pdfPath);
      },
      icon: _isLoading
          ? SizedBox(
              child: CircularProgressIndicator(),
              width: 30,
              height: 30,
            )
          : Icon(Icons.download_for_offline),
    );
  }
}
