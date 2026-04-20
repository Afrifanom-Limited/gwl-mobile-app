import 'dart:convert' show base64, utf8;
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/GPSService.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/views/meter/AddMeter.dart';
import 'package:gwcl/views/transactions/PayBillForOthers.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../views/index/intro.dart';

Expanded buildPoweredByAfrifanom({int? flex}) {
  return Expanded(
    flex: flex ?? 2,
    child: GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        launchURL(Constants.afrifanomWebsite);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: "Powered by ",
                  style: TextStyle(
                    color: Constants.kPrimaryColor,
                    fontSize: 12.sp,
                  ),
                ),
                TextSpan(
                  text: ' ',
                ),
                TextSpan(
                  text: 'Afrifanom Limited',
                  style: TextStyle(
                    color: Constants.kPrimaryColor,
                    fontSize: 12.sp,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget dialUssdForCode() {
  return GestureDetector(
    onTap: () {
      HapticFeedback.lightImpact();
      launchURL("tel:" + Uri.encodeComponent('*1010*1010#'));
    },
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: "Dial ",
                style: TextStyle(
                  color: Constants.kPrimaryColor,
                  fontSize: 13.sp,
                ),
              ),
              TextSpan(
                text: "*1010*1010#",
                style: TextStyle(
                  color: Constants.kPrimaryColor,
                  fontSize: 14.sp,
                  fontFamily: Constants.kFontMedium,
                ),
              ),
              TextSpan(
                text: " to see your code",
                style: TextStyle(
                  color: Constants.kPrimaryColor,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20)
      ],
    ),
  );
}

bool hasData(data) {
  if (data.length > 0) {
    return true;
  }
  return false;
}

String httpLink(inputLink) {
  String link;
  try {
    link = inputLink.replaceAll("https:", "http:");
  } catch (e) {
    link = "$inputLink";
  }
  return link;
}

String? validateEmail(String value) {
  Pattern pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
  RegExp regex = new RegExp(pattern.toString());
  if (!regex.hasMatch(value))
    return 'Please enter a valid email address';
  else
    return null;
}

String? validatePhone(String value) {
  Pattern pattern = r'(^(?:[+0]9)?[0-9]{10,12}$)';
  RegExp regex = new RegExp(pattern.toString());
  if (value.isEmpty || !regex.hasMatch(value) || value[0] != "0")
    return 'Provide a valid phone number. For example: 024XXXXXXX';
  else
    return null;
}

String? validateCode(String value) {
  Pattern pattern = r'(^(?:[+0]9)?[0-9]{6,6}$)';
  RegExp regex = new RegExp(pattern.toString());
  if (!regex.hasMatch(value))
    return 'Enter a valid code';
  else
    return null;
}

String getImagePath(String value) {
  String pattern = r'(http|https)://[\w-]+(\.[\w-]+)+([\w.,@?^=%&amp;:/~+#-]*[\w@?^=%&amp;/~+#-])?';
  RegExp regExp = new RegExp(pattern.toString());
  if (!regExp.hasMatch(value)) {
    return Endpoints.public + value;
  }
  return value;
}

String? money(String value) {
  Pattern pattern = r'(^[+-]?[0-9]{1,3}(?:,?[0-9]{3})*(?:\.[0-9]{1,2})?$)';
  RegExp regex = new RegExp(pattern.toString());
  if (value.isEmpty || !regex.hasMatch(value) || value.toString()[0] == '0')
    return 'Invalid amount. Input field allows decimal (one or two digits). Minimum amount is GHS 1.00';
  else
    return null;
}

String? checkNull(String value, String field) {
  if (value.isEmpty)
    return '$field is required';
  else
    return null;
}

String getMsisdn(String number) {
  var re = RegExp(r'\d{1}');
  return number.replaceFirst(re, '233');
}

String getActualPhone(String msisdn) {
  var re = RegExp(r'\d{3}');
  return msisdn.replaceFirst(re, '0');
}

String stripSymbols(String string) {
  var re = RegExp(r"[^\s\w]");
  return string.replaceAll(re, '');
}

String stripWhiteSpaces(String string) {
  var re = RegExp(r"\s+\b|\b\s");
  return string.replaceAll(re, '');
}

String greeting() {
  var hour = DateTime.now().hour;
  if (hour < 12) {
    return 'Good Morning';
  }
  if (hour < 17) {
    return 'Good Afternoon';
  }
  return 'Good Evening';
}

double amountPercentage({dynamic percentage = 2, dynamic amount}) {
  return (percentage / 100) * double.parse(amount.toString());
}

String appShare(type, deepLink) {
  String message = "Download the GWL App - ";
  return "$message ${Constants.gwclAppDownload}";
}

dynamic showSnackBar(context, {required String message, required Color bgColor, required Color textColor}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: Duration(seconds: 2),
      backgroundColor: bgColor,
      content: GText(
        textData: message,
        textAlign: TextAlign.center,
        textColor: textColor,
      ),
    ),
  );
}

