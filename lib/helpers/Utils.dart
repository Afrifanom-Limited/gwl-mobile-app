import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:path_provider/path_provider.dart';

class Utils {
  static Future<String> get getStorageDir async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static String getAppID() {
    return "cf7c1ea0a53e1723d70753e2d66c4976";
  }

  static getImageUrl(image) {
    if (hasData(image)) {
      var hasHttps = (image.indexOf('https://') < 0) ? false : true;
      var hasHttp = (image.indexOf('http://') < 0) ? false : true;
      if (hasHttps || hasHttp) {
        return image;
      }
      return Endpoints.baseUrl + image;
    }
    return Endpoints.baseUrl + "no_image";
  }

  static String randomString(int length) {
    var rand = new Random();
    var codeUnits = new List.generate(length, (index) {
      return rand.nextInt(33) + 89;
    });
    return new String.fromCharCodes(codeUnits);
  }

  static bool hasData(data) {
    return null != data && data.length > 0;
  }

  static Future<File> writeToFile(ByteData data, String path, String filename) {
    final buffer = data.buffer;
    return File("$path/$filename").writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  static Future deleteFile(file) async {
    var dir = new File("$file");
    dir.deleteSync(recursive: true);
  }

  static Future<String> createDir(String path) async {
    var data = path;
    if (FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound) {
      await Directory(path).create().then((Directory directory) {
        data = directory.path;
      });
    }
    return data;
  }

  static Future<String> get getFileDir async {
    final directory = await getExternalStorageDirectory();
    return directory!.path;
  }

  static length(data) {
    if (hasData(data)) {
      return data.split(",").length;
    }
    return 0;
  }

  static last(data) {
    var arr = data.split(",");
    return arr[arr.length - 1];
  }

  static getImages(data) {
    var arr = [data];
    if (data.contains(',')) {
      arr = data.split(",");
    }
    return arr;
  }

  static removeLast(data) {
    var arr = [data];
    if (data.contains(',')) {
      arr = data.split(",");
      arr.removeAt(arr.length - 1);
    }
    return arr.join(',');
  }

  static remove(data, index) {
    var arr = [data];
    if (data.contains(',')) {
      arr = data.split(",");
      arr.removeAt(index);
    }
    return arr.join(',');
  }

  static arrayRemove(data, index) {
    data.removeAt(index);
    return data;
  }

  static truncate(text, length, suffix) {
    if (text.length > length) {
      return text.substring(0, length) + suffix;
    } else {
      return text;
    }
  }
}
