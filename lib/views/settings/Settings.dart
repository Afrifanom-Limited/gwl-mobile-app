import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/CustomExpansionTile.dart' as custom;
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/FlashHelper.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/models/Customer.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/account/EditEmailAddress.dart';
import 'package:gwcl/views/account/EditGPGPS.dart';
import 'package:gwcl/views/account/EditPhoneNumber.dart';
import 'package:gwcl/views/account/UpdatePassword.dart';
import 'package:gwcl/views/home/Home.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  static const String id = "/settings";
  final dynamic customer;
  const Settings({Key? key, required this.customer}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  var _customer;
  bool _loading = false;

  _setCustomerInfo() {
    // if (widget.customer != null) {
    //   setState(() => _customer = widget.customer);
    //   _loadCustomerInfo();
    // } else {
    //   _loadCustomerInfo();
    // }
    _loadCustomerInfo();
  }

  _loadCustomerInfo() async {
    setState(() => _loading = true);
    var _localDb = new LocalDatabase();
    var _res = await _localDb.getCustomer();
    if (mounted) {
      setState(() {
        _customer = _res;
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    _setCustomerInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Home(index: 0)), (route) => false);
        return new Future(() => false);
      },
      child: ModalProgressHUD(
        inAsyncCall: _loading,
        color: Constants.kWhiteColor.withOpacity(0.8),
        opacity: 0.5,
        progressIndicator: CircularLoader(
          loaderColor: Constants.kPrimaryColor,
        ),
        child: _customer == null
            ? Container()
            : Scaffold(
                body: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Container(
                    color: Constants.kWhiteColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        ProfileHeader(
                          avatar: Constants.kProfileIcon,
                          title: "${_customer["name"]}",
                          subtitle: "${_customer["is_phone_verified"].toString()}",
                        ),
                        Constants.kSizeHeight_10,
                        UserInfo(
                          name: "${_customer["name"]}",
                          phoneNumber: "${_customer["phone_number"]}",
                          digitalAddress: "${_customer["digital_address"]}",
                          email: "${_customer["email"]}",
                          isPhoneVerified: "${_customer["is_phone_verified"].toString()}",
                        ),
                        Constants.kSizeHeight_10,
                        AppSettings(
                          allowEmail: "${_customer["allow_email"]}",
                          allowPush: "${_customer["allow_push"]}",
                          allowSms: "${_customer["allow_sms"]}",
                        ),
                        Constants.kSizeHeight_10,
                        SecuritySettings(),
                        Constants.kSizeHeight_20,
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          child: OutlinedButton(
                            style: ButtonStyle(
                              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.w),
                                  side: BorderSide(
                                    width: 2,
                                    color: Constants.kRedColor,
                                  ),
                                ),
                              ),
                            ),
                            child: ListTile(
                              title: GText(
                                textData: "Sign Out",
                                textColor: Constants.kRedColor,
                                textSize: 13.sp,
                              ),
                              trailing: Icon(
                                Icons.power_settings_new,
                                size: 18.w,
                                color: Constants.kRedColor,
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              showDialog(
                                context: context,
                                builder: (_) => ConfirmDialog(
                                  title: "Sign out?",
                                  content: "You will be logged out from your account. "
                                      "All cached data will be cleared. Biometric "
                                      "authentication will be disabled.",
                                  confirmText: "Sign Out",
                                  confirmTextColor: Colors.red,
                                  confirm: () => logout(context),
                                ),
                              );
                            },
                          ),
                        ),
                        Constants.kSizeHeight_50,
                        Constants.kSizeHeight_50,
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final AssetImage image;
  final Color borderColor;
  final Color? backgroundColor;
  final double radius;
  final double borderWidth;

  const Avatar({Key? key, required this.image, this.borderColor = Colors.grey, this.backgroundColor, this.radius = 30, this.borderWidth = 5}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius + borderWidth,
      backgroundColor: borderColor,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor != null ? backgroundColor : Constants.kPrimaryColor,
        child: CircleAvatar(
          radius: radius - borderWidth,
          backgroundImage: image,
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final AssetImage avatar;
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const ProfileHeader({
    Key? key,
    required this.avatar,
    required this.title,
    this.subtitle,
    this.actions,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        if (actions != null)
          Container(
            width: double.infinity,
            height: 80.h,
            padding: const EdgeInsets.only(bottom: 0.0, right: 0.0),
            alignment: Alignment.bottomRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            ),
          ),
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 40.h),
          child: Column(
            children: <Widget>[
              Avatar(
                image: avatar,
                radius: 40,
                backgroundColor: Colors.white,
                borderColor: Colors.grey.shade300,
                borderWidth: 4.0,
              ),
              GText(
                textData: title,
                textSize: 16.sp,
                textFont: Constants.kFontMedium,
              ),
              if (subtitle != null) ...[
                Constants.kSizeHeight_5,
                if (subtitle == 'false')
                  GText(
                    textData: "Your phone number is not verified",
                    textSize: 10.sp,
                    textFont: Constants.kFontLight,
                    textColor: Colors.red,
                  )
              ]
            ],
          ),
        )
      ],
    );
  }
}

