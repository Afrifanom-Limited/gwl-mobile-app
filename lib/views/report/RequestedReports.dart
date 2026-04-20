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
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/PageTransitions.dart';
import 'package:gwcl/helpers/ProgressDialog.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/models/ReportRequest.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/report/Report.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../mixpanel.dart';

class RequestedReports extends StatefulWidget {
  static const String id = "/requested_reports";
  @override
  _RequestedReportsState createState() => _RequestedReportsState();
}

class _RequestedReportsState extends State<RequestedReports> {
  bool _loading = false, _refreshing = false;
  var _reportRequests = List.empty(growable: true), _customer;
  late ReportRequest _reportRequest;

  _loadReportRequests() async {
    var _localDb = new LocalDatabase();
    var _res = await _localDb.getReportRequests();
    if (mounted) {
      setState(() => this._reportRequests = _res);
      _fetchReportRequests();
      return;
    }
  }

  _loadCustomerInfo() async {
    var _localDb = new LocalDatabase();
    _customer = await _localDb.getCustomer();
    if (mounted) {
      _loadReportRequests();
    }
  }

  _fetchReportRequests() async {
    setState(() => hasData(_reportRequests) ? _refreshing = true : _loading = true);
    RestDataSource _request = new RestDataSource();
    _request.get(context, url: Endpoints.report_requests).then((Map response) {
      if (response[Constants.success]) {
        var records = response[Constants.response]["records"];
        _onRequestSuccess(records);
      } else {
        if (mounted)
          setState(() {
            _refreshing = false;
            _loading = false;
          });
        _onRequestFailed(Constants.unableToRefresh);
      }
    });
  }

  @override
  void initState() {
    _loadCustomerInfo();
    mixpanel?.track('View Statement');
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
              title: "Statements",
              actionButton: Container(
                margin: EdgeInsets.only(top: 18.h, right: 10.w),
                child: IconButton(
                  icon: _refreshing
                      ? CircularLoader(
                          loaderColor: Constants.kWhiteColor,
                          isSmall: true,
                          isDark: true,
                        )
                      : Icon(
                          Icons.refresh,
                          color: Constants.kWhiteColor,
                        ),
                  onPressed: () {
                    _loadReportRequests();
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
            _refreshing
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        child: SizedBox(
                          height: 3.h,
                          child: BarLoader(
                            barColor: Constants.kPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Constants.indexHorizontalSpace,
                vertical: Constants.indexVerticalSpace,
              ),
              child: !hasData(_reportRequests)
                  ? Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: GText(
                            textData: "You have no Statements. "
                                "To make a request for either statement of billing"
                                " or statement of payment, kindly tap on"
                                " the '+' icon button",
                            textAlign: TextAlign.center,
                            textSize: 13.sp,
                            textColor: Constants.kGreyColor,
                            textMaxLines: 5,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.only(bottom: 60.h),
                      separatorBuilder: (BuildContext context, int index) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            height: 0.5,
                            width: MediaQuery.of(context).size.width / 1.3,
                            child: Divider(),
                          ),
                        );
                      },
                      itemCount: _reportRequests.length,
                      itemBuilder: (BuildContext context, int index) {
                        Map req = _reportRequests[index];
                        return ReportRequestItem(
                          reportReq: req,
                          key: UniqueKey(),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          elevation: 20,
          hoverColor: Constants.kPrimaryColor,
          backgroundColor: Constants.kPrimaryColor,
          autofocus: true,
          label: Text("Request Statement"),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pushReplacement(
              context,
              FadeRoute(
                page: Report(
                  customer: _customer,
                  reportType: 'billing',
                ),
              ),
            );
          },
          icon: Icon(Icons.add),
          tooltip: 'Report Request',
        ),
      ),
    );
  }

  _onRequestSuccess(List<dynamic> reportRequests) async {
    var _localDb = new LocalDatabase();
    // await _localDb.deleteAllReportRequest();
    for (var i = 0; i < reportRequests.length; i++) {
      _reportRequest = ReportRequest.map(reportRequests[i]);
      await _localDb.addReportRequest(_reportRequest);
    }
    var _res = await _localDb.getReportRequests();
    if (mounted) {
      setState(() {
        _loading = false;
        _refreshing = false;
        _reportRequests = _res;
      });
    }
  }