dynamic coolAlert(
  context,
  type, {
  String? title,
  required String subtitle,
  required String confirmBtnText,
  required bool showCancelBtn,
  bool? barrierDismissible,
  String? cancelBtnText,
  VoidCallback? onCancelBtnTap,
  VoidCallback? onConfirmBtnTap,
}) {
  CoolAlert.show(
    context: context,
    type: type ?? CoolAlertType.success,
    text: subtitle,
    title: title ?? "Success",
    animType: CoolAlertAnimType.scale,
    confirmBtnColor: Constants.kPrimaryColor,
    confirmBtnText: confirmBtnText,
    cancelBtnText: cancelBtnText ?? "View",
    backgroundColor: Constants.kPrimaryLightColor,
    showCancelBtn: showCancelBtn,
    confirmBtnTextStyle: TextStyle(
      color: Constants.kWhiteColor,
      fontWeight: FontWeight.w400,
      fontSize: 14.sp,
    ),
    cancelBtnTextStyle: TextStyle(
      color: Constants.kAccentColor,
      fontWeight: FontWeight.w400,
      fontSize: 14.sp,
    ),
    barrierDismissible: barrierDismissible ?? true,
    onCancelBtnTap: onCancelBtnTap ?? () {},
    onConfirmBtnTap: onConfirmBtnTap ?? () {},
  );
}

int getCurrentYear() {
  var now = new DateTime.now();
  var formatter = new DateFormat('yyyy');
  String formattedDate = formatter.format(now);
  return int.parse(formattedDate); // 2016-01-25
}

launchURL(String url) async {
  try {
    Uri uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  } catch (e) {
    print(e);
  }
}

callLauncher(String phoneNumber) async {
  try {
    final raw = phoneNumber.trim().replaceFirst(RegExp(r'^tel:'), '');
    final normalized = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    final dialNumber = normalized.startsWith('0')
        ? normalized.replaceFirst(RegExp(r'^0'), '+233')
        : normalized;
    final uri = Uri(scheme: 'tel', path: dialNumber);
    print("URI: $uri");

    // For iOS, prefer external application and fall back to telprompt.
    if (Platform.isIOS) {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final promptUri = Uri.parse('telprompt:$dialNumber');
        final promptLaunched = await launchUrl(promptUri, mode: LaunchMode.externalApplication);
        if (!promptLaunched) {
          throw 'Could not launch $uri';
        }
      }
      return;
    }

    if (await canLaunchUrl(uri)) {
      print("Launching URL: $uri");
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $uri';
    }
  } catch (e) {
    print(e);
  }
}

Future<Map> getDeviceInfo() async {
  String id = "", brand = "", model = "";
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    id = '${androidInfo.id}';
    brand = '${androidInfo.brand}';
    model = '${androidInfo.model}';
  } else {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    id = '${iosInfo.identifierForVendor}';
    brand = '${iosInfo.systemName}';
    model = '${iosInfo.utsname.machine}';
  }

  var map = new Map<String, dynamic>();
  map["deviceId"] = id;
  map["operatingSystem"] = Platform.operatingSystem;
  map["appId"] = Constants.appId;
  map["brand"] = brand;
  map["model"] = model;
  return map;
}

