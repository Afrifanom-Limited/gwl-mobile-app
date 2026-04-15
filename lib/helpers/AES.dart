import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as Enc;
import 'package:gwcl/helpers/Functions.dart';
import 'dart:convert' show base64, utf8;
import 'package:gwcl/helpers/Utils.dart';

class Aes {
  static Future<String> encrypt(String msg, {String? key}) async {
    var localKey = await getAesMobileIDKey();
    String ivText = Utils.randomString(16);
    final encKey = Enc.Key.fromUtf8(key ?? localKey);
    final iv = Enc.IV.fromUtf8(ivText);
    final encrypter = Enc.Encrypter(Enc.AES(encKey, mode: Enc.AESMode.cbc));
    Uint8List encrypted = encrypter.encrypt(msg, iv: iv).bytes;
    Uint8List ivBytes = iv.bytes;
    var fullData = new Uint8List.fromList(ivBytes).toList();
    fullData.addAll(encrypted);
    return base64.encode(fullData);
  }

  static Future<String> decrypt(String encMsg, {String? key}) async {
    var localKey = await getAesMobileIDKey();
    final encKey = Enc.Key.fromUtf8(key ?? localKey);
    var fullData = base64.decode(encMsg);
    var ivData = fullData.sublist(0, 16);
    var encData = fullData.sublist(16);
    var iv = Enc.IV(ivData);
    var ency = Enc.Encrypted(encData);
    final decrypter = Enc.Encrypter(Enc.AES(encKey, mode: Enc.AESMode.cbc));
    String decryptedStr = decrypter.decrypt(ency, iv: iv);
    return decryptedStr;
  }

  static String gwclEncrypt(String msg, String key, String ivText) {
    final encKey = Enc.Key.fromUtf8(key);
    final iv = Enc.IV.fromUtf8(ivText);
    final encrypter = Enc.Encrypter(Enc.AES(encKey, mode: Enc.AESMode.cbc));
    Uint8List encrypted = encrypter.encrypt(msg, iv: iv).bytes;
    return base64.encode(encrypted);
  }

  static String encodeBase64(String string) {
    return base64.encode(utf8.encode(string));
  }
}
