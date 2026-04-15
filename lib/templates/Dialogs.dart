import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gwcl/helpers/AES.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/FlashHelper.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/TextFields.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final Function confirm;
  final String confirmText;
  final Color confirmTextColor;
  final String? cancelText;
  ConfirmDialog({
    required this.title,
    required this.content,
    required this.confirm,
    this.cancelText,
    this.confirmText = "Confirm",
    this.confirmTextColor = Constants.kPrimaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoAlertDialog(
        title: GText(
          textData: title,
          textSize: 16.sp,
        ),
        content: GText(
          textData: content,
          textFont: Constants.kFontLight,
          textSize: 14.sp,
          textMaxLines: 15,
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            child: GText(
              textData: cancelText ?? "Cancel",
              textSize: 14.sp,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: GText(
              textData: confirmText,
              textColor: confirmTextColor,
              textSize: 14.sp,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              confirm();
            },
          ),
        ],
      );
    } else
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: GText(
          textData: title,
          textSize: 16.sp,
        ),
        content: GText(
          textData: content,
          textFont: Constants.kFontLight,
          textSize: 14.sp,
          textMaxLines: 15,
        ),
        actions: <Widget>[
          TextButton(
            child: GText(
              textData: "Cancel",
              textSize: 14.sp,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: GText(
              textData: confirmText,
              textColor: confirmTextColor,
              textSize: 14.sp,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              confirm();
            },
          ),
        ],
      );
  }
}