Future<Map> getDevicePackageInfo() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String appName = packageInfo.appName;
  String packageName = packageInfo.packageName;
  String version = packageInfo.version;
  String buildNumber = packageInfo.buildNumber;

  var map = new Map<String, dynamic>();
  map["appName"] = appName;
  map["packageName"] = packageName;
  map["version"] = version;
  map["buildNumber"] = buildNumber;
  return map;
}

// Future<File> compressImage(String imagePath) async {
//   //File compressedFile = await FlutterNativeImage.compressImage(imagePath, quality: 80, targetWidth: 600, targetHeight: (properties.height! * 600 / properties.width!).round());
//
//   var compressedFile = await FlutterImageCompress.compressWithFile(
//     imagePath,
//     quality: 80,
//     minWidth: 600,
//     minHeight: 600,
//   );
//   return compressedFile;
// }

Future logout(BuildContext context) async {
  try {
    var _localDb = new LocalDatabase();
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    var _phoneNumber = _localStorage.getString('localAuthPhone');
    // Unsubscribe from notification service
    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    if (_phoneNumber != null && _phoneNumber.isNotEmpty) {
      // On iOS, topic operations require APNs token.
      if (!Platform.isIOS) {
        await firebaseMessaging.unsubscribeFromTopic(_phoneNumber);
        await firebaseMessaging.unsubscribeFromTopic(Constants.appId);
      } else {
        final apnsToken = await firebaseMessaging.getAPNSToken();
        if (apnsToken != null && apnsToken.isNotEmpty) {
          await firebaseMessaging.unsubscribeFromTopic(_phoneNumber);
          await firebaseMessaging.unsubscribeFromTopic(Constants.appId);
        }
      }
    }

    await _localStorage.clear();
    await _localDb.deleteAllOtherTables();
    await _localStorage.clear();

    Navigator.of(context).pushNamedAndRemoveUntil(Introduction.id, (Route<dynamic> route) => false);
  } catch (e) {
    Navigator.of(context).pushNamedAndRemoveUntil(Introduction.id, (Route<dynamic> route) => false);
  }
}

bool isAndroid() {
  if (Platform.isAndroid) {
    return true;
  }
  return false;
}

dynamic getLongLat() async {
  final gps = GPSLocation();
  var data = new Map<String, dynamic>();
  try {
    var location = await gps.getCurrentLocation();
    if (location != null) {
      data['longitude'] = location.latitude;
      data['latitude'] = location.longitude;
    }
    return data;
  } catch (e) {
    print(e.toString());
  }
}

TableRow tableRow(firstCol, secondCol, {Color? secondColColor}) {
  return TableRow(
    children: [
      Container(
        padding: EdgeInsets.all(10.w),
        child: GText(textData: firstCol ?? "None", textSize: 12.sp, textColor: Constants.kGreyColor),
      ),
      Container(
        color: Constants.kPrimaryLightColor,
        padding: EdgeInsets.all(10.w),
        child: GText(
          textData: secondCol ?? "None",
          textSize: 12.sp,
          textColor: secondColColor,
        ),
      ),
    ],
  );
}

Future<String> getLocalPath(folderName) async {
  final directory = Platform.isAndroid ? await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();
  var _localPath = directory!.path + Platform.pathSeparator + '$folderName';
  final savedDir = Directory(_localPath);
  bool hasExisted = await savedDir.exists();
  if (!hasExisted) {
    savedDir.create();
  }
  return _localPath;
}

String formatDigitalAddress(String address) {
  String newAddress = address;
  if (address.isNotEmpty && address.length > 6) {
    address = address.replaceAll("-", "");
    address = address.replaceAll(" ", "");
    newAddress = address.substring(0, 2) + "-" + address.substring(2, address.length - 4) + "-" + address.substring(address.length - 4);
    return newAddress.toUpperCase();
  }
  return address;
}

