import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/AES.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/PageTransitions.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/helpers/TextFields.dart';
import 'package:gwcl/models/Customer.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/home/Home.dart';
import 'package:gwcl/views/index/ForceVerifyPhoneNumber.dart';
import 'package:gwcl/views/index/ForgotPassword.dart';
import 'package:local_auth/local_auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../mixpanel.dart';

enum _SupportState {
  unknown,
  supported,
  unsupported,
}

class Login extends StatefulWidget {
  static const String id = "/login";
  final bool isLoggedIn;

  const Login({Key? key, this.isLoggedIn = false}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  _SupportState _supportState = _SupportState.unknown;

  final _formKey = GlobalKey<FormState>();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false, _secureText = true, _canCheckIfBiometricsExists = false;
  var _localAuthKey;

  void _submitForm() async {
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    HapticFeedback.lightImpact();
    FocusScope.of(context).requestFocus(FocusNode());
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      HapticFeedback.vibrate();
      return;
    } else {
      setState(() => _loading = true);
      RestDataSource _request = new RestDataSource();

      mixpanel?.track('User Submit Login');

      _request.login(context, phoneNumber: getMsisdn(_phoneNumberController.text), password: _passwordController.text).then((Map response) async {
        if (response[Constants.success]) {
          mixpanel?.track('User Login Success');
          await _localStorage.remove(Constants.canUpdateMeter);
          await _localStorage.remove(Constants.canUpdateVendor);
          await _localStorage.remove(Constants.showSessionExpired);
          _onLoginSuccess(response[Constants.response]);
        } else {
          mixpanel?.track('User Login Failed', properties: {
            'errorMessage': response[Constants.message],
          });
          if (mounted)
            setState(() {
              _passwordController.text = "";
              _loading = false;
            });
          _onLoginFailed(response[Constants.message]);
        }
      });
    }
  }

  _showHide() {
    setState(() {
      _secureText = !_secureText;
    });
  }

