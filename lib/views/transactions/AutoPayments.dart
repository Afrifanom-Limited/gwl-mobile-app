import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gwcl/helpers/BlinkingWidget.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/ColumnBuilder.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/models/AutoPayment.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Functions.dart';

class AutoPayments extends StatefulWidget {
  static const String id = "/auto_payments";
  @override
  _AutoPaymentsState createState() => _AutoPaymentsState();
}

class _AutoPaymentsState extends State<AutoPayments> {
  ScrollController _scrollController = ScrollController();
  bool _loading = false, _loadingMore = false, _hasMoreRecords = false;
  var _autoPayments = List.empty(growable: true);
  int _page = 1;

  _fetchAutoPayments() async {
    setState(() => _loading = true);
    RestDataSource _request = new RestDataSource();
    _request.get(context, url: Endpoints.auto_payments).then((Map response) {
      if (response[Constants.success]) {
        var records = response[Constants.response]["records"];
        var _totalPage = response[Constants.response]["total_page"];
        if (_totalPage > _page) {
          setState(() {
            this._page = _page + 1;
            _hasMoreRecords = true;
          });
        }
        _onRequestSuccess(records);
      } else {
        if (mounted) setState(() => _loading = false);
        _onRequestFailed(Constants.unableToRefresh);
      }
    });
  }

  void _disposeScrollController() {
    _scrollController.dispose();
  }

  @override
  void dispose() {
    _disposeScrollController();
    super.dispose();
  }

  @override
  void initState() {
    _fetchAutoPayments();
    super.initState();
    _scrollController.addListener(() {
      double _maxScroll = _scrollController.position.maxScrollExtent;
      double _currentScroll = _scrollController.position.pixels;
      // double _delta = MediaQuery.of(context).size.height * 0.5;
      if (_maxScroll == _currentScroll) {
        if (!_loadingMore) _loadMoreRecords();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.h),
        child: Container(
          color: Constants.kPrimaryColor,
          child:
            GeneralHeader(
              title: "My Auto-Payments",
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
          _loading
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
          _loadingMore
              ? Column(
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
                )
              : Container(),
          SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 10.w,
                vertical: Constants.indexVerticalSpace,
              ),
              child: Column(
                children: [
                  !hasData(_autoPayments)
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20.w, vertical: 20.h),
                            child: GText(
                              textData: _loading
                                  ? " "
                                  : "No auto-payments to display",
                              textAlign: TextAlign.center,
                              textSize: 13.sp,
                              textColor: Constants.kGreyColor,
                              textMaxLines: 5,
                            ),
                          ),
                        )
                      : ColumnBuilder(
                          itemCount: _autoPayments.length,
                          itemBuilder: (BuildContext context, int index) {
                            AutoPayment autoPayment =
                                AutoPayment.map(_autoPayments[index]);
                            return AutoPaymentItem(
                              key: UniqueKey(),
                              autoPayment: autoPayment,
                            );
                          },
                        ),
                  Constants.kSizeHeight_50
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _onRequestSuccess(List<dynamic> autoPayments) async {
    if (mounted) {
      setState(() => this._autoPayments = autoPayments);
      setState(() {
        _loading = false;
      });
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
  }

  _loadMoreRecords() {
    if (_hasMoreRecords) {
      HapticFeedback.lightImpact();
      setState(() => _loadingMore = true);
      var _moreRecords = List.empty(growable: true);
      RestDataSource _request = new RestDataSource();
      _request
          .get(
        context,
        url: Endpoints.notifications + "?page=$_page&limit=10",
      )
          .then((Map response) async {
        if (mounted) setState(() => _loadingMore = false);
        if (response[Constants.success]) {
          HapticFeedback.lightImpact();
          _moreRecords = response[Constants.response]["records"];
          var _totalPage = response[Constants.response]["total_page"];
          if (mounted) setState(() => this._autoPayments.addAll(_moreRecords));
          if (_totalPage > _page) {
            setState(() {
              this._page = _page + 1;
              _hasMoreRecords = true;
            });
          } else {
            setState(() {
              _hasMoreRecords = false;
            });
          }
        } else {
          _onRequestFailed(Constants.unableToRefresh);
        }
      });
    }
  }
}

class AutoPaymentItem extends StatefulWidget {
  final AutoPayment autoPayment;

  const AutoPaymentItem({Key? key, required this.autoPayment})
      : super(key: key);

  @override
  State<AutoPaymentItem> createState() => _AutoPaymentItemState();
}

class _AutoPaymentItemState extends State<AutoPaymentItem> {
  bool _showRecord = true;
  RestDataSource _request = new RestDataSource();
  _deleteAutoPayment() async {
    _request
        .get(context,
            url: Endpoints.auto_payments_delete
                .replaceFirst("{valOne}", "${widget.autoPayment.autoPaymentId}")
                .replaceFirst(
                    "{valTwo}", "${widget.autoPayment.transactionId}"))
        .then((Map response) async {
      if (response[Constants.success]) {
      } else {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return _showRecord
        ? Card(
            child: Container(
              child: ListTile(
                onTap: () {
                  HapticFeedback.lightImpact();
                },
                contentPadding:
                    EdgeInsets.symmetric(vertical: 15.h, horizontal: 10.w),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GText(
                      textData:
                          "ACC: ${formatCustomerAccountNumber(widget.autoPayment.accountNumber)}",
                      textFont: Constants.kFontMedium,
                      textSize: 14.sp,
                      textMaxLines: 10,
                    ),
                    Constants.kSizeHeight_5,
                    GText(
                      textData: "Water bills for account number "
                          "${formatCustomerAccountNumber(widget.autoPayment.accountNumber)} "
                          "will automatically be "
                          "paid "
                          "on a scheduled date using wallet number ${widget.autoPayment.msisdn}.",
                      textFont: Constants.kFontLight,
                      textSize: 11.sp,
                      textMaxLines: 10,
                    ),
                    Constants.kSizeHeight_5,
                    buildOutlinedButton(
                      bgColor: Constants.kWhiteColor,
                      textColor: Constants.kRedColor,
                      title: "Cancel Now",
                      borderRadius: 10.w,
                      titleFont: Constants.kFontMedium,
                      textSize: 11.sp,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => ConfirmDialog(
                            title: "Confirm Action",
                            content: "This will remove account number: "
                                "${formatCustomerAccountNumber(widget.autoPayment.accountNumber)} from the Auto-Payment service. Do you want to continue?",
                            confirmText: "Yes",
                            confirmTextColor: Constants.kPrimaryColor,
                            confirm: () async {
                              setState(() => this._showRecord = false);
                              _deleteAutoPayment();
                            },
                          ),
                        );
                      },
                    )
                  ],
                ),
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BlinkingWidget(
                      widget: Icon(
                        Icons.circle,
                        color: Constants.kGreenLightColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : Container();
  }
}
