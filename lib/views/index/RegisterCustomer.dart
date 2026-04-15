import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/CustomClippers.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/helpers/TextFields.dart';
import 'package:gwcl/models/Customer.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/index/OtpConfirmation.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../mixpanel.dart';

class RegisterCustomer extends StatefulWidget {
  static const String id = "/register_customer";

  @override
  _RegisterCustomerState createState() => _RegisterCustomerState();
}

class _RegisterCustomerState extends State<RegisterCustomer> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  bool _loading = false, _secureText = true, _showAppBar = true;

  void _submitForm() async {
    FocusScope.of(context).requestFocus(FocusNode());
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      if (mounted) setState(() => this._showAppBar = !this._showAppBar);
      HapticFeedback.vibrate();
      return;
    } else {
      setState(() => _loading = true);
      String appSignature = await SmsAutoFill().getAppSignature;
      Map deviceInfo = await getDeviceInfo();
      RestDataSource _request = new RestDataSource();

      _request
          .register(context,
              name: _nameController.text,
              deviceId: deviceInfo.values.toList()[0],
              devicePlatform: deviceInfo.values.toList()[1],
              phoneNumber: getMsisdn(_phoneNumberController.text),
              password: _passwordController.text,
              appSignature: appSignature)
          .then((Map response) async {
        if (mounted) setState(() => _loading = false);
        if (response[Constants.success]) {
          mixpanel?.track('User Created New Account');
          _onRegisterSuccess(response[Constants.response], appSignature);
        } else {
          _onRegisterFailed(response[Constants.message]);
        }
      });
    }
  }

  _showHide() {
    setState(() {
      _secureText = !_secureText;
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
          preferredSize: Size.fromHeight(1.h),
          child: LightHeader(),
        ),
        body: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Container(
            child: Column(
              children: <Widget>[
                Container(
                  height: 80.h,
                  child: ClipPath(
                    clipper: OvalBottomBorderClipper(),
                    child: Container(
                      color: Constants.kWhiteColor,
                      padding: EdgeInsets.only(left: 34.w, right: 20.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Let’s get started!",
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).primaryColor),
                          ),
                          Constants.kSizeHeight_10,
                          IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black87,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                FocusScope.of(context).requestFocus(FocusNode());
                                Navigator.pop(context);
                              },
                              icon: Icon(Icons.arrow_back)),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Text(
                    "Sign up today and take the first step towards a seamless bill payment experience.",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Constants.indexHorizontalSpace,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Constants.kSizeHeight_20,
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 7.w),
                                child: GText(
                                  textData: "Enter your name *",
                                  textSize: 12.sp,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 7.w),
                                child: GText(
                                  textData: "Name should not be more than 20 characters",
                                  textSize: 10.sp,
                                ),
                              ),
                              Constants.kSizeHeight_10,
                              TextFormField(
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                controller: _nameController,

                                // maxLength: 20,
                                validator: (value) => checkNull(value!, "Your name"),
                                onFieldSubmitted: (v) {
                                  FocusScope.of(context).nextFocus();
                                },
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                    RegExp("[a-zA-Z-.' ]"),
                                  ),
                                  LengthLimitingTextInputFormatter(20),
                                ],
                                style: circularTextStyle(),
                                decoration: circularInputDecoration(
                                  title: "Name",
                                  counterColor: Constants.kWhiteColor,
                                  errorTextColor: Constants.kWarningColor,
                                ),
                              ),
                              Constants.kSizeHeight_20,
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 7.w),
                                child: GText(
                                  textData: "Phone Number *",
                                  textSize: 12.sp,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 7.w),
                                child: GText(
                                  textData: "Kindly enter a valid phone number",
                                  textSize: 10.sp,
                                  textMaxLines: 4,
                                ),
                              ),
                              Constants.kSizeHeight_10,
                              TextFormField(
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                controller: _phoneNumberController,
                                validator: (value) => validatePhone(value!),
                                onFieldSubmitted: (v) {
                                  FocusScope.of(context).nextFocus();
                                },
                                style: circularTextStyle(),
                                decoration: circularInputDecoration(
                                  title: "Phone Number",
                                  errorTextColor: Constants.kWarningColor,
                                ),
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                              ),
                              Constants.kSizeHeight_20,
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 7.w),
                                child: GText(
                                  textData: "Create New Password *",
                                  textSize: 12.sp,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 7.w),
                                child: GText(
                                  textData: "New password must not be "
                                      "less than 6 characters",
                                  textSize: 10.sp,
                                ),
                              ),
                              Constants.kSizeHeight_10,
                              TextFormField(
                                keyboardType: TextInputType.text,
                                controller: _passwordController,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value!.length < 6)
                                    return "Password must be at "
                                        "least 6 characters";
                                  return null;
                                },
                                obscureText: _secureText,
                                onFieldSubmitted: (v) {
                                  FocusScope.of(context).nextFocus();
                                },
                                style: circularTextStyle(),
                                decoration: circularInputDecoration(
                                  title: "New Password",
                                  errorTextColor: Constants.kWarningColor,
                                  suffixIconButton: IconButton(
                                    onPressed: _showHide,
                                    icon: Icon(_secureText ? Icons.visibility_off : Icons.visibility),
                                  ),
                                ),
                              ),
                              Constants.kSizeHeight_20,
                              buildElevatedButton(
                                title: "Continue",
                                bgColor: Constants.kPrimaryColor,
                                textColor: Constants.kWhiteColor,
                                onPressed: () {
                                  _submitForm();
                                },
                              ),
                              Constants.kSizeHeight_20,
                            ],
                          ),
                        ),
                        Constants.kSizeHeight_50,
                        Constants.kSizeHeight_50,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _onRegisterFailed(dynamic errorText) {
    String _error;
    if (errorText is String) {
      _error = errorText;
    } else {
      _error = "${errorText["phone_number"] ?? '${Constants.somethingWentWrong}'}";
    }
    print(_error);
    showDialog(
      context: context,
      builder: (_) => ErrorDialog(
        content: errorText.toString().replaceAll(RegExp(Constants.errorFilter), ""),
      ),
    );
    // showBasicsFlash(
    //   context,
    //   _error.toString().replaceAll(RegExp(Constants.errorFilter), ""),
    //   textColor: Constants.kWhiteColor,
    //   bgColor: Constants.kRedLightColor,
    // );
  }

  _onRegisterSuccess(Customer customer, String appSignature) async {
    var _localDb = new LocalDatabase();
    await _localDb.saveCustomer(customer);
    Navigator.of(context).pushNamedAndRemoveUntil(OtpConfirmation.id, (Route<dynamic> route) => false);
  }
}
