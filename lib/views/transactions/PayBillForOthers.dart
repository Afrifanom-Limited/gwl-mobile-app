import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/DropDownFormField.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/FlashHelper.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/MaskTextInputFormatter.dart';
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

class PayBillForOthers extends StatefulWidget {
  static const String id = "/pay_bill_for_others";

  @override
  _PayBillForOthersState createState() => _PayBillForOthersState();
}

class _PayBillForOthersState extends State<PayBillForOthers> {
  var _localDb = new LocalDatabase();
  final _formKey = GlobalKey<FormState>();
  late FocusNode _accountNumberFocusNode;
  final _mobileNumberController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  String _previousBalance = "";
  double get balanceAmount {
    if (_previousBalance == "") return 0.0;
    return double.parse(_previousBalance);
  }

  String _amount = "", _paymentMethod = "", _paymentChannel = "momo";
  dynamic _customer;
  bool _loading = false, _phoneNumberField = false, _gettingCustomerInfo = false, _isCard = false, _accountNameVerified = false;
  dynamic _isPhoneVerified;

  bool _isVisaPayment() {
    if (_paymentMethod == "CARD") {
      setState(() => this._paymentChannel = "card");
      return true;
    }
    setState(() => this._paymentChannel = "momo");
    return false;
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
            content: "We need to verify your phone number (${_mobileNumberController.text}) "
                "before you can make any transaction. This is "
                "a one-time verification. Verify now?",
            confirmText: "Yes, Verify Now",
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
        "gwcl_customer_number": stripSymbols(_accountNumberController.text),
        "payer_name": _customer["name"],
        "payment_method": _paymentChannel,
        "msisdn": getMsisdn(_mobileNumberController.text),
        "network": _paymentMethod,
        "account_number": "${_accountNumberController.text}",
        "account_name": "${_accountNameController.text}",
        "actual_amount": double.parse(_amount),
        "amount": (double.parse(_amount) + _transactionFee),
        "transaction_charge": _transactionFee.toStringAsFixed(2),
      };
      mixpanel?.track('Pay for Others Proceed');
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
                apiUrl: Endpoints.payment_history_add_others,
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
                  accountName: _accountNameController.text,
                  accountNumber: _accountNumberController.text,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CardPaymentForm(
                  transData: _data,
                  accountNumber: _accountNumberController.text,
                  accountName: _accountNameController.text,
                ),
              ),
            );
          }
        }
      }
    }
  }

  void _getCustomerInfo() async {
    if (stripSymbols(_accountNumberController.text).toString().length > 11) {
      FocusScope.of(context).requestFocus(FocusNode());
      setState(() {
        _gettingCustomerInfo = true;
        _accountNameVerified = false;
      });
      _accountNameController.text = "";
      _previousBalance = "";
      RestDataSource _request = new RestDataSource();
      _request.post(
        context,
        url: Endpoints.meters_get_customer_info,
        data: {
          "account_number": stripSymbols(_accountNumberController.text),
          "app_signature": Constants.appId,
        },
      ).then((Map response) async {
        if (mounted) setState(() => _gettingCustomerInfo = false);
        if (response[Constants.success]) {
          var data = response[Constants.response];

          if (mounted)
            setState(() {
              _previousBalance = (data["balance"] ?? "").toString();
              _amount = _previousBalance;
              _accountNameController.text = data["customer_name"];
              _accountNameVerified = true;
            });
          _addAccountNumberToList(_accountNumberController.text);
        } else {
          if (mounted)
            showDialog(
              context: context,
              builder: (_) => InfoDialog(
                title: "Oops!",
                content: "${response[Constants.message]}",
              ),
            );
        }
      });
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

  _loadCustomerInfo() async {
    setState(() => _loading = true);
    var _localDb = new LocalDatabase();
    _customer = await _localDb.getCustomer();
    if (mounted) {
      setState(() {
        this._mobileNumberController.text = getActualPhone(_customer["phone_number"]);
        this._isPhoneVerified = _customer["is_phone_verified"];
        _loading = false;
      });
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
    _accountNumberFocusNode = new FocusNode();
    _accountNumberFocusNode.addListener(() {
      if (!_accountNumberFocusNode.hasFocus) {
        _getCustomerInfo();
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
              title: "Pay Bill (For Others)",
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
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Constants.kSizeHeight_10,
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5.w),
                        child: GText(
                          textData: "Customer Account Number *",
                          textSize: 12.sp,
                          textColor: Constants.kPrimaryColor,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5.w),
                        child: GText(
                          textData: "12-character GWCL customer "
                              "account number. For example: 0202-2482-XXXX",
                          textSize: 10.sp,
                          textColor: Constants.kGreyColor,
                        ),
                      ),
                      Constants.kSizeHeight_10,
                      TypeAheadFormField(
                        textFieldConfiguration: TextFieldConfiguration(
                          controller: _accountNumberController,
                          focusNode: _accountNumberFocusNode,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.characters,
                          style: circularTextStyle(),
                          inputFormatters: [MaskTextInputFormatter(mask: "GGGG-GGGG-GGGG")],
                          decoration: circularInputDecoration(
                            title: "",
                            circularRadius: 10.w,
                          ),
                        ),
                        suggestionsCallback: (pattern) {
                          return PreviousAccountNumbers.getSuggestions(pattern);
                        },
                        itemBuilder: (context, suggestion) {
                          return ListTile(
                            title: GText(
                              textData: suggestion.toString(),
                              textSize: 13.sp,
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline_rounded),
                              onPressed: () => _removeAccountNumberFromList(suggestion.toString()),
                            ),
                          );
                        },
                        transitionBuilder: (context, suggestionsBox, controller) {
                          return suggestionsBox;
                        },
                        onSuggestionSelected: (suggestion) {
                          _accountNumberController.text = suggestion.toString();
                        },
                        noItemsFoundBuilder: (context) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: GText(
                              textData: "No recent account numbers found",
                              textColor: Constants.kGreyColor,
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                        validator: (value) {
                          if (value!.length < 14) return "Invalid customer number provided";
                          return null;
                        },
                        onSaved: (value) => _accountNumberController.text = value!,
                      ),
                      if (_accountNameVerified) Constants.kSizeHeight_20,
                      if (_accountNameVerified)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w),
                          child: GText(
                            textData: "Customer Account Name",
                            textSize: 12.sp,
                            textColor: Constants.kPrimaryColor,
                          ),
                        ),
                      if (_accountNameVerified)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w),
                          child: GText(
                            textData: "Name of account holder for the account number",
                            textSize: 10.sp,
                            textColor: Constants.kGreyColor,
                          ),
                        ),
                      if (_accountNameVerified) Constants.kSizeHeight_10,
                      if (_accountNameVerified)
                        TextFormField(
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          controller: _accountNameController,
                          readOnly: true,
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
                      if (_previousBalance.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              GText(
                                textData: balanceAmount > 0 ? "Owes this amount: " : "Has balance of: ",
                                textSize: 10.sp,
                              ),
                              GText(
                                textData: "GHS $balanceAmount",
                                textSize: 12.sp,
                                textWeight: FontWeight.bold,
                                textColor: balanceAmount > 0 ? Colors.pink : Colors.green,
                              ),
                            ],
                          ),
                        ),
                      if (_gettingCustomerInfo)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                child: SizedBox(
                                  height: 1.h,
                                  child: BarLoader(
                                    barColor: Constants.kPrimaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                                  toolbarOptions: ToolbarOptions(
                                    paste: false,
                                    cut: false,
                                    copy: true,
                                    selectAll: true,
                                  ),
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

  Future _addAccountNumberToList(String accountNumber) async {
    try {
      SharedPreferences _localStorage = await SharedPreferences.getInstance();
      List<String> prefList = [];
      if (_localStorage.getStringList(Constants.accountNumbers) == null) {
        prefList.add(accountNumber);
      } else {
        prefList = _localStorage.getStringList(Constants.accountNumbers)!;
        if (prefList.contains(accountNumber) == false) {
          prefList.add(accountNumber);
        }
      }
      _localStorage.setStringList(Constants.accountNumbers, prefList);
    } catch (e) {}
  }

  Future _removeAccountNumberFromList(String accountNumber) async {
    try {
      SharedPreferences _localStorage = await SharedPreferences.getInstance();
      List<String> prefList = [];
      prefList = _localStorage.getStringList(Constants.accountNumbers)!;
      prefList.removeWhere((item) => item == accountNumber);
      _localStorage.setStringList(Constants.accountNumbers, prefList);
      showBasicsFlash(
        context,
        "$accountNumber removed. It will not be listed on the next search",
        textColor: Constants.kPrimaryColor,
        bgColor: Constants.kPrimaryLightColor,
      );
    } catch (e) {}
  }
}

class PreviousAccountNumbers {
  static Future<List<String>> getSuggestions(String query) async {
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    List<String>? jsonList = _localStorage.getStringList(Constants.accountNumbers);

    List<String> matches = List.empty(growable: true);
    if (jsonList != null) matches.addAll(jsonList);

    matches.retainWhere((s) => s.toLowerCase().contains(query.toLowerCase()));
    return matches;
  }
}
