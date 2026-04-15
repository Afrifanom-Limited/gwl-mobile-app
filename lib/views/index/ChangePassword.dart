import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/FlashHelper.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/helpers/TextFields.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChangePassword extends StatefulWidget {
  static const String id = "/change_password";
  final String msisdn;
  const ChangePassword({Key? key, required this.msisdn}) : super(key: key);
  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false, _secureText = true;

  _showHide() {
    setState(() {
      _secureText = !_secureText;
    });
  }

  void _submitForm() async {
    FocusScope.of(context).requestFocus(FocusNode());
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      HapticFeedback.vibrate();
      return;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      HapticFeedback.vibrate();
      _onRequestFailed("Your new passwords do not match");
    } else {
      setState(() => _loading = true);
      RestDataSource _request = new RestDataSource();
      _request.post(
        context,
        url: Endpoints.account_reset_password,
        data: {
          "password": _passwordController.text,
          "phone_number": widget.msisdn
        },
      ).then((Map response) async {
        if (mounted) setState(() => _loading = false);
        if (response[Constants.success]) {
          _onRequestSuccess();
        } else {
          _onRequestFailed(response[Constants.message]);
        }
      });
    }
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
              title: "New Password",
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
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                    child: GText(
                      textData: "Create a new password for "
                          "your account. Your new password must "
                          "not be less than 6 characters",
                      textFont: Constants.kFontLight,
                      textSize: 14.sp,
                      textMaxLines: 4,
                    ),
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
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
                            paste: true,
                            cut: true,
                            copy: true,
                            selectAll: true,
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
                            paste: false,
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
                            title: "Proceed",
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
    try {
      showBasicsFlash(
        context,
        "Password reset was successful",
        textColor: Constants.kWhiteColor,
        bgColor: Constants.kGreenLightColor,
        duration: Duration(seconds: 6),
      );
      Navigator.pop(context, true);
    } catch (e) {
      // print(e.toString());
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
