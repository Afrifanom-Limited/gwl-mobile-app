import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/FlashHelper.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/LiquidWave.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/ProgressDialog.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/helpers/TimeAgo.dart' as timeAgo;
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/templates/Modals.dart';
import 'package:gwcl/views/home/Home.dart';
import 'package:gwcl/views/meter/EditAlias.dart';
import 'package:gwcl/views/meter/EditMeterDetails.dart';
import 'package:gwcl/views/meter/EditMeterEmailAddress.dart';
import 'package:gwcl/views/meter/EditSecondaryPhoneNumber.dart';
import 'package:gwcl/views/transactions/PayBill.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:open_file/open_file.dart';
import '../../mixpanel.dart';

class MeterDetails extends StatefulWidget {
  final dynamic meterInfo;

  const MeterDetails({Key? key, required this.meterInfo}) : super(key: key);
  @override
  _MeterDetailsState createState() => _MeterDetailsState();
}

class _MeterDetailsState extends State<MeterDetails> {
  late Dio _dio;
  String _progress = "";
  bool _loading = false, _isOwing = true, _billLoading = false, _allowWriteFile = false;
  var _meter, _amount = "";

  _loadMeter() {
    if (mounted) setState(() => this._meter = widget.meterInfo);
    if (this._meter["balance"].toString()[0] == "-") {
      setState(() {
        _isOwing = false;
        _amount = _meter["balance"].toString().replaceFirst(RegExp('-'), '');
      });
    } else {
      setState(() {
        _isOwing = true;
        _amount = _meter["balance"].toString();
      });
    }
  }

