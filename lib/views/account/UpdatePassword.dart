import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gwcl/helpers/AES.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/helpers/TextFields.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdatePassword extends StatefulWidget {
  static const String id = "/update_password";
  @override
  _UpdatePasswordState createState() => _UpdatePasswordState();
}

class _UpdatePasswordState extends State<UpdatePassword> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false, _secureText = true, _secureOldPasswordText = true;

  _showHide() {
    setState(() => _secureText = !_secureText);
  }

  _showHideOldPassword() {
    setState(() => _secureOldPasswordText = !_secureOldPasswordText);
  }

  void _submitForm() async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).requestFocus(FocusNode());
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    var _oldPassword = _localStorage.getString(Constants.localAuthKey);
    var _decryptedPass = await Aes.decrypt(_oldPassword!);
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      HapticFeedback.vibrate();
      return;
    } else if (_oldPasswordController.text != _decryptedPass) {
      HapticFeedback.vibrate();
      _onRequestFailed("Old password provided is wrong");
    } else if (_passwordController.text != _confirmPasswordController.text) {
      HapticFeedback.vibrate();
      _onRequestFailed("Your new passwords do not match");
    } else {
      showDialog(
        context: context,
        builder: (_) => ConfirmDialog(
          title: "Confirm Action",
          content: "Are you sure you want to change your password?",
          confirmText: "Confirm",
          confirmTextColor: Constants.kPrimaryColor,
          confirm: () => _proceedToChangePassword(),
        ),
      );
    }
  }

  _proceedToChangePassword() {
    setState(() => _loading = true);
    RestDataSource _request = new RestDataSource();
    _request.post(
      context,
      url: Endpoints.account_change_password,
      data: {"password": _passwordController.text},
    ).then((Map response) async {
      if (response[Constants.success]) {
        _onRequestSuccess();
      } else {
        if (mounted) setState(() => _loading = false);
        _onRequestFailed(response[Constants.message]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _loading,
      color: Constants.kWhiteColor.withOpacity(0.8),
      opacity: 0.5,
      progressIndicator: CircularLoader(
        loaderColor: Constants.kPrimaryColor,
      ),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70.h),
          child: Container(
            color: Constants.kPrimaryColor,
            child: GeneralHeader(
                title: "Change Password",
            ),
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: Constants.kBgTwo,
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.linearToSrgbGamma()),
              ),
            ),
            SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Constants.indexHorizontalSpace,
                  vertical: Constants.indexVerticalSpace,
                ),
                child: Column(children: <Widget>[
                  Constants.kSizeHeight_10,
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 10.h),
                          child: GText(
                            textData: "Old Password *",
                            textSize: 12.sp,
                            textColor: Constants.kPrimaryColor,
                          ),
                        ),
                        TextFormField(
                          keyboardType: TextInputType.text,
                          controller: _oldPasswordController,
                          textInputAction: TextInputAction.next,
                          toolbarOptions: ToolbarOptions(
                            paste: true,
                            cut: true,
                            copy: true,
                            selectAll: true,
                          ),
                          validator: (value) =>
                              checkNull(value!, "Old password"),
                          obscureText: _secureOldPasswordText,
                          onFieldSubmitted: (v) {
                            FocusScope.of(context).nextFocus();
                          },
                          style: TextStyle(fontSize: 16.sp),
                          decoration: circularInputDecoration(
                            title: "Old Password",
                            suffixIconButton: IconButton(
                              onPressed: _showHideOldPassword,
                              icon: Icon(_secureOldPasswordText
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                            ),
                          ),
                        ),
                        Constants.kSizeHeight_10,
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 10.h),
                          child: GText(
                            textData: "New Password *",
                            textSize: 12.sp,
                            textColor: Constants.kPrimaryColor,
                          ),
                        ),
                        TextFormField(
                          keyboardType: TextInputType.text,
                          controller: _passwordController,
                          textInputAction: TextInputAction.next,
                          obscureText: _secureText,
                          toolbarOptions: ToolbarOptions(
                            paste: false,
                            cut: false,
                            copy: false,
                            selectAll: false,
                          ),
                          validator: (value) {
                            if (value!.length < 6)
                              return "New password must be at "
                                  "least 6 characters";
                            return null;
                          },
                          onFieldSubmitted: (v) {
                            FocusScope.of(context).nextFocus();
                          },
                          style: TextStyle(fontSize: 16.sp),
                          decoration: circularInputDecoration(
                            title: "New Password",
                            suffixIconButton: IconButton(
                              onPressed: _showHide,
                              icon: Icon(_secureText
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                            ),
                          ),
                        ),
                        Constants.kSizeHeight_10,
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 10.h),
                          child: GText(
                            textData: "Confirm Password *",
                            textSize: 12.sp,
                            textColor: Constants.kPrimaryColor,
                          ),
                        ),
                        TextFormField(
                          keyboardType: TextInputType.text,
                          controller: _confirmPasswordController,
                          textInputAction: TextInputAction.next,
                          obscureText: true,
                          toolbarOptions: ToolbarOptions(
                            paste: true,
                            cut: true,
                            copy: true,
                            selectAll: true,
                          ),
                          validator: (value) {
                            if (value!.length < 6)
                              return "Password must be at "
                                  "least 6 characters";
                            return null;
                          },
                          onFieldSubmitted: (v) {
                            FocusScope.of(context).nextFocus();
                          },
                          style: TextStyle(fontSize: 16.sp),
                          decoration: circularInputDecoration(
                            title: "Confirm Password",
                          ),
                        ),
                        Constants.kSizeHeight_20,
                        buildElevatedButton(
                            title: "Submit",
                            onPressed: () {
                              _submitForm();
                            }),
                        Constants.kSizeHeight_5,
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _onRequestSuccess() async {
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    var _encryptedPass = await Aes.encrypt(_passwordController.text);
    _localStorage.setString(Constants.localAuthKey, _encryptedPass);
    if (mounted) {
      setState(() => _loading = false);
      Navigator.pop(context, true);
    }
  }

  _onRequestFailed(dynamic errorText) async {
    showDialog(
      context: context,
      builder: (_) => ErrorDialog(
        content:
            errorText.toString().replaceAll(RegExp(Constants.errorFilter), ""),
      ),
    );
    // showBasicsFlash(
    //   context,
    //   errorText.toString().replaceAll(RegExp(Constants.errorFilter), ""),
    //   textColor: Constants.kWhiteColor,
    //   bgColor: Constants.kRedLightColor,
    // );
  }
}