class UserInfo extends StatefulWidget {
  final String name, phoneNumber, isPhoneVerified;
  final String email, digitalAddress;
  const UserInfo({
    Key? key,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.digitalAddress,
    required this.isPhoneVerified,
  }) : super(key: key);

  @override
  _UserInfoState createState() => _UserInfoState();
}

class _UserInfoState extends State<UserInfo> {
  String _phoneNumber = "", _email = "", _digitalAddress = "";
  _navigateAndReturnValue(BuildContext context, Widget widget, String fieldName) async {
    dynamic _result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => widget),
    );
    if (_result == true) {
      _loadCustomerInfo();
      showBasicsFlash(
        context,
        "$fieldName has been updated successfully",
        textColor: Constants.kWhiteColor,
        bgColor: Constants.kGreenLightColor,
      );
    }
  }

  _loadCustomerInfo() async {
    var _localDb = new LocalDatabase();
    var res = await _localDb.getCustomer();
    setState(() {
      this._phoneNumber = res['phone_number'].toString();
      this._email = res['email'].toString();
      this._digitalAddress = res['digital_address'].toString();
    });
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      this._phoneNumber = widget.phoneNumber;
      this._email = widget.email;
      this._digitalAddress = widget.digitalAddress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Theme(
        data: ThemeData().copyWith(
          dividerColor: Colors.transparent,
          colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Constants.kAccentColor),
        ),
        child: custom.ExpansionTile(
          headerBackgroundColor: Constants.kPrimaryLightColor,
          iconColor: Constants.kWarningColor,
          initiallyExpanded: true,
          title: GText(
            textData: "ACCOUNT",
            textMaxLines: 2,
            textSize: 14.sp,
            textColor: Constants.kPrimaryColor,
            textFont: Constants.kFontMedium,
          ),
          children: <Widget>[
            Column(
              children: <Widget>[
                ...ListTile.divideTiles(
                  color: Colors.grey,
                  tiles: [
                    ListTile(
                      title: GText(
                        textData: "Name",
                        textSize: 12.sp,
                      ),
                      subtitle: Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.h),
                        child: GText(
                          textData: "${widget.name}",
                          textSize: 13.sp,
                          textColor: Constants.kPrimaryColor,
                        ),
                      ),
                    ),
                    ListTile(
                      title: GText(
                        textData: "Phone Number",
                        textSize: 12.sp,
                      ),
                      subtitle: Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.h),
                        child: Row(
                          children: [
                            GText(
                              textData: "${getActualPhone(this._phoneNumber)}",
                              textSize: 13.sp,
                              textColor: Constants.kPrimaryColor,
                            ),
                            Constants.kSizeWidth_5,
                            if (widget.isPhoneVerified == "false")
                              Icon(
                                Icons.warning_amber_outlined,
                                color: Constants.kWarningColor,
                                size: 16.w,
                              )
                          ],
                        ),
                      ),
                      trailing: InkWell(
                        child: Icon(
                          Icons.edit,
                          color: Constants.kPrimaryColor,
                        ),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _navigateAndReturnValue(
                            context,
                            EditPhoneNumber(
                              phoneNumber: getActualPhone(this._phoneNumber),
                              navigateToHome: false,
                              verifyMomo: false,
                            ),
                            "Phone Number",
                          );
                        },
                      ),
                    ),
                    ListTile(
                      title: GText(
                        textData: "Email Address",
                        textSize: 12.sp,
                      ),
                      subtitle: Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.h),
                        child: GText(
                          textData: "${this._email != "null" ? this._email : "Not set"}",
                          textSize: 13.sp,
                          textColor: Constants.kPrimaryColor,
                        ),
                      ),
                      trailing: InkWell(
                        child: Icon(
                          Icons.edit,
                          color: Constants.kPrimaryColor,
                        ),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _navigateAndReturnValue(
                            context,
                            EditEmailAddress(
                              emailAddress: this._email,
                            ),
                            "Email Address",
                          );
                        },
                      ),
                    ),
                    ListTile(
                      title: GText(
                        textData: "Digital Address",
                        textSize: 12.sp,
                      ),
                      subtitle: Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.h),
                        child: GText(
                          textData: "${this._digitalAddress != "null"
                              "" ? formatDigitalAddress(this._digitalAddress) : "Not provided"}",
                          textSize: 13.sp,
                          textColor: Constants.kPrimaryColor,
                        ),
                      ),
                      trailing: InkWell(
                        child: Icon(
                          Icons.edit,
                          color: Constants.kPrimaryColor,
                        ),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _navigateAndReturnValue(
                            context,
                            EditGPGPS(
                              gpgps: this._digitalAddress,
                            ),
                            "Digital Address",
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class AppSettings extends StatefulWidget {
  final String allowPush, allowSms, allowEmail;

  const AppSettings({
    Key? key,
    required this.allowPush,
    required this.allowSms,
    required this.allowEmail,
  }) : super(key: key);
  @override
  _AppSettingsState createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings> {
  String _togglePushNotification = 'true', _toggleSmsNotification = 'false', _toggleEmailNotification = 'false';

  _loadToggleOptions() async {
    setState(() {
      _togglePushNotification = widget.allowPush;
      _toggleSmsNotification = widget.allowSms;
      _toggleEmailNotification = widget.allowEmail;
    });
  }

  _updateAAppSettings() async {
    RestDataSource _request = new RestDataSource();
    _request.post(
      context,
      url: Endpoints.account_edit,
      data: {
        "allow_push": this._togglePushNotification,
        "allow_sms": this._toggleSmsNotification,
        "allow_email": this._toggleEmailNotification,
      },
    ).then((Map response) async {
      if (response[Constants.success]) {
        Customer _customerData;
        _customerData = Customer.map(response[Constants.response]);
        var _localDb = new LocalDatabase();
        await _localDb.updateCustomer(_customerData);
      } else {
        showBasicsFlash(context, Constants.unableToSendRequest, textColor: Constants.kWhiteColor, bgColor: Constants.kWarningLightColor);
      }
    });
  }

  @override
  void initState() {
    _loadToggleOptions();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Theme(
        data: ThemeData().copyWith(
          dividerColor: Colors.transparent,
          colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Constants.kAccentColor),
        ),
        child: custom.ExpansionTile(
          headerBackgroundColor: Constants.kPrimaryLightColor,
          iconColor: Constants.kWarningColor,
          initiallyExpanded: true,
          title: GText(
            textData: "NOTIFICATION",
            textMaxLines: 2,
            textSize: 14.sp,
            textColor: Constants.kPrimaryColor,
            textFont: Constants.kFontMedium,
          ),
          children: <Widget>[
            Column(
              children: <Widget>[
                ...ListTile.divideTiles(
                  color: Colors.grey,
                  tiles: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: SwitchListTile(
                        activeColor: Constants.kPrimaryColor,
                        contentPadding: const EdgeInsets.all(0),
                        value: _togglePushNotification == 'true' ? true : false,
                        title: GText(
                          textData: "Push Notifications",
                          textSize: 12.sp,
                        ),
                        onChanged: (val) => setState(() {
                          _togglePushNotification = val.toString();
                          _updateAAppSettings();
                        }),
                        inactiveTrackColor: Colors.grey,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: SwitchListTile(
                        activeColor: Constants.kPrimaryColor,
                        contentPadding: const EdgeInsets.all(0),
                        value: _toggleEmailNotification == 'true' ? true : false,
                        title: GText(
                          textData: "Email Notifications",
                          textSize: 12.sp,
                        ),
                        inactiveTrackColor: Colors.grey,
                        onChanged: (val) => setState(() {
                          _toggleEmailNotification = val.toString();
                          _updateAAppSettings();
                        }),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: SwitchListTile(
                        activeColor: Constants.kPrimaryColor,
                        contentPadding: const EdgeInsets.all(0),
                        value: _toggleSmsNotification == 'true' ? true : false,
                        title: GText(
                          textData: "SMS Notifications",
                          textSize: 12.sp,
                        ),
                        inactiveTrackColor: Colors.grey,
                        onChanged: (val) => setState(() {
                          _toggleSmsNotification = val.toString();
                          _updateAAppSettings();
                        }),
                      ),
                    )
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class SecuritySettings extends StatefulWidget {
  @override
  _SecuritySettingsState createState() => _SecuritySettingsState();
}

class _SecuritySettingsState extends State<SecuritySettings> {
  bool _toggleBiometrics = false, _biometricsAvailability = false;

  _loadToggleOption() async {
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    bool? _allowBiometrics = _localStorage.getBool(Constants.allowBiometrics);
    bool? _biometricsAvailability = _localStorage.getBool(Constants.biometricsAvailability);
    _reDefineAllowBiometricBoolean(_allowBiometrics ?? false, checkBioAvailability: _biometricsAvailability);
  }

  _reDefineAllowBiometricBoolean(bool response, {bool? checkBioAvailability}) {
    if (response) {
      setState(() => this._toggleBiometrics = true);
    } else {
      setState(() => this._toggleBiometrics = false);
    }

    if (checkBioAvailability == null) {
      setState(() => this._biometricsAvailability = false);
    } else {
      setState(() => this._biometricsAvailability = true);
    }
  }

  _toggleAllowBiometric(selectedValue) async {
    try {
      SharedPreferences _localStorage = await SharedPreferences.getInstance();
      if (selectedValue) {
        await _localStorage.setBool(Constants.allowBiometrics, this._toggleBiometrics);
        setState(() => this._toggleBiometrics = true);
      } else {
        await _localStorage.remove(Constants.allowBiometrics);
        setState(() => this._toggleBiometrics = false);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  _navigateAndReturnValue(BuildContext context, Widget widget, String fieldName) async {
    dynamic _result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => widget),
    );
    if (_result == true) {
      showBasicsFlash(context, "$fieldName has been updated successfully", textColor: Constants.kWhiteColor, bgColor: Constants.kGreenLightColor);
    }
  }

  @override
  void initState() {
    _loadToggleOption();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Theme(
        data: ThemeData().copyWith(
          dividerColor: Colors.transparent,
          colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Constants.kAccentColor),
        ),
        child: custom.ExpansionTile(
          headerBackgroundColor: Constants.kPrimaryLightColor,
          iconColor: Constants.kWarningColor,
          initiallyExpanded: true,
          title: GText(
            textData: "SECURITY",
            textMaxLines: 2,
            textSize: 14.sp,
            textColor: Constants.kPrimaryColor,
            textFont: Constants.kFontMedium,
          ),
          children: <Widget>[
            Column(
              children: <Widget>[
                ...ListTile.divideTiles(
                  color: Colors.grey,
                  tiles: [
                    if (_biometricsAvailability)
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                          child: SwitchListTile(
                            activeColor: Constants.kPrimaryColor,
                            contentPadding: const EdgeInsets.all(0),
                            value: _toggleBiometrics,
                            title: Row(
                              children: [
                                GText(
                                  textData: "Use Biometric Authentication",
                                  textSize: 12.sp,
                                ),
                              ],
                            ),
                            inactiveTrackColor: Colors.grey,
                            subtitle: Padding(
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                              child: GText(textData: "Enable fingerprint (or FaceID) authentication"),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _toggleBiometrics = val;
                                _toggleAllowBiometric(val);
                              });
                            },
                          )),
                    Constants.kSizeHeight_5,
                    ListTile(
                      title: GText(
                        textData: "Change Password",
                        textSize: 12.sp,
                      ),
                      trailing: Icon(Icons.keyboard_arrow_right),
                      onTap: () {
                        _navigateAndReturnValue(
                          context,
                          UpdatePassword(),
                          "Password",
                        );
                      },
                    ),
                    Divider(),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