  _onRequestFailed(dynamic errorText) async {
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
    //   bgColor: Constants.kWarningLightColor,
    // );
  }
}

class ReportRequestItem extends StatefulWidget {
  final dynamic reportReq;

  ReportRequestItem({
    Key? key,
    required this.reportReq,
  }) : super(key: key);

  @override
  _ReportRequestItemState createState() => _ReportRequestItemState();
}

class _ReportRequestItemState extends State<ReportRequestItem> {
  bool _allowWriteFile = false, _isDownloaded = false, _deletingRecord = false, _isDeleted = false;

  late Dio _dio;
  String progress = "";

  _requestWritePermission() async {
    var storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) {
      setState(() {
        _allowWriteFile = true;
      });
    }
  }

  Future<String> _getDirectoryPath() async {
    dynamic path = await getLocalPath('reports');
    return path;
  }

  _checkIfFileExists(pdfPath) {
    String _url = Endpoints.public + pdfPath;
    String _extension = _url.substring(_url.lastIndexOf("/"));
    _getDirectoryPath().then((path) {
      File f = File(path + "$_extension");
      if (f.existsSync()) {
        setState(() => _isDownloaded = true);
      }
    });
    setState(() => _isDownloaded = false);
  }

  Future<void> _openFile(pdfPath) async {
    try {
      String _url = Endpoints.public + pdfPath;
      String _extension = _url.substring(_url.lastIndexOf("/"));
      _getDirectoryPath().then((path) {
        File f = File(path + "$_extension");
        if (f.existsSync()) {
          OpenFile.open(f.path, type: "application/pdf");
          //  mimeType: "com.adobe.pdf");
          return;
        }
        _downloadFile(_url, "$path/$_extension");
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _deleteFile(pdfPath) async {
    try {
      String _url = Endpoints.public + pdfPath;
      String _extension = _url.substring(_url.lastIndexOf("/"));
      _getDirectoryPath().then((path) {
        File f = File(path + "$_extension");
        if (f.existsSync()) {
          f.deleteSync();
          return;
        }
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future _downloadFile(String url, path) async {
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
        if (mounted)
          setState(() {
            progress = ((rec / total) * 100).toStringAsFixed(0) + "%";
            progressDialog.update(message: "Downloading $progress");
          });
      });
      progressDialog.hide();
      setState(() => _isDownloaded = true);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  getStatementTitle(String requestType) {
    if (requestType == 'BILLING') {
      return 'STATEMENT OF BILLING';
    } else {
      return 'STATEMENT OF PAYMENT';
    }
  }

  @override
  void initState() {
    super.initState();
    if (_checkIfDocumentIsReport()) _checkIfFileExists(widget.reportReq['report_file_link']);
  }

  final _format = DateFormat("dd MMMM, yyyy");
  final _monthFormat = DateFormat("MMMM");
  final _fullDateFormat = DateFormat("dd MMMM, yyyy HH:mm");
  final _billMonthFormat = DateFormat("MMMM, yyyy");
  String _formatDate(DateTime date, DateFormat format) {
    try {
      return format.format(date);
    } catch (e) {}
    return '';
  }

  bool _checkIfDocumentIsReport() {
    if (widget.reportReq['report_file_link'] == null || widget.reportReq['report_file_link'] == "null") {
      return false;
    }
    return true;
  }

  _deleteReport() async {
    setState(() {
      _deletingRecord = true;
      _isDeleted = false;
    });
    RestDataSource _request = new RestDataSource();
    _request.get(context, url: Endpoints.report_requests_delete.replaceFirst("{id}", "${widget.reportReq['report_request_id']}")).then((Map response) async {
      if (mounted)
        setState(() {
          _deletingRecord = false;
          _isDeleted = true;
        });
      if (response[Constants.success]) {
        var _localDb = new LocalDatabase();
        await _localDb.deleteReportRequest(widget.reportReq['report_request_id'].toString());
        _deleteFile(widget.reportReq['report_file_link']);
      } else {
        if (mounted)
          showBasicsFlash(
            context,
            response[Constants.message].toString().replaceAll(RegExp(Constants.errorFilter), ""),
            textColor: Constants.kWhiteColor,
            bgColor: Constants.kWarningLightColor,
          );
      }
    });
  }

  bool _isSameMonth() {
    dynamic _startMonth = _formatDate(DateTime.parse(widget.reportReq['start_date']), _monthFormat);
    dynamic _endMonth = _formatDate(DateTime.parse(widget.reportReq['end_date']), _monthFormat);
    if (_startMonth == _endMonth) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return _isDeleted
        ? Container()
        : Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: GestureDetector(
              onLongPress: () async {
                HapticFeedback.lightImpact();
                var optionSelection;
                if (Platform.isAndroid) {
                  optionSelection = await optionAndroidDialog(context);
                } else if (Platform.isIOS) {
                  optionSelection = await optionIosDialog(context);
                }
                if (optionSelection == Constants.delete) {
                  _deleteReport();
                }
              },
              child: ListTile(
                contentPadding: EdgeInsets.all(0),
                onTap: () {
                  showBasicsFlash(
                    context,
                    !_checkIfDocumentIsReport()
                        ? "Your request was not found. Long-press for more options"
                        : 'Statement is ready. Tap on the "Download/View" button.'
                            ' Long press for more options',
                    duration: Duration(seconds: 3),
                    textColor: !_checkIfDocumentIsReport() ? Constants.kRedLightColor : Constants.kAccentColor,
                    bgColor: Constants.kWhiteColor,
                  );
                },
                title: Padding(
                  padding: EdgeInsets.symmetric(vertical: 5.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          GText(
                            textData: "${getStatementTitle(widget.reportReq['report_type'].toString().toUpperCase())}",
                            textColor: Constants.kPrimaryColor,
                            textFont: Constants.kFontMedium,
                            textSize: 12.sp,
                          ),
                          Constants.kSizeWidth_5,
                          if (_checkIfDocumentIsReport())
                            Icon(
                              Icons.check_circle,
                              color: Constants.kGreenLightColor,
                              size: 15.sp,
                            )
                        ],
                      ),
                      Constants.kSizeHeight_5,
                      GText(
                        textData: "Requested on ${_formatDate(DateTime.parse(widget.reportReq['date_created']), _fullDateFormat)}",
                        textSize: 9.sp,
                        textColor: Constants.kGreyColor,
                      ),
                    ],
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isSameMonth())
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Table(
                            border: TableBorder.symmetric(
                                inside: BorderSide(
                              width: 1,
                            )),
                            columnWidths: {
                              0: FractionColumnWidth(.25),
                            },
                            children: [
                              tableRow("From", "${_formatDate(DateTime.parse(widget.reportReq['start_date']), _format)}"),
                              tableRow("To", "${_formatDate(DateTime.parse(widget.reportReq['end_date']), _format)}"),
                            ],
                          ),
                        ],
                      ),
                    if (_isSameMonth())
                      Table(
                        border: TableBorder.symmetric(
                            inside: BorderSide(
                          width: 1,
                        )),
                        columnWidths: {
                          0: FractionColumnWidth(.25),
                        },
                        children: [
                          tableRow("For", "${_formatDate(DateTime.parse(widget.reportReq['end_date']), _billMonthFormat)}"),
                        ],
                      ),
                    if (!_checkIfDocumentIsReport())
                      Column(
                        children: [
                          Constants.kSizeHeight_5,
                          GText(
                            textData: "Status: Report not found",
                            textColor: Constants.kRedColor,
                            textSize: 10.sp,
                            textFont: Constants.kFontLight,
                            textMaxLines: 1,
                          ),
                        ],
                      ),
                    Constants.kSizeHeight_5,
                    _deletingRecord
                        ? BarLoader(
                            barColor: Constants.kPrimaryColor,
                            thickness: 1.h,
                          )
                        : _checkIfDocumentIsReport()
                            ? buildOutlinedButton(
                                bgColor: _isDownloaded ? Constants.kPrimaryColor : Constants.kWhiteColor,
                                textColor: _isDownloaded ? Constants.kWhiteColor : Constants.kWarningColor,
                                title: _isDownloaded ? "View Bill" : "Download Statement",
                                borderRadius: 10.w,
                                titleFont: Constants.kFontMedium,
                                textSize: 11.sp,
                                onPressed: () {
                                  _openFile(widget.reportReq['report_file_link']);
                                },
                              )
                            : Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),
                  ],
                ),
              ),
            ),
          );
  }
}
