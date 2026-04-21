import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gwcl/helpers/AES.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/MaskTextInputFormatter.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/helpers/TextFields.dart';
import 'package:gwcl/models/SavedCard.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/templates/Modals.dart';
import 'package:gwcl/views/transactions/PayBillSummary.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CardPaymentForm extends StatefulWidget {
  final dynamic transData;
  final String accountName, accountNumber;
  final SavedCard? savedCard;

  const CardPaymentForm({
    Key? key,
    required this.transData,
    required this.accountName,
    required this.accountNumber,
    this.savedCard,
  }) : super(key: key);
  @override
  _CardPaymentFormState createState() => _CardPaymentFormState();
}

class _CardPaymentFormState extends State<CardPaymentForm> {
  var _localDb = new LocalDatabase();
  final _formKey = GlobalKey<FormState>();
  final _cvvController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cardHolderNameController = TextEditingController();
  bool _loading = false;
  String _loadingState = "", cardFirst4 = "", cardLast4 = "";
  var _customer;
  bool _toggleSaveCardInfo = false;

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

  _loadSavedCardDetails() async {
    setState(() => _loading = true);
    if (widget.savedCard != null) {
      _expiryDateController.text = widget.savedCard!.expiryDate;
      _cardHolderNameController.text = widget.savedCard!.cardName;
      setState(() {
        cardFirst4 = widget.savedCard!.cardNumberFirst;
        cardLast4 = widget.savedCard!.cardNumberLast;
      });
    }
    setState(() => _loading = false);
  }

