import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/DateTimePickerFormField.dart';
import 'package:gwcl/helpers/DropDownFormField.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Menu.dart';
import 'package:gwcl/helpers/PageTransitions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/helpers/TextFields.dart';
import 'package:gwcl/models/ReportRequest.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/report/RequestedReports.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class Report extends StatefulWidget {
  final String reportType;
  final String? billingReportType;
  final dynamic customer;

  const Report(
      {Key? key,
      required this.reportType,
      required this.customer,
      this.billingReportType})
      : super(key: key);
  @override
  _ReportState createState() => _ReportState();
}

class _ReportState extends State<Report> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false, _isBilling = true, _isSingle = true;
  final _format = DateFormat("dd MMMM, yyyy");
  String _meterId = "", _reportType = "", _billingReportType = "";
  DateTime? _startDate, _endDate;
  var _meters = List.empty(growable: true);
  late ReportRequest _reportRequest;

  _loadMeters() async {
    var _localDb = new LocalDatabase();
    var _res = await _localDb.getMeters();
    if (mounted) {
      setState(() => this._meters = _res);
      return;
    }
  }

  List<dynamic> _loadMetersIntoDropDown() {
    List<dynamic> _loadedMeters = [];
    for (var i = 0; i < _meters.length; i++) {
      _loadedMeters.add({
        "display":
            "${formatCustomerAccountNumber(_meters[i]["account_number"])} - ${_meters[i]["account_name"]}",
        "value": "${_meters[i]["meter_id"]}",
      });
    }
    return _loadedMeters;
  }

  void _submitForm() async {
    try {
      FocusScope.of(context).requestFocus(FocusNode());

      final isValid = _formKey.currentState!.validate();
      if (!isValid) {
        HapticFeedback.vibrate();
        return;
      }

      if (!_isSingle) {
        // Check for valid date range
        DateTime start = DateTime.parse(_startDate.toString());
        DateTime end = DateTime.parse(_endDate.toString());
        var _differenceInDays = end.difference(start).inDays;
        if (_differenceInDays.toString()[0] == "-") {
          HapticFeedback.vibrate();
          _onRequestFailed("Invalid date range selection");
          return;
        }
      }

      if (_isSingle) {
        _startDate = _endDate;
      }

      if (_meterId == "") {
        HapticFeedback.vibrate();
        _onRequestFailed("Kindly specify customer account number");
        return;
      } else {
        setState(() => _loading = true);
        RestDataSource _request = new RestDataSource();
        _request.post(
          context,
          url: Endpoints.report_requests_add,
          data: {
            "meter_id": _meterId,
            "report_type": _reportType,
            "start_date": _startDate.toString() == "null"
                ? DateTime.now().toString()
                : _startDate.toString(),
            "end_date": _endDate.toString() == "null"
                ? DateTime.now().toString()
                : _endDate.toString()
          },
        ).then((Map response) async {
          if (mounted) setState(() => _loading = false);
          if (response[Constants.success]) {
            setState(() => _meterId = '');
            _reportRequest = ReportRequest.map(response[Constants.response]);
            _onRequestSuccess(_reportRequest);
          } else {
            _onRequestFailed(response[Constants.message]);
          }
        });
      }
    } catch (e) {}
  }

  void _checkSelectedReportType() {
    if (_reportType == "billing") {
      setState(() => _isBilling = true);
    } else {
      setState(() {
        _isBilling = false;
        _isSingle = false;
        _billingReportType = "multiple";
      });
    }
  }

  void _checkSelectedBillingReportType() {
    if (_billingReportType == "single") {
      setState(() => _isSingle = true);
    } else {
      setState(() => _isSingle = false);
    }
  }

  @override
  void initState() {
    _loadMeters();
    super.initState();
    setState(() {
      _reportType = widget.reportType;
      _billingReportType = (widget.billingReportType != null
          ? widget.billingReportType
          : "single")!;
      _isBilling = widget.billingReportType == 'multiple' ? false : true;
      _isSingle = widget.billingReportType == 'multiple' ? false : true;
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
              title: "Statement Request",
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
              child: Column(
                children: [
                  if (_meters.length < 1)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Constants.indexHorizontalSpace,
                      ),
                      child: addAccountFirst(context),
                    )
                  else
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Constants.kSizeHeight_20,
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 24.w, vertical: 0.h),
                            child: GText(
                              textData: "Select Account Number *",
                              textSize: 12.sp,
                              textColor: Constants.kPrimaryColor,
                            ),
                          ),
                          Constants.kSizeHeight_10,
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 0.h),
                            child: DropDownFormField(
                              value: _meterId,
                              hintText: "Select Account ...",
                              inputDecoration: circularInputDecoration(
                                  title: "",
                                  circularRadius: 10.w,
                                  useDropDownPadding: true,
                                  suffix: Icon(
                                      Icons.keyboard_arrow_down_outlined,
                                      size: 22.sp)),
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
                          ),
                          Constants.kSizeHeight_20,
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 24.w, vertical: 0.h),
                            child: GText(
                              textData: "Select Statement Type *",
                              textSize: 12.sp,
                              textColor: Constants.kPrimaryColor,
                            ),
                          ),
                          Constants.kSizeHeight_10,
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 0.h),
                            child: DropDownFormField(
                              value: _reportType,
                              hintText: "Select ...",
                              inputDecoration: circularInputDecoration(
                                  title: "",
                                  circularRadius: 10.w,
                                  useDropDownPadding: true,
                                  suffix: Icon(
                                      Icons.keyboard_arrow_down_outlined,
                                      size: 22.sp)),
                              onSaved: (value) {
                                setState(() => _reportType = value);
                                _checkSelectedReportType();
                              },
                              onChanged: (value) {
                                setState(() => _reportType = value);
                                _checkSelectedReportType();
                              },
                              dataSource: Menu.reportType,
                              required: true,
                              validator: (value) {
                                if (value.toString() == 'null') {
                                  return 'Report type is required';
                                }
                                return null;
                              },
                              textField: 'display',
                              valueField: 'value',
                            ),
                          ),
                          Constants.kSizeHeight_10,
                          if (_isBilling)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Constants.kSizeHeight_10,
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 24.w, vertical: 0.h),
                                  child: GText(
                                    textData: "Date Format *",
                                    textSize: 12.sp,
                                    textColor: Constants.kPrimaryColor,
                                  ),
                                ),
                                Constants.kSizeHeight_10,
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 14.w, vertical: 0.h),
                                  child: DropDownFormField(
                                    value: _billingReportType,
                                    inputDecoration: circularInputDecoration(
                                        title: "",
                                        useDropDownPadding: true,
                                        circularRadius: 10.w,
                                        suffix: Icon(
                                            Icons.keyboard_arrow_down_outlined,
                                            size: 22.sp)),
                                    onSaved: (value) {
                                      setState(
                                          () => _billingReportType = value);
                                      _checkSelectedBillingReportType();
                                    },
                                    onChanged: (value) {
                                      setState(
                                          () => _billingReportType = value);
                                      _checkSelectedBillingReportType();
                                    },
                                    required: true,
                                    validator: (value) {
                                      if (value.toString() == 'null') {
                                        return 'Billing report format is required';
                                      }
                                      return null;
                                    },
                                    dataSource: Menu.billingReportType,
                                    textField: 'display',
                                    valueField: 'value',
                                  ),
                                ),
                              ],
                            ),
                          if (_isBilling) Constants.kSizeHeight_10,
                          if (_isBilling) Constants.kSizeHeight_5,
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            child: Table(
                              children: [
                                TableRow(
                                  children: [
                                    if (!_isSingle)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 5.w),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 14.w,
                                                  vertical: 10.h),
                                              child: GText(
                                                textData: "Start Date *",
                                                textSize: 12.sp,
                                                textColor:
                                                    Constants.kPrimaryColor,
                                              ),
                                            ),
                                            DateTimeField(
                                              format: _format,
                                              style: circularTextStyle(),
                                              decoration:
                                                  circularInputDecoration(
                                                title: "",
                                                circularRadius: 10.w,
                                              ),
                                              onSaved: (value) {
                                                setState(
                                                    () => _startDate = value);
                                              },
                                              onChanged: (value) {
                                                setState(
                                                    () => _startDate = value);
                                              },
                                              validator: (value) {
                                                if (!_isSingle &&
                                                    value == null) {
                                                  return 'Kindly specify start date';
                                                }
                                                return null;
                                              },
                                              onShowPicker: (context,
                                                  currentValue) async {
                                                final date =
                                                    await showRoundedDatePicker(
                                                  context: context,
                                                  firstDate: DateTime(2000),
                                                  barrierDismissible: true,
                                                  initialDatePickerMode:
                                                      DatePickerMode.day,
                                                  initialDate: currentValue,
                                                  lastDate: DateTime.now(),
                                                  theme: ThemeData(
                                                    primaryColor:
                                                        Constants.kPrimaryColor,
                                                    disabledColor: Colors.grey,
                                                  ),
                                                  styleDatePicker:
                                                      buildMaterialRoundedDatePickerStyle(),
                                                );

                                                if (date != null) {
                                                  return date;
                                                } else {
                                                  return currentValue;
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 5.w),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12.w,
                                                vertical:
                                                    !_isSingle ? 10.h : 2.h),
                                            child: GText(
                                              textData: _isSingle
                                                  ? "Specify month *"
                                                  : "End Date *",
                                              textSize: 12.sp,
                                              textColor:
                                                  Constants.kPrimaryColor,
                                            ),
                                          ),
                                          if (_isSingle)
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 12.w),
                                              child: GText(
                                                textData:
                                                    "Select 1st day of Month"
                                                    " and Year. eg: 01 June, 2020",
                                                textFont: Constants.kFontLight,
                                                textSize: 12.sp,
                                                textColor:
                                                    Constants.kPrimaryColor,
                                                textMaxLines: 10,
                                              ),
                                            ),
                                          if (_isSingle)
                                            Constants.kSizeHeight_10,
                                          DateTimeField(
                                            format: _format,
                                            style: circularTextStyle(),
                                            decoration: circularInputDecoration(
                                              title: "",
                                              circularRadius: 10.w,
                                            ),
                                            onSaved: (value) {
                                              setState(() => _endDate = value);
                                            },
                                            onChanged: (value) {
                                              setState(() => _endDate = value);
                                            },
                                            validator: (value) {
                                              if (value == null) {
                                                return 'Kindly specify ${_isSingle ? " month "
                                                    "" : "end date "}';
                                              }
                                              return null;
                                            },
                                            onShowPicker:
                                                (context, currentValue) async {
                                              final date =
                                                  await showRoundedDatePicker(
                                                context: context,
                                                firstDate: DateTime(2000),
                                                barrierDismissible: true,
                                                initialDate: currentValue,
                                                lastDate: DateTime.now(),
                                                theme: ThemeData(
                                                  primaryColor:
                                                      Constants.kPrimaryColor,
                                                  disabledColor: Colors.grey,
                                                ),
                                                styleDatePicker:
                                                    buildMaterialRoundedDatePickerStyle(),
                                              );

                                              if (date != null) {
                                                return date;
                                              } else {
                                                return currentValue;
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                left: 15.w,
                                right: 15.w,
                                top: 10.h,
                                bottom: 0.h),
                            child: Container(
                              decoration: BoxDecoration(
                                  color:
                                      Constants.kPrimaryColor.withOpacity(0.2),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5.w))),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15.w, vertical: 10.h),
                                child: GText(
                                  textData: _isBilling
                                      ? "TIP: This will generate a PDF report of "
                                          "monthly bills associated to the specified account number."
                                      : "TIP: This will generate a PDF report of "
                                          "monthly bills and payments "
                                          "associated to the specified account number.",
                                  textFont: Constants.kFontLight,
                                  textSize: 12.sp,
                                  textAlign: TextAlign.justify,
                                  textColor: Constants.kPrimaryColor,
                                  textMaxLines: 10,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 15.w, vertical: 20.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                buildElevatedButton(
                                  borderRadius: 10.w,
                                  title: "Submit Request",
                                  onPressed: () => _submitForm(),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  _onRequestSuccess(ReportRequest reportRequest) async {
    coolAlert(
      context,
      CoolAlertType.success,
      title: "Success",
      subtitle: "Your statement is ready",
      confirmBtnText: "View My Statements",
      showCancelBtn: false,
      barrierDismissible: false,
      onConfirmBtnTap: () {
        Navigator.pushReplacement(
          context,
          FadeRoute(
            page: RequestedReports(),
          ),
        );
      },
    );
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
