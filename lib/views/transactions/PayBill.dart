import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/DropDownFormField.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/FlashHelper.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Menu.dart';
import 'package:gwcl/helpers/PageTransitions.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/helpers/TextFields.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/account/EditPhoneNumber.dart';
import 'package:gwcl/views/home/Home.dart';
import 'package:gwcl/views/index/ForceVerifyPhoneNumber.dart';
import 'package:gwcl/views/transactions/CardPaymentForm.dart';
import 'package:gwcl/views/transactions/PayBillSummary.dart';
import 'package:gwcl/views/transactions/SavedCards.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../mixpanel.dart';

class PayBill extends StatefulWidget {
  static const String id = "/pay_bill";
  final dynamic meter;
  final bool hasOldBalance;

  const PayBill({Key? key, this.meter, required this.hasOldBalance}) : super(key: key);

  @override
  _PayBillState createState() => _PayBillState();
}

class _PayBillState extends State<PayBill> {
  var _localDb = new LocalDatabase();
  final _formKey = GlobalKey<FormState>();
  final FocusNode _amountInputFieldFocus = FocusNode();
  final _mobileNumberController = TextEditingController();
  var _meters = List.empty(growable: true);
  String _meterId = "", _amount = "", _paymentMethod = "", _paymentChannel = "momo";
  dynamic _customer;
  bool _loading = false, _phoneNumberField = false, _isCard = false;
  String _accountName = "", _accountNumber = "";
  dynamic _isPhoneVerified;

  bool _isVisaPayment() {
    if (_paymentMethod == "CARD") {
      setState(() => this._paymentChannel = "card");
      return true;
    }
    setState(() => this._paymentChannel = "momo");
    return false;
  }

  _getMeterInfo() async {
    var _localDb = new LocalDatabase();
    var _res = await _localDb.viewMeter(_meterId);
    if (_res != null) {
      setState(() {
        _accountName = _res[0]["account_name"];
        _accountNumber = _res[0]["account_number"];
      });
    }
  }