  void _initLocalAuth() async {
    try {
      if (widget.isLoggedIn) {
        SharedPreferences _localStorage = await SharedPreferences.getInstance();
        setState(() {
          _phoneNumberController.text = getActualPhone(_localStorage.getString(Constants.localAuthPhone)!);
          _localAuthKey = _localStorage.getString(Constants.localAuthKey);
        });
      }

      _localAuthentication.isDeviceSupported().then(
            (isSupported) => setState(() {
              _supportState = isSupported ? _SupportState.supported : _SupportState.unsupported;
              if (isSupported) {
                if (widget.isLoggedIn) _autoAuthenticateWithBio();
              }
            }),
          );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  _autoAuthenticateWithBio() async {
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    bool? _allowBiometrics = _localStorage.getBool(Constants.allowBiometrics);
    if (_allowBiometrics == true) {
      _authenticateWithBiometrics();
    }
  }

  @override
  void initState() {
    super.initState();
    _initLocalAuth();
    _checkBiometricsAvailability();
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _loading,
      color: Constants.kWhiteColor.withValues(alpha: 0.8),
      opacity: 0.5,
      progressIndicator: CircularLoader(
        loaderColor: Constants.kPrimaryColor,
      ),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Constants.indexHorizontalSpace,
                vertical: Constants.indexVerticalSpace,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Login",
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Constants.kSizeHeight_10,
                        !widget.isLoggedIn
                            ? IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black87,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  FocusScope.of(context).requestFocus(FocusNode());
                                  Navigator.pop(context);
                                },
                                icon: Icon(Icons.arrow_back),
                              )
                            : Container(
                                margin: EdgeInsets.only(top: 2.h),
                                child: TextButton(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.account_circle,
                                        size: 18.sp,
                                        color: Constants.kWarningColor,
                                      ),
                                      Constants.kSizeWidth_5,
                                      GText(
                                        textData: "Switch User",
                                        textSize: 12.sp,
                                        textColor: Constants.kWarningColor,
                                        textFont: Constants.kFontMedium,
                                      ),
                                    ],
                                  ),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    FocusScope.of(context).requestFocus(FocusNode());
                                    showDialog(
                                      context: context,
                                      builder: (_) => ConfirmDialog(
                                        title: "Switch User?",
                                        content: "This allows you to login with a different user account."
                                            " Current user will be logged out.",
                                        confirmText: "Proceed",
                                        confirmTextColor: Colors.red,
                                        confirm: () => logout(context),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ],
                    ),
                  ),
                  Constants.kSizeHeight_20,
                  Text("Enter your phone number. We will send you a  confirmation code there."),
                  // Constants.kSizeHeight_10,
                  // Center(
                  //   child: Image(
                  //     image: Constants.kVectorOne,
                  //     height: 120.h,
                  //   ),
                  // ),
                  Constants.kSizeHeight_20,
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.h),
                          child: GText(
                            textData: "Phone Number *",
                            textSize: 12.sp,
                          ),
                        ),
                        TextFormField(
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          controller: _phoneNumberController,
                          validator: (value) => validatePhone(value!),
                          onFieldSubmitted: (v) {
                            FocusScope.of(context).nextFocus();
                          },
                          readOnly: widget.isLoggedIn,
                          style: circularTextStyle(),
                          decoration: circularInputDecoration(
                            title: "Phone Number",
                            fillColor: widget.isLoggedIn ? Constants.kGreenLightColor.withValues(alpha: 0.2) : null,
                          ),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.h),
                          child: GText(
                            textData: "Password*",
                            textSize: 12.sp,
                          ),
                        ),
                        TextFormField(
                          keyboardType: TextInputType.text,
                          controller: _passwordController,
                          textInputAction: TextInputAction.next,
                          obscureText: _secureText,
                          validator: (value) => checkNull(value!, "Password"),
                          onFieldSubmitted: (v) {
                            FocusScope.of(context).nextFocus();
                          },
                          style: circularTextStyle(),
                          decoration: circularInputDecoration(
                            title: "Password",
                            suffix: IconButton(
                              onPressed: _showHide,
                              icon: Icon(_secureText ? Icons.visibility_off : Icons.visibility),
                            ),
                          ),
                        ),
                        Constants.kSizeHeight_10,
                        Constants.kSizeHeight_5,
                        buildElevatedButton(
                          title: "Login",
                          onPressed: () {
                            _submitForm();
                          },
                        ),
                        Constants.kSizeHeight_10,
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (widget.isLoggedIn)
                                if ((_supportState == _SupportState.supported) && _canCheckIfBiometricsExists)
                                  localAuthOutlinedButton(onPressed: () async {
                                    SharedPreferences _localStorage = await SharedPreferences.getInstance();
                                    bool? _allowBiometrics = _localStorage.getBool(Constants.allowBiometrics);
                                    if (_allowBiometrics == true) {
                                      _authenticateWithBiometrics();
                                    } else {
                                      HapticFeedback.lightImpact();
                                      showDialog(
                                        context: context,
                                        builder: (_) => ConfirmDialog(
                                          title: "Biometric Login",
                                          content: "Eliminate the hassle of entering your "
                                              "password every time you want to login."
                                              " Would you like to use Fingerprint "
                                              "or FaceID instead?",
                                          confirmText: "Yes",
                                          confirmTextColor: Constants.kPrimaryColor,
                                          confirm: () {
                                            _localStorage.setBool(Constants.allowBiometrics, true);
                                            _authenticateWithBiometrics();
                                          },
                                        ),
                                      );
                                    }
                                  }),
                              Constants.kSizeHeight_10,
                              buildTextButton(
                                title: "Forgot your password?",
                                textColor: Constants.kPrimaryColor,
                                textSize: 12.sp,
                                onPressed: () {
                                  Navigator.pushNamed(context, ForgotPassword.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Constants.kSizeHeight_20,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _resendOtp({required String phoneNumber}) async {
    String appSignature = await SmsAutoFill().getAppSignature;
    RestDataSource _request = new RestDataSource();
    _request.post(
      context,
      url: Endpoints.send_otp_code,
      data: {"app_signature": appSignature, "phone_number": getMsisdn(_phoneNumberController.text)},
    ).then((Map response) async {
      if (mounted) setState(() => _loading = false);
      if (response[Constants.success]) {
        Navigator.pushReplacement(
          context,
          FadeRoute(
            page: ForceVerifyPhoneNumber(
              phoneNumber: phoneNumber,
              appSignature: appSignature,
              returnFunction: () {
                _proceedToHome();
              },
            ),
          ),
        );
      } else {
        _proceedToHome();
      }
    });
  }

  _onLoginFailed(dynamic errorText) {
    showDialog(
      context: context,
      builder: (_) => ErrorDialog(
        content: errorText.toString().replaceAll(RegExp(Constants.errorFilter), ""),
      ),
    );
    // showBasicsFlash(
    //   context,
    //   errorText.toString().replaceAll(RegExp(Constants.errorFilter), ""),
    //   textColor: Constants.kWhiteColor,
    //   bgColor: Constants.kRedLightColor,
    // );
  }

  _onLoginSuccess(Customer customer) async {
    var _localDb = new LocalDatabase();
    await _localDb.saveCustomer(customer);

    var _customer = await _localDb.getCustomer();
    if (mounted) {
      if (_customer["is_phone_verified"] == 'false') {
        _resendOtp(phoneNumber: _customer["phone_number"]);
      } else {
        setState(() => _loading = false);
        _proceedToHome();
      }
    }
  }

  _proceedToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(Home.id, (Route<dynamic> route) => false);
  }

  Future<void> _authenticateWithBiometrics() async {
    bool _authenticated = false;
    try {
      final List<BiometricType> availableBiometrics = await _localAuthentication.getAvailableBiometrics();

      if (availableBiometrics.isNotEmpty) {
        _authenticated = await _localAuthentication.authenticate(
          localizedReason: 'Please authenticate to access your account',
          options: const AuthenticationOptions(stickyAuth: false, useErrorDialogs: false, biometricOnly: true),
        );

        if (mounted && _authenticated) {
          var _decryptedPass = await Aes.decrypt(_localAuthKey);
          setState(() {
            if (_localAuthKey != null) _passwordController.text = _decryptedPass;
          });
          _submitForm();
        }
      } else {
        return;
      }
    } on PlatformException catch (e) {
      debugPrint(e.toString());
      return;
    } catch (e) {
      debugPrint(e.toString());
      return;
    }
  }

  Future<void> _checkBiometricsAvailability() async {
    bool _canCheckBiometrics = false;
    try {
      _canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
    } on PlatformException catch (e) {
      _canCheckBiometrics = false;
      debugPrint(e.toString());
      return;
    }
    if (!mounted) return;

    setState(() {
      _canCheckIfBiometricsExists = _canCheckBiometrics;
    });

    if (_canCheckIfBiometricsExists) {
      SharedPreferences _localStorage = await SharedPreferences.getInstance();
      await _localStorage.setBool(Constants.biometricsAvailability, true);
    }
  }
}