String formatCustomerAccountNumber(String number) {
  String newNumber = number;
  if (number.isNotEmpty && number.length > 6) {
    number = number.replaceAll("-", "");
    number = number.replaceAll(" ", "");
    newNumber = number.substring(0, 4) + "-" + number.substring(4, number.length - 4) + "-" + number.substring(number.length - 4);
    return newNumber.toUpperCase();
  }
  return number;
}

getAesCusIDKey(dynamic id) {
  var key = "";
  var len = id.toString().length;
  String keyLen = len.toString();
  if (len < 10) {
    keyLen = len.toString().padLeft(2, '0');
  }
  while (key.toString().length <= 16) {
    key += keyLen + id.toString();
  }
  return key.substring(0, 16);
}

getAesCusIDIV(dynamic id) {
  var key = "";
  var len = id.toString().length;
  String keyLen = len.toString();
  if (len < 10) {
    keyLen = len.toString().padLeft(2, '0');
  }
  while (key.toString().length <= 16) {
    key += id.toString() + keyLen;
  }
  return key.substring(0, 16);
}

getAesMobileIDKey() async {
  var key = "";
  var _deviceInfo = await getDeviceInfo();
  var _deviceId = _deviceInfo.values.toList()[0];
  var _base64Id = base64.encode(utf8.encode(_deviceId));
  key = _base64Id.toString();
  while (_base64Id.toString().length <= 16) {
    key += _base64Id.toString();
  }
  return key.substring(0, 16);
}

String getCardType(String cardNumber) {
  final rAmericanExpress = RegExp(r'^3[47][0-9]{0,}$');
  final rDinersClub = RegExp(r'^3(?:0[0-59]{1}|[689])[0-9]{0,}$');
  final rDiscover = RegExp(r'^(6011|65|64[4-9]|62212[6-9]|6221[3-9]|622[2-8]|6229[01]|62292[0-5])[0-9]{0,}$');
  final rJcb = RegExp(r'^(?:2131|1800|35)[0-9]{0,}$');
  final rMasterCard = RegExp(r'^(5[1-5]|222[1-9]|22[3-9]|2[3-6]|27[01]|2720)[0-9]{0,}$');
  final rMaestro = RegExp(r'^(5[06789]|6)[0-9]{0,}$');
  final rRupay = RegExp(r'^(6522|6521|60)[0-9]{0,}$');
  final rVisa = RegExp(r'^4[0-9]{0,}$');
  final rElo = RegExp(
      r'^(4011(78|79)|43(1274|8935)|45(1416|7393|763(1|2))|50(4175|6699|67[0-7][0-9]|9000)|50(9[0-9][0-9][0-9])|627780|63(6297|6368)|650(03([^4])|04([0-9])|05(0|1)|05([7-9])|06([0-9])|07([0-9])|08([0-9])|4([0-3][0-9]|8[5-9]|9[0-9])|5([0-9][0-9]|3[0-8])|9([0-6][0-9]|7[0-8])|7([0-2][0-9])|541|700|720|727|901)|65165([2-9])|6516([6-7][0-9])|65500([0-9])|6550([0-5][0-9])|655021|65505([6-7])|6516([8-9][0-9])|65170([0-4]))');

  cardNumber = cardNumber.trim().replaceAll(' ', '');

  if (rAmericanExpress.hasMatch(cardNumber)) {
    return "americanExpress";
  } else if (rMasterCard.hasMatch(cardNumber)) {
    return "masterCard";
  } else if (rVisa.hasMatch(cardNumber)) {
    return "visa";
  } else if (rDinersClub.hasMatch(cardNumber)) {
    return "dinersClub";
  } else if (rRupay.hasMatch(cardNumber)) {
    if (rDiscover.hasMatch(cardNumber)) {
      return "discover";
    } else {
      return "rupay";
    }
  } else if (rDiscover.hasMatch(cardNumber)) {
    return "discover";
  } else if (rJcb.hasMatch(cardNumber)) {
    return "jcb";
  } else if (rElo.hasMatch(cardNumber)) {
    return "elo";
  } else if (rMaestro.hasMatch(cardNumber)) {
    return "maestro";
  }

  return "other";
}