  void _resendOtp({required String phoneNumber}) async {
    if (mounted) setState(() => _loading = true);
    String appSignature = await SmsAutoFill().getAppSignature;
    RestDataSource _request = new RestDataSource();
    _request.post(
      context,
      url: Endpoints.send_otp_code,
      data: {"app_signature": appSignature, "phone_number": phoneNumber},
    ).then((Map response) async {
      if (mounted) setState(() => _loading = false);
      if (response[Constants.success]) {
        Navigator.pushReplacement(
          context,
          FadeRoute(
            page: ForceVerifyPhoneNumber(
              canGoBack: true,
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

  _proceedToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(Home.id, (Route<dynamic> route) => false);
  }

  void _submitForm() async {
    mixpanel?.track('Submit Confirm Pay Bill');
    await _getMeterInfo();
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    FocusScope.of(context).requestFocus(FocusNode());
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      HapticFeedback.vibrate();
      return;
    } else {
      // Check if phone number is verified
      if (_isPhoneVerified.toString() == "false") {
        showDialog(
          context: context,
          builder: (_) => ConfirmDialog(
            title: "Unverified Phone Number",
            content: "We need to verify your phone"
                " number (${_mobileNumberController.text}) "
                "before you can make a transaction. This is "
                "a one-time verification. Verify now?",
            confirmText: "Verify Now",
            confirmTextColor: Constants.kPrimaryColor,
            confirm: () {
              _resendOtp(phoneNumber: getMsisdn(_mobileNumberController.text));
            },
          ),
        );
        return;
      }

      var _percentage = _localStorage.getString(Constants.paymentPercentageCharge);
      var _transactionFee = amountPercentage(percentage: double.parse(_percentage ?? "0"), amount: _amount);
      var _data = {
        "meter_id": _meterId,
        "payment_method": _paymentChannel,
        "amount": (double.parse(_amount) + _transactionFee),
        "transaction_charge": _transactionFee.toStringAsFixed(2),
        "actual_amount": double.parse(_amount),
        "msisdn": getMsisdn(_mobileNumberController.text),
        "network": _paymentMethod,
        "old_balance": widget.hasOldBalance ? widget.meter["balance"].toString() : "",
        "account_number": "${formatCustomerAccountNumber(_accountNumber)}",
        "account_name": "$_accountName",
      };
      if (!_isVisaPayment()) {
        double _payAmount = double.parse(_amount);
        double _maxAmount = double.parse("5000");
        if (_payAmount > _maxAmount) {
          HapticFeedback.vibrate();
          _onRequestFailed("Maximum amount for Mobile Cash is GHS 5,000");
          return;
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PayBillSummary(
                paymentDetails: _data,
                apiUrl: Endpoints.payment_history_add,
                paymentType: Constants.momo,
              ),
            ),
          );
        }
      } else {
        double _payAmount = double.parse(_amount);
        double _minAmount = double.parse("10");
        if (_payAmount < _minAmount) {
          HapticFeedback.vibrate();
          _onRequestFailed("Minimum amount for Debit Card Payment is GHS 10.00");
          return;
        } else {
          if (mounted) setState(() => _loading = true);
          bool _hasSavedCard = await _localDb.hasSavedCards();
          if (mounted) setState(() => _loading = false);
          if (_hasSavedCard) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SavedCards(
                  paymentDetails: _data,
                  accountName: _accountName,
                  accountNumber: _accountNumber,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CardPaymentForm(
                  transData: _data,
                  accountName: _accountName,
                  accountNumber: _accountNumber,
                ),
              ),
            );
          }
        }
      }
    }
  }

  void _checkSelectedPaymentMethod() {
    if (_paymentMethod == "CARD") {
      setState(() {
        _phoneNumberField = true;
        _isCard = true;
      });
    } else {
      setState(() {
        _phoneNumberField = true;
        _isCard = false;
      });
    }
  }

  _loadMeters() async {
    var _localDb = new LocalDatabase();
    var _res = await _localDb.getMeters();
    if (mounted) {
      setState(() => this._meters = _res);
      setState(() => _loading = false);
      return;
    }
  }

  List<dynamic> _loadMetersIntoDropDown() {
    List<dynamic> _loadedMeters = [];
    for (var i = 0; i < _meters.length; i++) {
      _loadedMeters.add({
        "display": "${formatCustomerAccountNumber(_meters[i]["account_number"])} - ${_meters[i]["account_name"]}",
        "value": "${_meters[i]["meter_id"]}",
      });
    }
    return _loadedMeters;
  }

  _loadCustomerInfo() async {
    setState(() => _loading = true);
    var _localDb = new LocalDatabase();
    _customer = await _localDb.getCustomer();

    SharedPreferences _localStorage = await SharedPreferences.getInstance();

    var phoneNumber = _localStorage.getString(Constants.localMomoPhone);
    String customerPhoneNumber = _customer["phone_number"];
    var isVerified = _customer["is_phone_verified"];

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      customerPhoneNumber = phoneNumber;
      isVerified = "true";
    }

    if (mounted) {
      setState(() {
        this._mobileNumberController.text = getActualPhone(customerPhoneNumber);
        this._isPhoneVerified = isVerified;
      });
      _loadMeters();
    }
  }

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