  _backToHome(var meterId) async {
    var _localDb = new LocalDatabase();
    await _localDb.removeMeter(meterId.toString());
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Home(index: 0)), (route) => false);
    }
  }

  _removeMeter(var meterId) {
    setState(() => _loading = true);
    RestDataSource _request = new RestDataSource();
    _request.get(context, url: Endpoints.meters_delete.replaceFirst("{id}", "$meterId")).then((Map response) {
      if (mounted) setState(() => _loading = false);
      if (response[Constants.success]) {
        _backToHome(meterId);
      } else {
        showBasicsFlash(context, "Unable to remove account.", textColor: Constants.kWhiteColor, bgColor: Constants.kWarningLightColor);
      }
    });
  }

  _billRows(bill) {
    List<TableRow> list = List.empty(growable: true);
    for (var i = 0; i < bill.length; i++) {
      dynamic item = bill[i];
      list.add(tableRow("${item['key']}", "${item["value"]}"));
    }
    return list;
  }

  _getCurrentBill() {
    setState(() => _billLoading = true);
    RestDataSource _request = new RestDataSource();
    _request.get(context, url: Endpoints.meters_current_bill.replaceFirst("{id}", "${_meter["meter_id"]}")).then((Map response) async {
      if (mounted) setState(() => _billLoading = false);
      HapticFeedback.lightImpact();
      if (response[Constants.success]) {
        dynamic _meter = response[Constants.response]["meter"];
        _showResults(response[Constants.response]["bill"], response[Constants.response]["month"], fileUrl: _meter["current_bill"]);
      } else {
        showBasicsFlash(context, 'Unable to fetch Current Bill', textColor: Constants.kWhiteColor, bgColor: Constants.kWarningLightColor);
      }
    });
  }

  _showResults(List bill, dynamic month, {fileUrl}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        child: ScreenModal(
          title: "$month",
          titleColor: Constants.kPrimaryColor,
          isLoading: false,
          height: 0.9,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Constants.kSizeHeight_10,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: GText(
                  textData: "PAYMENT MADE SUBSEQUENT TO DATE OF THIS BILL WILL REFLECT ON YOUR NEXT BILL",
                  textFont: Constants.kFontLight,
                  textSize: 12.sp,
                  textColor: Constants.kWarningColor,
                  textMaxLines: 4,
                ),
              ),
              Constants.kSizeHeight_10,
              Table(
                  border: TableBorder.symmetric(
                      inside: BorderSide(
                    width: 1,
                  )),
                  columnWidths: {
                    0: FractionColumnWidth(.35),
                  },
                  children: _billRows(bill)),
              Constants.kSizeHeight_5,
              buildElevatedButton(
                title: "View Bill",
                borderRadius: 10.w,
                onPressed: () {
                  _openFile(fileUrl);
                },
              ),
              Constants.kSizeHeight_10,
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    _loadMeter();
    super.initState();
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
              title: "Account Info",
              actionButton: Container(
                margin: EdgeInsets.only(top: 22.h, right: 10.w),
                child: IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Constants.kWhiteColor,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditMeterDetails(
                          meterInfo: _meter,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(image: Constants.kBgTwo, fit: BoxFit.cover, colorFilter: ColorFilter.linearToSrgbGamma()),
              ),
            ),
            SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Constants.indexHorizontalSpace,
                  vertical: Constants.indexVerticalSpace,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      height: 100.h,
                      child: LiquidWave(
                        title: "Customer Number",
                        body: "${formatCustomerAccountNumber(_meter["account_number"])}",
                      ),
                    ),
                    Constants.kSizeHeight_10,
                    GText(
                      textData: _isOwing ? "You owe this amount" : "Your balance is",
                      textColor: Constants.kPrimaryColor,
                      textSize: 10.sp,
                      textAlign: TextAlign.center,
                    ),
                    Constants.kSizeHeight_5,
                    Center(
                      child: ShadowText(
                        textData: "GHS $_amount",
                        textStyle: TextStyle(
                          color: _isOwing ? Colors.orange : Constants.kPrimaryColor,
                          fontSize: 18.sp,
                        ),
                      ),
                    ),
                    Constants.kSizeHeight_10,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(_billLoading ? Constants.kWhiteColor : Constants.kPrimaryLightColor),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  side: BorderSide(
                                    color: _billLoading ? Constants.kWhiteColor : Constants.kPrimaryColor,
                                  ),
                                ),
                              ),
                            ),
                            child: _billLoading
                                ? CircularLoader(
                                    loaderColor: Constants.kPrimaryColor,
                                    isSmall: true,
                                  )
                                : GText(
                                    textData: "View Current Bill",
                                    textSize: 12.sp,
                                    textColor: Constants.kPrimaryColor,
                                    textFont: Constants.kFontLight,
                                  ),
                            onPressed: () {
                              if (!_billLoading) _getCurrentBill();
                            },
                          ),
                        ),
                        Constants.kSizeWidth_10,
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 10.0)],
                            ),
                            child: TextButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all<Color>(Constants.kPrimaryColor),
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    side: BorderSide(
                                      color: Constants.kWhiteColor,
                                    ),
                                  ),
                                ),
                              ),
                              child: GText(
                                textData: "Pay Bill",
                                textSize: 12.sp,
                                textColor: Constants.kWhiteColor,
                                textFont: Constants.kFontLight,
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PayBill(
                                      meter: _meter,
                                      hasOldBalance: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    Constants.kSizeHeight_10,
                    buildInfoCard(
                      canEdit: true,
                      title: "Alias",
                      body: "${_meter["meter_alias"] == null ? "Not "
                          "set" : _meter["meter_alias"]}",
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditAlias(
                              meterInfo: _meter,
                            ),
                          ),
                        );
                      },
                    ),
                    buildInfoCard(
                      canEdit: false,
                      title: "Meter Number",
                      body: "${_meter["meter_number"]}",
                    ),
                    buildInfoCard(
                      canEdit: false,
                      title: "Meter Type",
                      body: "${_meter["meter_type"]}",
                    ),
                    buildInfoCard(
                      canEdit: false,
                      title: "Account Name",
                      body: "${_meter["account_name"]}",
                    ),
                    buildInfoCard(
                      canEdit: false,
                      title: "Primary Phone",
                      body: "${_meter["primary_phone_number"] == null ? "Not"
                          " provided" : getActualPhone(_meter["primary_phone_number"])}",
                    ),
                    buildInfoCard(
                      canEdit: true,
                      title: "Secondary Phone",
                      body: "${_meter["secondary_phone_number"] == null ? "Not "
                          "provided" : getActualPhone(_meter["secondary_phone_number"])}",
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditSecondaryPhoneNumber(
                              meterInfo: _meter,
                            ),
                          ),
                        );
                      },
                    ),
                    buildInfoCard(
                      canEdit: true,
                      title: "Email Address",
                      body: "${_meter["email_address"] == '' ? "Not "
                          "provided" : _meter["email_address"]}",
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditMeterEmailAddress(
                              meterInfo: _meter,
                            ),
                          ),
                        );
                      },
                    ),
                    buildInfoCard(
                      canEdit: false,
                      title: "Digital Address",
                      body: "${_meter["digital_address"] == null ? "Not "
                          "available" : formatDigitalAddress(_meter["digital_address"])}",
                    ),
                    buildInfoCard(
                      canEdit: false,
                      title: "Service Category",
                      body: "${_meter["service_category_name"]}",
                    ),
                    buildInfoCard(
                      canEdit: false,
                      title: "District Name",
                      body: "${_meter["district_name"] == null ? "Not "
                          "available" : _meter["district_name"]}",
                    ),
                    buildInfoCard(
                      canEdit: false,
                      title: "Region Name",
                      body: "${_meter["region_name"] == null ? "Not "
                          "available" : _meter["region_name"]}",
                    ),
                    buildInfoCard(
                      canEdit: false,
                      title: "Last Bill Amount",
                      body: "GHS ${_meter["last_bill_amount"]}",
                      hasTrailingWidget: true,
                      trailingWidget: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GText(
                            textData: "Last Read: "
                                "${_meter['last_reading']}",
                            textSize: 9.sp,
                            textAlign: TextAlign.right,
                          ),
                          Constants.kSizeHeight_5,
                          GText(
                            textData: " "
                                "${timeAgo.format(DateTime.parse(_meter['last_bill_date']))}",
                            textSize: 9.sp,
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                    Constants.kSizeHeight_10,
                    buildOutlinedButton(
                      title: "Remove Account",
                      bgColor: Constants.kWhiteColor,
                      textColor: Constants.kRedColor,
                      titleFont: Constants.kFontMedium,
                      textSize: 12.sp,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        showDialog(
                          context: context,
                          builder: (_) => ConfirmDialog(
                            title: "Confirm Action",
                            content: "Do you want to remove this"
                                " account "
                                "(${formatCustomerAccountNumber(_meter["account_number"])})"
                                " ?",
                            confirmText: "Yes",
                            confirmTextColor: Constants.kPrimaryColor,
                            confirm: () => _removeMeter(_meter["meter_id"]),
                          ),
                        );
                      },
                    ),
                    Constants.kSizeHeight_50,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Card buildInfoCard({required bool canEdit, String? title, String? body, Color? cardColor, bool hasTrailingWidget = false, Widget? trailingWidget, VoidCallback? onPressed}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.w),
      ),
      color: cardColor ?? null,
      elevation: 1,
      child: ListTile(
        title: GText(
          textData: title ?? "Null",
          textSize: 8.sp,
        ),
        subtitle: Container(
          padding: EdgeInsets.symmetric(vertical: 5.h),
          child: GText(
            textData: body ?? "Null",
            textSize: 14.sp,
            textColor: Constants.kPrimaryColor,
          ),
        ),
        trailing: canEdit
            ? InkWell(
                child: Icon(
                  Icons.edit,
                  color: Constants.kPrimaryColor,
                ),
                onTap: onPressed ??
                    () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditMeterDetails(
                            meterInfo: widget.meterInfo,
                          ),
                        ),
                      );
                    },
              )
            : !hasTrailingWidget
                ? Icon(
                    Icons.circle,
                    color: Colors.grey[200],
                  )
                : trailingWidget,
      ),
    );
  }

  _requestWritePermission() async {
    if (!mounted) return;
    setState(() {
      _allowWriteFile = true;
    });
  }

  Future<String> _getDirectoryPath() async {
    dynamic path = await getLocalPath('reports');
    return path;
  }

  Future<void> _openFile(pdfPath) async {
    String _url = Endpoints.public + pdfPath;
    mixpanel?.track('View Bill', properties: {"fileUrl": _url});
    String _extension = _url.substring(_url.lastIndexOf("/"));
    _getDirectoryPath().then((path) {
      File f = File(path + "$_extension");
      if (f.existsSync()) {
        OpenFile.open(f.path, type: "application/pdf");
        //  mimeType: "com.adobe.pdf");
        return;
      }
      _downloadFile(_url, "$path/$_extension", actualPath: pdfPath);
    });
  }

  Future _downloadFile(String url, path, {actualPath}) async {
    _dio = Dio();
    if (!_allowWriteFile) {
      _requestWritePermission();
    }
    try {
      ProgressDialog progressDialog = ProgressDialog(context, type: ProgressDialogType.Normal);
      progressDialog.style(
        message: "Downloading File",
        messageTextStyle: TextStyle(
          fontFamily: Constants.kFontLight,
        ),
      );
      progressDialog.show();

      await _dio.download(url, path, onReceiveProgress: (rec, total) {
        setState(() {
          _progress = ((rec / total) * 100).toStringAsFixed(0) + "%";
          progressDialog.update(message: "Downloading $_progress");
        });
      });
      progressDialog.hide();
      _openFile(actualPath);
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