  void _submitForm() async {
    FocusScope.of(context).requestFocus(FocusNode());
    // Create encryption key and iv
    var _customerId = _customer["customer_id"];
    var _aesKey = getAesCusIDKey(_customerId);
    var _aesIv = getAesCusIDIV(_customerId);

    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      HapticFeedback.vibrate();
      return;
    } else {
      var _cardNumber = _cardNumberController.text;
      if (cardFirst4 != "") {
        _cardNumber =
            cardFirst4 + " " + _cardNumberController.text + " " + cardLast4;
      }
      var _expiryDate = _expiryDateController.text.split('/');
      var _cardDetails = Aes.gwclEncrypt(
          "${stripWhiteSpaces(_cardNumber)}|"
          "|${_cardHolderNameController.text}||${_expiryDate[0]}|"
          "|${_expiryDate[1]}||${_cvvController.text}",
          _aesKey,
          _aesIv);

      var _data = {
        "meter_id": widget.transData["meter_id"] ?? "",
        "payment_method": "card",
        "msisdn": widget.transData["msisdn"],
        "network": getCardType(_cardNumber),
        "old_balance": widget.transData["old_balance"] ?? "",
        "gwcl_customer_number":
            widget.transData["gwcl_customer_number"] ?? widget.accountNumber,
        "card_details": _cardDetails,
        "amount": widget.transData["amount"],
        "transaction_charge": widget.transData["transaction_charge"],
        "actual_amount": widget.transData["actual_amount"],
        "account_number":
            "${formatCustomerAccountNumber(widget.accountNumber)}",
        "account_name": "${widget.accountName}",
      };

      var cardNumberFirst =
          stripWhiteSpaces(_cardNumber).toString().substring(0, 4);
      var cardNumberLast =
          stripWhiteSpaces(_cardNumber).toString().substring(12, 16);
      var saveCardData = {
        "saved_card_id": "${cardNumberFirst + cardNumberLast}",
        "card_number_first": "$cardNumberFirst",
        "card_number_last": "$cardNumberLast",
        "expiry_date": "${_expiryDateController.text}",
        "card_name": "${_cardHolderNameController.text}",
      };

      // Check and Save Card Details
      if (_toggleSaveCardInfo == true) {
        await _localDb.addCard(SavedCard.map(saveCardData));
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PayBillSummary(
            paymentDetails: _data,
            apiUrl: Endpoints.payment_history_add_debit_card,
            paymentType: Constants.card,
          ),
        ),
      );
    }
  }

  _showCardPreview() async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).requestFocus(FocusNode());
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    } else {
      setState(() => _loading = true);
      var _cardNumber = _cardNumberController.text;
      if (cardFirst4 != "") {
        _cardNumber =
            cardFirst4 + " " + _cardNumberController.text + " " + cardLast4;
      }

      await Future.delayed(const Duration(milliseconds: 300), () {
        setState(() => _loading = false);
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => CardModal(
            cardHolderName: _cardHolderNameController.text,
            cardNumber: _cardNumber,
            cvv: _cvvController.text,
            expiryDate: _expiryDateController.text,
          ),
        );
      });
    }
  }

  _loadToggleOption() async {
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    bool? _toggleSaveCard = _localStorage.getBool(Constants.allowSaveCardInfo);
    if (_toggleSaveCard == null) {
      setState(() => this._toggleSaveCardInfo = false);
    } else {
      setState(() => this._toggleSaveCardInfo = true);
    }
  }

  _toggleAllowSaveCardInfo(selectedValue) async {
    try {
      SharedPreferences _localStorage = await SharedPreferences.getInstance();
      if (selectedValue) {
        await _localStorage.setBool(
            Constants.allowSaveCardInfo, this._toggleSaveCardInfo);
        setState(() => this._toggleSaveCardInfo = true);
      } else {
        showDialog(
          context: context,
          builder: (_) => ConfirmDialog(
            title: "Confirm Action",
            content: "This will clear any saved cards."
                " Do you want to proceed? ",
            confirmText: "Yes",
            confirmTextColor: Constants.kPrimaryColor,
            confirm: () async {
              await _localStorage.remove(Constants.allowSaveCardInfo);
              await _localStorage.remove(Constants.debitCardInfo);
              setState(() => this._toggleSaveCardInfo = false);
            },
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    _loadToggleOption();
    _loadSavedCardDetails();
    _loadCustomerInfo();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _loading,
      color: Constants.kWhiteColor.withValues(alpha: 0.8),
      opacity: 0.5,
      progressIndicator: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularLoader(
            loaderColor: Constants.kPrimaryColor,
          ),
          if (_loadingState.length > 0)
            Container(
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
              margin: EdgeInsets.only(top: 10.h),
              color: Constants.kGreyColor,
              child: GText(
                textData: _loadingState,
                textSize: 10.sp,
                textColor: Constants.kPrimaryColor,
              ),
            )
        ],
      ),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70.h),
          child: Container(
            color: Constants.kPrimaryColor,
            child: GeneralHeader(
                title: "Debit Card",
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Constants.kSizeHeight_10,
              Form(
                key: _formKey,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Constants.indexHorizontalSpace,
                    vertical: Constants.indexVerticalSpace,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 5.w, vertical: 10.h),
                        child: GText(
                          textData: "Card Holder Name *",
                          textSize: 12.sp,
                          textColor: Constants.kPrimaryColor,
                        ),
                      ),
                      TextFormField(
                        keyboardType: TextInputType.text,
                        controller: _cardHolderNameController,
                        toolbarOptions: ToolbarOptions(
                          paste: true,
                          cut: true,
                          copy: true,
                          selectAll: true,
                        ),
                        validator: (value) =>
                            checkNull(value!, "Card holder name"),
                        textCapitalization: TextCapitalization.characters,
                        style: circularTextStyle(),
                        decoration: circularInputDecoration(
                          title: "",
                        ),
                      ),
                      Constants.kSizeHeight_10,
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 5.w, vertical: 10.h),
                        child: GText(
                          textData: cardFirst4 == ""
                              ? "Card Number *"
                              : "Card Number (Enter middle 8 numbers) *",
                          textSize: 12.sp,
                          textColor: Constants.kPrimaryColor,
                        ),
                      ),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        textAlign: cardFirst4 == ""
                            ? TextAlign.left
                            : TextAlign.center,
                        validator: (value) {
                          if (value!.length < 8)
                            return "Invalid card number provided";
                          return null;
                        },
                        toolbarOptions: ToolbarOptions(
                          paste: true,
                          cut: true,
                          copy: true,
                          selectAll: true,
                        ),
                        controller: _cardNumberController,
                        inputFormatters: [
                          cardFirst4 == ""
                              ? MaskTextInputFormatter(
                                  mask: "#### #### #### ####")
                              : MaskTextInputFormatter(mask: "#### ####")
                        ],
                        style: circularTextStyle(),
                        decoration: circularInputDecoration(
                          title: "",
                          prefix: cardFirst4 != ""
                              ? Padding(
                                  padding: EdgeInsets.only(
                                      left: 20.w,
                                      right: 12.w,
                                      top: 12.h,
                                      bottom: 12.h),
                                  child: GText(
                                    textData: "$cardFirst4",
                                    textSize: 14.sp,
                                    textColor: Constants.kPrimaryColor,
                                  ),
                                )
                              : null,
                          suffix: cardLast4 != ""
                              ? Padding(
                                  padding: EdgeInsets.only(
                                      right: 16.w, top: 12.h, bottom: 12.h),
                                  child: GText(
                                    textData: "$cardLast4",
                                    textSize: 14.sp,
                                    textColor: Constants.kPrimaryColor,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Constants.kSizeHeight_10,
                      Table(
                        columnWidths: {
                          0: FractionColumnWidth(.5),
                          1: FractionColumnWidth(.5),
                        },
                        children: [
                          TableRow(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 10.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 5.w, vertical: 10.h),
                                      child: GText(
                                        textData: "Card Expiry *",
                                        textSize: 12.sp,
                                        textColor: Constants.kPrimaryColor,
                                      ),
                                    ),
                                    TextFormField(
                                      keyboardType: TextInputType.number,
                                      controller: _expiryDateController,
                                      toolbarOptions: ToolbarOptions(
                                        paste: true,
                                        cut: true,
                                        copy: true,
                                        selectAll: true,
                                      ),
                                      validator: (value) {
                                        if (value!.length < 5)
                                          return "Invalid expiry date";
                                        return null;
                                      },
                                      inputFormatters: [
                                        MaskTextInputFormatter(
                                            mask: "##/##",
                                            filter: {"#": RegExp(r'[0-9]')})
                                      ],
                                      style: circularTextStyle(),
                                      decoration: circularInputDecoration(
                                        title: "MM/YY",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 10.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 5.w, vertical: 10.h),
                                      child: GText(
                                        textData: "CVV *",
                                        textSize: 12.sp,
                                        textColor: Constants.kPrimaryColor,
                                      ),
                                    ),
                                    TextFormField(
                                      keyboardType: TextInputType.number,
                                      controller: _cvvController,
                                      toolbarOptions: ToolbarOptions(
                                        paste: true,
                                        cut: true,
                                        copy: true,
                                        selectAll: true,
                                      ),
                                      validator: (value) {
                                        if (value!.length < 3)
                                          return "Invalid cvv provided";
                                        return null;
                                      },
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(3),
                                      ],
                                      style: circularTextStyle(),
                                      decoration: circularInputDecoration(
                                        title: "",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (widget.savedCard == null) Constants.kSizeHeight_20,
                      if (widget.savedCard == null)
                        Container(
                          color: Constants.kNearlyDarkBlueColor.withValues(alpha: 0.2),
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 2.h),
                          child: SwitchListTile(
                            activeColor: Constants.kPrimaryColor,
                            value: _toggleSaveCardInfo,
                            title: GText(
                              textData: "Save Payment Method",
                              textSize: 13.sp,
                              textColor: Constants.kPrimaryColor,
                            ),
                            onChanged: (val) => setState(() {
                              setState(() {
                                _toggleAllowSaveCardInfo(val);
                              });
                            }),
                          ),
                        ),
                      // Constants.kSizeHeight_10,
                      // Divider(height: 0.5, color: Constants.kPrimaryColor),
                      Constants.kSizeHeight_20,
                      buildElevatedButton(
                        title: "Proceed",
                        onPressed: () {
                          _submitForm();
                        },
                      ),
                      buildTextButton(
                        title: "Preview card details",
                        textSize: 12.sp,
                        textColor: Constants.kPrimaryColor,
                        onPressed: () {
                          _showCardPreview();
                        },
                      ),
                      Constants.kSizeHeight_50,
                      Constants.kSizeHeight_50,
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