  @override
  void initState() {
    _loadCustomerInfo();
    super.initState();
    if (widget.meter != null)
      setState(() {
        _meterId = widget.meter["meter_id"].toString();
        if (widget.meter["balance"].toString()[0] == "-") {
          _amount = "";
        } else {
          _amount = widget.meter["balance"].toString();
          _amountInputFieldFocus.requestFocus();
        }
      });
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
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70.h),
          child: Container(
            color: Constants.kPrimaryColor,
            child: GeneralHeader(
              title: "Pay Bill (My Account)",
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Constants.indexHorizontalSpace,
              vertical: Constants.indexVerticalSpace,
            ),
            child: Column(
              children: <Widget>[
                if (_meters.length < 1)
                  addAccountFirst(context)
                else
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 10.h),
                          child: GText(
                            textData: "Select Customer Account *",
                            textSize: 12.sp,
                            textColor: Constants.kPrimaryColor,
                          ),
                        ),
                        DropDownFormField(
                          value: _meterId,
                          inputDecoration: circularInputDecoration(title: "", useDropDownPadding: true, circularRadius: 10.w, suffix: Icon(Icons.keyboard_arrow_down_outlined, size: 22.sp)),
                          onSaved: (value) {
                            setState(() => _meterId = value);
                          },
                          onChanged: (value) {
                            setState(() => _meterId = value);
                          },
                          dataSource: _loadMetersIntoDropDown(),
                          required: true,
                          validator: (value) {
                            if (value.toString() == 'null') {
                              return 'Kindly specify account';
                            }
                            return null;
                          },
                          textField: 'display',
                          valueField: 'value',
                        ),
                        Constants.kSizeHeight_10,
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 10.h),
                          child: GText(
                            textData: "Amount (GHS) *",
                            textSize: 12.sp,
                            textColor: Constants.kPrimaryColor,
                          ),
                        ),
                        TextFormField(
                          keyboardType: Platform.isAndroid ? TextInputType.phone : TextInputType.numberWithOptions(decimal: true, signed: false),
                          focusNode: _amountInputFieldFocus,
                          textInputAction: TextInputAction.next,
                          validator: (value) => money(value!),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                            LengthLimitingTextInputFormatter(7),
                          ],
                          onFieldSubmitted: (v) {
                            FocusScope.of(context).nextFocus();
                          },
                          initialValue: _amount,
                          toolbarOptions: ToolbarOptions(
                            paste: false,
                            cut: false,
                            copy: true,
                            selectAll: true,
                          ),
                          onChanged: (dynamic value) {
                            setState(() {
                              _amount = value;
                            });
                          },
                          style: circularTextStyle(),
                          decoration: circularInputDecoration(
                            title: "",
                            circularRadius: 10.w,
                          ),
                        ),
                        Constants.kSizeHeight_10,
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 10.h),
                          child: GText(
                            textData: "Payment Method *",
                            textSize: 12.sp,
                            textColor: Constants.kPrimaryColor,
                          ),
                        ),
                        DropDownFormField(
                          value: _paymentMethod,
                          inputDecoration: circularInputDecoration(title: "", useDropDownPadding: true, circularRadius: 10.w, suffix: Icon(Icons.keyboard_arrow_down_outlined, size: 22.sp)),
                          onSaved: (value) {
                            setState(() {
                              _paymentMethod = value;
                            });
                            _checkSelectedPaymentMethod();
                          },
                          onChanged: (value) {
                            setState(() {
                              _paymentMethod = value;
                            });
                            _checkSelectedPaymentMethod();
                          },
                          required: true,
                          validator: (value) {
                            if (value.toString() == 'null') {
                              return 'Payment method is required';
                            }
                            return null;
                          },
                          dataSource: Menu.paymentMethod,
                          textField: 'display',
                          valueField: 'value',
                          labelImage: 'image',
                        ),
                        !_phoneNumberField
                            ? Container(height: 14.h)
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Constants.kSizeHeight_20,
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 5.w),
                                    child: GText(
                                      textData: !_isCard ? "Mobile Wallet Number *" : "Telephone Number *",
                                      textSize: 12.sp,
                                      textColor: Constants.kPrimaryColor,
                                    ),
                                  ),
                                  Constants.kSizeHeight_10,
                                  TextFormField(
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    controller: _mobileNumberController,
                                    validator: (value) => validatePhone(value!),
                                    readOnly: true,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    onFieldSubmitted: (v) {
                                      FocusScope.of(context).nextFocus();
                                    },
                                    style: circularTextStyle(),
                                    decoration: circularInputDecoration(
                                      title: "",
                                      circularRadius: 10.w,
                                      fillColor: Constants.kGreenLightColor.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.centerRight,
                                    child: buildTextButton(
                                      title: "Change this"
                                          " ${!_isCard ? "Mobile Wallet Number"
                                              "" : "Telephone Number"}?",
                                      textColor: Constants.kPrimaryColor,
                                      textSize: 12.sp,
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        _navigateAndReturnValue(
                                          context,
                                          EditPhoneNumber(
                                            phoneNumber: this._mobileNumberController.text,
                                            navigateToHome: false,
                                            verifyMomo: true,
                                          ),
                                          "Phone Number",
                                        );
                                      },
                                    ),
                                  ),
                                  Constants.kSizeHeight_5
                                ],
                              ),
                        buildElevatedButton(
                          borderRadius: 10.w,
                          title: "Proceed",
                          onPressed: () {
                            _submitForm();
                          },
                        ),
                        Constants.kSizeHeight_50,
                        Constants.kSizeHeight_50,
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _onRequestFailed(dynamic errorText) async {
    showDialog(
      context: context,
      builder: (_) => ErrorDialog(
        content: errorText.toString().replaceAll(RegExp(Constants.errorFilter), ""),
      ),
    );
  }
}