class InfoDialog extends StatelessWidget {
  final String title;
  final String content;
  InfoDialog({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoAlertDialog(
        title: GText(
          textData: title,
          textSize: 16.sp,
        ),
        content: GText(
          textData: content,
          textFont: Constants.kFontLight,
          textSize: 14.sp,
          textMaxLines: 15,
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            child: GText(
              textData: "Okay",
              textSize: 14.sp,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    } else
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: GText(
          textData: title,
          textSize: 16.sp,
        ),
        content: GText(
          textData: content,
          textFont: Constants.kFontLight,
          textSize: 14.sp,
          textMaxLines: 15,
        ),
        actions: <Widget>[
          TextButton(
            child: GText(
              textData: "Okay",
              textSize: 14.sp,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
  }
}

class ErrorDialog extends StatelessWidget {
  final String content;
  ErrorDialog({
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoAlertDialog(
        title: null,
        content: GText(
          textData: content,
          textFont: Constants.kFontLight,
          textSize: 14.sp,
          textMaxLines: 15,
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            child: GText(
              textData: "Close",
              textSize: 14.sp,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    } else
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: null,
        content: GText(
          textData: content,
          textFont: Constants.kFontLight,
          textSize: 14.sp,
          textMaxLines: 15,
        ),
        actions: <Widget>[
          TextButton(
            child: GText(
              textData: "Close",
              textSize: 14.sp,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
  }
}

//Show Dialog to force user to update
showVersionDialog(context, byForce) async {
  await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      String title = "New Update Available";
      String message =
          "A newer version of the app is available. Please update it now.";
      String btnLabel = "Update Now";
      String btnLabelCancel = "Later";
      return Platform.isIOS
          ? new CupertinoAlertDialog(
              title: GText(
                textData: title,
                textSize: 16.sp,
              ),
              content: GText(
                textData: message,
                textFont: Constants.kFontLight,
                textSize: 14.sp,
                textMaxLines: 15,
              ),
              actions: <Widget>[
                CupertinoDialogAction(
                  child: GText(
                    textData: btnLabel,
                    textSize: 14.sp,
                  ),
                  onPressed: () => launchURL(Constants.gwclAppDownload),
                ),
                if (byForce == "false")
                  CupertinoDialogAction(
                    child: GText(
                      textData: btnLabelCancel,
                      textSize: 14.sp,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            )
          : new AlertDialog(
              title: GText(
                textData: title,
                textSize: 16.sp,
              ),
              content: GText(
                textData: message,
                textFont: Constants.kFontLight,
                textSize: 14.sp,
                textMaxLines: 15,
              ),
              actions: <Widget>[
                TextButton(
                  child: GText(
                    textData: btnLabel,
                    textColor: Constants.kPrimaryColor,
                    textSize: 14.sp,
                  ),
                  onPressed: () => launchURL(Constants.gwclAppDownload),
                ),
                if (byForce == "false")
                  TextButton(
                    child: GText(
                      textData: "Later",
                      textSize: 14.sp,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            );
    },
  );
}

Future<bool> quickLogin(context, String phoneNumber, String password) async {
  RestDataSource _request = new RestDataSource();
  bool res = await _request
      .login(context, phoneNumber: getMsisdn(phoneNumber), password: password)
      .then((Map response) async {
    if (response[Constants.success]) {
      return true;
    } else {
      return false;
    }
  });
  return res;
}

//Show Dialog to force users to re-login
showSessionExpiredDialog(context) async {
  bool _loading = false;
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  Color? bgColor = Colors.white;
  SharedPreferences _localStorage = await SharedPreferences.getInstance();

  bool? _allowBiometrics = _localStorage.getBool(Constants.allowBiometrics);
  var _showSessionExpired = _localStorage.getBool(Constants.showSessionExpired);
  var _localAuthKey;
  _localAuthKey = _localStorage.getString(Constants.localAuthKey);

  if (_showSessionExpired == null) {
    await _localStorage.setBool(Constants.showSessionExpired, true);
    final _formKey = GlobalKey<FormState>();
    final _phoneNumberController = TextEditingController();
    final _passwordController = TextEditingController();
    _phoneNumberController.text =
        getActualPhone(_localStorage.getString(Constants.localAuthPhone)!);
    showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              backgroundColor: bgColor,
              content: Stack(
                children: <Widget>[
                  _loading
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 30.w),
                              child: Center(
                                child: SizedBox(
                                  height: 50,
                                  width: 50,
                                  child: CircularLoader(
                                    loaderColor: Constants.kPrimaryColor,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.w, vertical: 10.h),
                                  child: GText(
                                    textData:
                                        "Oops! Your login session has expired. "
                                        "Please enter your password to continue "
                                        "using the App",
                                    textSize: 12.sp,
                                    textColor: Constants.kPrimaryColor,
                                    textMaxLines: 5,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.w, vertical: 10.h),
                                  child: GText(
                                    textData: "Phone Number *",
                                    textSize: 12.sp,
                                    textColor: Constants.kPrimaryColor,
                                  ),
                                ),
                                TextFormField(
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  controller: _phoneNumberController,
                                  toolbarOptions: ToolbarOptions(
                                    paste: true,
                                    cut: true,
                                    copy: true,
                                    selectAll: true,
                                  ),
                                  validator: (value) => validatePhone(value!),
                                  onFieldSubmitted: (v) {
                                    FocusScope.of(context).nextFocus();
                                  },
                                  readOnly: true,
                                  style: circularTextStyle(),
                                  decoration: circularInputDecoration(
                                      title: "Phone Number",
                                      circularRadius: 10.w),
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                ),
                                if (_allowBiometrics != true)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10.w, vertical: 10.h),
                                        child: GText(
                                          textData: "Password*",
                                          textSize: 12.sp,
                                          textColor: Constants.kPrimaryColor,
                                        ),
                                      ),
                                      TextFormField(
                                        keyboardType: TextInputType.text,
                                        controller: _passwordController,
                                        textInputAction: TextInputAction.next,
                                        obscureText: true,
                                        toolbarOptions: ToolbarOptions(
                                          paste: false,
                                          cut: true,
                                          copy: true,
                                          selectAll: true,
                                        ),
                                        validator: (value) =>
                                            checkNull(value!, "Password"),
                                        onFieldSubmitted: (v) {
                                          FocusScope.of(context).nextFocus();
                                        },
                                        style: circularTextStyle(),
                                        decoration: circularInputDecoration(
                                            title: "Password",
                                            circularRadius: 10.w),
                                      ),
                                      Constants.kSizeHeight_10,
                                      buildElevatedButton(
                                        title: "Continue",
                                        borderRadius: 10.w,
                                        onPressed: () async {
                                          FocusScope.of(context)
                                              .requestFocus(FocusNode());
                                          final isValid =
                                              _formKey.currentState!.validate();
                                          if (!isValid) {
                                            HapticFeedback.vibrate();
                                            return;
                                          } else {
                                            setState(() {
                                              _loading = true;
                                              bgColor = Colors.white;
                                            });
                                            bool res = await quickLogin(
                                                context,
                                                _phoneNumberController.text,
                                                _passwordController.text);
                                            if (res == true) {
                                              showBasicsFlash(
                                                context,
                                                "Login successful. Thank you",
                                                textColor:
                                                    Constants.kWhiteColor,
                                                bgColor:
                                                    Constants.kGreenLightColor,
                                              );
                                              await _localStorage.remove(
                                                  Constants.showSessionExpired);
                                              Navigator.pop(context);
                                            } else {
                                              HapticFeedback.vibrate();
                                              setState(() {
                                                _loading = false;
                                                bgColor = Colors.pink[50];
                                              });
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                Constants.kSizeHeight_10,
                                if (_allowBiometrics == true)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      localAuthOutlinedButton(
                                          onPressed: () async {
                                        bool _authenticated = false;
                                        try {
                                          final List<BiometricType>
                                              availableBiometrics =
                                              await _localAuthentication
                                                  .getAvailableBiometrics();

                                          if (availableBiometrics.isNotEmpty) {
                                            _authenticated =
                                                await _localAuthentication
                                                    .authenticate(
                                              localizedReason:
                                                  'Please authenticate to access your account',
                                              options:
                                                  const AuthenticationOptions(
                                                      stickyAuth: false,
                                                      useErrorDialogs: false,
                                                      biometricOnly: true),
                                            );

                                            if (_authenticated) {
                                              var _decryptedPass =
                                                  await Aes.decrypt(
                                                      _localAuthKey);
                                              setState(() {
                                                if (_localAuthKey != null)
                                                  _passwordController.text =
                                                      _decryptedPass;
                                              });

                                              ///
                                              setState(() {
                                                _loading = true;
                                                bgColor = Colors.white;
                                              });
                                              bool res = await quickLogin(
                                                  context,
                                                  _phoneNumberController.text,
                                                  _passwordController.text);
                                              if (res == true) {
                                                showBasicsFlash(
                                                  context,
                                                  "Login successful. Thank you",
                                                  textColor:
                                                      Constants.kWhiteColor,
                                                  bgColor: Constants
                                                      .kGreenLightColor,
                                                );
                                                await _localStorage.remove(
                                                    Constants
                                                        .showSessionExpired);
                                                Navigator.pop(context);
                                              } else {
                                                HapticFeedback.vibrate();
                                                setState(() {
                                                  _loading = false;
                                                  bgColor = Colors.pink[50];
                                                });
                                              }
                                            }
                                          } else {
                                            setState(() {
                                              _allowBiometrics = false;
                                            });
                                            return;
                                          }
                                        } on PlatformException catch (e) {
                                          debugPrint(e.toString());
                                        } catch (e) {
                                          debugPrint(e.toString());
                                        }
                                      }),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
            );
          });
        });
  }
}

Future optionIosDialog(BuildContext context, {optionTitle}) async {
  return await showCupertinoModalPopup(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return CupertinoActionSheet(
        actions: <Widget>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context, Constants.delete);
            },
            isDefaultAction: true,
            child: GText(
              textData: optionTitle ?? "Delete",
              textSize: 14.sp,
              textColor: Constants.kPrimaryColor,
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(context).pop();
          },
          isDefaultAction: true,
          child: GText(
            textData: "Cancel",
            textSize: 14.sp,
            textColor: Constants.kRedColor,
          ),
        ),
      );
    },
  );
}

Future optionAndroidDialog(BuildContext context, {optionTitle}) async {
  return await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        children: <Widget>[
          SimpleDialogOption(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            onPressed: () {
              Navigator.pop(context, Constants.delete);
            },
            child: GText(
              textData: optionTitle ?? "Delete",
              textSize: 14.sp,
              textColor: Constants.kPrimaryColor,
              textAlign: TextAlign.center,
            ),
          ),
          Divider(color: Constants.kPrimaryColor),
          SimpleDialogOption(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: GText(
              textData: "Cancel",
              textSize: 14.sp,
              textColor: Constants.kRedColor,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    },
  );
}