viewImages(BuildContext context, List<dynamic> images, int index) {
  PageController _controller = PageController(initialPage: index, keepPage: false);
  Navigator.of(context, rootNavigator: true).push(
    new MaterialPageRoute<bool>(
      fullscreenDialog: false,
      builder: (BuildContext context) => PageView.builder(
        controller: _controller,
        itemBuilder: (context, position) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Material(
              type: MaterialType.transparency,
              child: Stack(
                children: <Widget>[
                  Center(
                    child: CachedNetworkImage(
                        imageUrl: getImagePath(images[position]),
                        imageBuilder: (context, imageProvider) => PhotoView(
                              imageProvider: imageProvider,
                            ),
                        placeholder: (context, url) => Center(
                              child: CircularLoader(
                                loaderColor: Constants.kPrimaryColor,
                                strokeWidth: 2,
                              ),
                            ),
                        errorWidget: (context, url, error) => Center(
                              child: Container(
                                height: 300.h,
                                width: MediaQuery.of(context).size.width,
                                color: Constants.kGreyColor,
                                child: Center(
                                  child: GText(textData: "Unable to load image"),
                                ),
                              ),
                            ),
                        alignment: Alignment.center,
                        fit: BoxFit.fitWidth,
                        width: MediaQuery.of(context).size.width),
                  ),
                  Container(
                    child: Positioned(
                      bottom: MediaQuery.of(context).size.height * 0.052,
                      right: MediaQuery.of(context).size.width * 0.43,
                      child: ClipOval(
                        child: Material(
                          color: Constants.kRedColor, // button color
                          child: InkWell(
                            splashColor: Constants.kPrimaryColor.withOpacity(0.5),
                            child: SizedBox(width: 50.w, height: 50.w, child: Icon(Icons.close, color: Constants.kWhiteColor)),
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        itemCount: images.length,
      ),
    ),
  );
}

addAccountFirst(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Constants.kSizeHeight_20,
      GText(
        textData: "Oops! You have not added "
            "your Ghana Water customer account number yet",
        textSize: 12.sp,
        textColor: Constants.kGreyColor,
        textFont: Constants.kFont,
        textMaxLines: 5,
        textAlign: TextAlign.center,
      ),
      Constants.kSizeHeight_10,
      Center(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushReplacementNamed(context, AddMeter.id);
          },
          child: Container(
            width: 240.w,
            height: 200.h,
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: BoxDecoration(
              color: Constants.kPrimaryLightColor,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(50.w),
                topLeft: Radius.circular(10.w),
                bottomLeft: Radius.circular(10.w),
                bottomRight: Radius.circular(10.w),
              ),
              border: Border.all(color: Constants.kPrimaryColor.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Constants.kPrimaryColor.withOpacity(0.2),
                  spreadRadius: 0,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(vertical: 14.w, horizontal: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Constants.kSizeHeight_20,
                Constants.kSizeHeight_10,
                Icon(
                  Icons.add_circle,
                  color: Constants.kPrimaryColor,
                  size: 46.sp,
                ),
                Constants.kSizeHeight_10,
                GText(
                  textData: "Add your Ghana Water\n account number",
                  textSize: 12.sp,
                  textColor: Constants.kPrimaryColor,
                  textFont: Constants.kFont,
                  textMaxLines: 5,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      Constants.kSizeHeight_10,
      Container(
        width: 240.w,
        height: 50.h,
        decoration: BoxDecoration(
          boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 5.0)],
        ),
        child: TextButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Constants.kPrimaryColor),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
                side: BorderSide(
                  color: Constants.kPrimaryColor,
                ),
              ),
            ),
          ),
          child: GText(
            textData: "Pay Water Bill",
            textSize: 12.sp,
            textColor: Constants.kWhiteColor,
            textFont: Constants.kFont,
          ),
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PayBillForOthers(),
              ),
            );
          },
        ),
      ),
    ],
  );
}

bool autoPaymentEligible(String network) {
  // if (network == "CARD" ||
  //     network == Constants.vodafone ||
  //     network == Constants.airteltigo) {
  //   return false;
  // } else {
  //   return true;
  // }
  // TODO: Uncomment when ready
  return false;
}
