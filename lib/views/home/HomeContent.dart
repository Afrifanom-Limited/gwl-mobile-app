import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/BlinkingWidget.dart';
import 'package:gwcl/helpers/ColumnBuilder.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/FlashHelper.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/models/Meter.dart';
import 'package:gwcl/models/Payment.dart';
import 'package:gwcl/models/Vendor.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/views/complaint/ComplaintsList.dart';
import 'package:gwcl/views/home/AddAccount.dart';
import 'package:gwcl/views/home/Feeds.dart';
import 'package:gwcl/views/meter/MeterComponents.dart';
import 'package:gwcl/views/report/Report.dart';
import 'package:gwcl/views/report/RequestedReports.dart';
import 'package:gwcl/views/transactions/AutoPayments.dart';
import 'package:gwcl/views/transactions/PayBillForOthers.dart';
import 'package:gwcl/views/transactions/PaymentComponents.dart';
import 'package:gwcl/views/vendor/VendorComponents.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mixpanel.dart';
import '../../templates/Dialogs.dart';

enum DashButtonType { payBills, meter, notifications, complaints, reportRequests, autoPayments }

class MenuData {
  final AssetImage assetImage;
  final String title;
  final int alertCount;
  final VoidCallback? onPressed;
  final DashButtonType? buttonType;

  MenuData({
    required this.assetImage,
    required this.title,
    this.alertCount = 0,
    this.onPressed,
    this.buttonType,
  });
}

class HomeContent extends StatefulWidget {
  final dynamic customer;
  final BuildContext? rootContext;
  const HomeContent({Key? key, required this.customer, this.rootContext}) : super(key: key);

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loadingMeters = false, _loadingVendors = false, _loadingPaymentHistory = false, _loadingLocalMeters = false;
  var _meters = List.empty(growable: true);
  var _vendors = List.empty(growable: true);
  var _payments = List.empty(growable: true);
  late Meter _meter;
  late Vendor _vendor;
  late Payment _payment;
  bool? _showQuickAccess;
  var _localDb = new LocalDatabase();
  bool _newFeedsAvailable = false;

  _loadMeters() async {
    setState(() => _loadingLocalMeters = true);
    var _res = await _localDb.getMetersLimited();
    if (mounted) {
      setState(() => _loadingLocalMeters = false);
      if (_res.length < 1) {
        _fetchMeters();
      } else {
        setState(() => this._meters = _res);
      }
      _loadPaymentHistory();
      return;
    }
  }

  _reloadMeters() async {
    setState(() => _meters = List.empty(growable: true));
    await _localDb.deleteAllMeter();
    _fetchMeters();
  }

  _fetchMeters() async {
    setState(() => _loadingMeters = true);
    RestDataSource _request = new RestDataSource();
    _request.get(context, url: Endpoints.meters).then((Map response) {
      if (mounted) setState(() => _loadingMeters = false);
      if (response[Constants.success]) {
        var records = response[Constants.response]["records"];
        _onRequestSuccess(records);
      } else {
        _onRequestFailed(Constants.unableToRefresh);
      }
    });
  }

  _loadVendors() async {
    var _res = await _localDb.getVendors();
    if (mounted) {
      if (_res.length < 1) {
        _fetchVendors();
      } else {
        setState(() => this._vendors = _res);
      }
      return;
    }
  }

  _reloadVendors() async {
    setState(() => _vendors = List.empty(growable: true));
    await _localDb.deleteAllVendors();
    _fetchVendors();
  }

  _fetchVendors() async {
    setState(() => _loadingVendors = true);
    RestDataSource _request = new RestDataSource();
    _request.get(context, url: Endpoints.vendors).then((Map response) {
      if (mounted) setState(() => _loadingVendors = false);
      if (response[Constants.success]) {
        var records = response[Constants.response]["records"];
        _onVendorsRequestSuccess(records);
      } else {
        _onRequestFailed(Constants.unableToRefresh);
      }
    });
  }

  _loadPaymentHistory() async {
    var _res = await _localDb.getPaymentHistory();
    if (mounted) {
      if (_res.length < 1) {
        _fetchPaymentHistory();
      } else {
        setState(() => this._payments = _res);
        _fetchPaymentHistory();
      }
    }
  }

  _fetchPaymentHistory() async {
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    var _canUpdateMeter = _localStorage.getBool(Constants.canUpdateMeter);
    if (_canUpdateMeter == null) {
      if (mounted) {
        Timer(new Duration(seconds: 1), () {
          if (mounted) setState(() => _loadingPaymentHistory = true);
          RestDataSource _request = new RestDataSource();
          if(!context.mounted) return;
          _request.get(context, url: Endpoints.payment_history).then((Map response) async {
            if (mounted) setState(() => _loadingPaymentHistory = false);
            if (response[Constants.success]) {
              var records = response[Constants.response]["records"];
              for (var i = 0; i < records.length; i++) {
                _payment = Payment.map(records[i]);
                await _localDb.addPaymentHistory(_payment);
              }
              if (mounted) setState(() => this._payments = records);
            } else {
              _onRequestFailed(Constants.unableToRefresh);
            }
          });
        });
      }
    }
  }

  _toggleQuickAccess(selectedValue) async {
    try {
      SharedPreferences _localStorage = await SharedPreferences.getInstance();
      if (selectedValue) {
        await _localStorage.setBool(Constants.showQuickAccess, true);
        if (mounted) setState(() => this._showQuickAccess = true);
      } else {
        await _localStorage.remove(Constants.showQuickAccess);
        if (mounted) setState(() => this._showQuickAccess = false);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  _loadQuickAccessOption() async {
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    bool? _showAccess = _localStorage.getBool(Constants.showQuickAccess);
    if (_showAccess == null || _showAccess == false)
      setState(() => this._showQuickAccess = false);
    else
      setState(() => this._showQuickAccess = true);
  }

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Once the Live Updates tab is opened, clear the blinking indicator.
      if (_tabController.index == 1 && _newFeedsAvailable) {
        if (mounted) setState(() => _newFeedsAvailable = false);
      }
    });
    _loadMeters();
    _loadVendors();
    super.initState();
    _loadQuickAccessOption();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
    // _webViewController?.clearCache();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(90.h),
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorWeight: 3.0,
            tabAlignment: TabAlignment.center,
            labelStyle: TextStyle(fontFamily: Constants.kFont, fontSize: 15.sp, fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(fontFamily: Constants.kFont, fontSize: 15.sp),
            labelColor: Constants.kPrimaryColor,
            unselectedLabelColor: Colors.black87,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: "My Activity"),
              Tab(
                child: Row(
                  children: <Widget>[
                    GText(
                      textData: "Live Updates",
                      textSize: 13.sp,
                      textFont: Constants.kFont,
                    ),
                    Constants.kSizeWidth_5,
                    Visibility(
                      // show the blinking circle if new feeds are available
                      visible: _newFeedsAvailable == true,
                      child: BlinkingWidget(
                        widget: Icon(
                          Icons.circle,
                          size: 8.sp,
                          color: Colors.green,
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      //Announcements
      body: TabBarView(
        controller: _tabController,
        children: [
          _activitySection(),
          Feeds(
            newFeedsAvailable: _newFeedsAvailable,
            onNewFeedsAvailable: (bool hasNewFeeds) {
              // Do not show blinking state while user is already on the feeds tab.
              if (_tabController.index == 1) return;
              if (mounted && _newFeedsAvailable != hasNewFeeds) {
                setState(() => _newFeedsAvailable = hasNewFeeds);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _activitySection() {
    return ListView(
      children: [
        Constants.kSizeHeight_10,
        // Container(
        //   padding: EdgeInsets.symmetric(horizontal: 18.w),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: <Widget>[
        //       Column(
        //         crossAxisAlignment: CrossAxisAlignment.start,
        //         children: <Widget>[
        //           Constants.kSizeHeight_10,
        //           GText(
        //             textData: "${greeting()},",
        //             textSize: 15.sp,
        //             textMaxLines: 1,
        //             textColor: Constants.kPrimaryColor,
        //             textFont: Constants.kFontMedium,
        //           ),
        //           GText(
        //             textData: "What would you like to do?",
        //             textSize: 13.sp,
        //             textFont: Constants.kFontLight,
        //           ),
        //         ],
        //       ),
        //     ],
        //   ),
        // ),
        Constants.kSizeHeight_20,
        Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 3.h),
          margin: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GText(
                textData: "My Accounts",
                textMaxLines: 2,
                textSize: 12.sp,
                textFont: Constants.kFontMedium,
              ),

              FilledButton.icon(
                icon: Icon(Icons.sync),
                label: Text("Sync Accounts"),
                style: FilledButton.styleFrom(
                  shape: StadiumBorder(),
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  if (_meters.length > 0) {
                    showDialog(
                      context: context,
                      builder: (_) => ConfirmDialog(
                        title: "Sync Accounts",
                        content: "This will sync your account(s)"
                            " with servers and load newly added "
                            "accounts from other devices.",
                        confirmText: "Ok, continue",
                        cancelText: "Cancel",
                        confirmTextColor: Constants.kPrimaryColor,
                        confirm: () {
                          _reloadMeters();
                        },
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PayBillForOthers(),
                      ),
                    );
                  }
                },
              )

              // if (_meters.length > 0)
              //   InkWell(
              //     child: GText(
              //       textData: "View All",
              //       textFont: Constants.kFontMedium,
              //       textColor: Constants.kWarningColor,
              //       textSize: 13.sp,
              //     ),
              //     onTap: () {
              //       HapticFeedback.lightImpact();
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //           builder: (context) => Meters(meters: _meters),
              //         ),
              //       );
              //     },
              //   )
              //
            ],
          ),
        ),
        Constants.kSizeHeight_5,
        Container(
          height: 250.h,
          child: !_loadingLocalMeters
              ? Builder(
                  builder: (BuildContext context) {
                    return ListView.separated(
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext context, int index) {
                        var oddIndex = (index % 2);
                        if (index == _meters.length) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              if (_loadingMeters)
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 30.w),
                                  child: SizedBox(
                                    height: 50,
                                    width: 50,
                                    child: CircularLoader(
                                      loaderColor: Constants.kPrimaryColor,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pushNamed(context, AddAccount.id);
                                },
                                child: Container(
                                  width: 300.w,
                                  height: 210.h,
                                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                                  decoration: BoxDecoration(
                                    color: Constants.kPrimaryLightColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Constants.kPrimaryColor.withOpacity(0.2)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Constants.kPrimaryColor.withOpacity(0.2),
                                        spreadRadius: 0,
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 14.w, horizontal: 12.h),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add_circle,
                                        color: Constants.kPrimaryColor,
                                        size: 46.sp,
                                      ),
                                      Constants.kSizeHeight_10,
                                      GText(
                                        textData: "Add your Ghana Water account",
                                        textSize: 12.sp,
                                        textColor: Constants.kPrimaryColor,
                                        textFont: Constants.kFont,
                                        textMaxLines: 5,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        return MeterCard(
                          meterCard: _meters[index],
                          textColor: Constants.kWhiteColor,
                          bgImage: Constants.kMeterBgTwo,
                          buttonTextColor: Constants.kPrimaryColor,
                          isLarge: false,
                          isDark: true,
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return Constants.kSizeWidth_10;
                      },
                      itemCount: _meters.length + 1,
                    );
                  },
                )
              : Column(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Container(
                        width: 300.w,
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        decoration: BoxDecoration(
                          color: Constants.kPrimaryLightColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Constants.kPrimaryColor.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Constants.kPrimaryColor.withOpacity(0.2),
                              spreadRadius: 0,
                              blurRadius: 0.0,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.w, horizontal: 12.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        Constants.kSizeHeight_10,
        if (_loadingVendors)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 3.h),
            child: BarLoader(
              barColor: Constants.kPrimaryColor,
              thickness: 2,
            ),
          ),
        if (_vendors.length > 0)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
                margin: EdgeInsets.symmetric(horizontal: 12.w),
                color: Constants.kPrimaryLightColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GText(
                      textData: "VENDING ACCOUNTS",
                      textMaxLines: 2,
                      textSize: 12.sp,
                      textColor: Constants.kPrimaryColor,
                      textFont: Constants.kFontMedium,
                    ),
                    if (_vendors.length > 0)
                      InkWell(
                        child: GText(
                          textData: "Refresh",
                          textFont: Constants.kFontMedium,
                          textColor: Constants.kWarningColor,
                          textSize: 13.sp,
                        ),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _reloadVendors();
                        },
                      )
                  ],
                ),
              ),
              Constants.kSizeHeight_5,
              ColumnBuilder(
                itemCount: _vendors.length,
                itemBuilder: (BuildContext context, int index) {
                  var oddIndex = (index % 2);
                  return VendorCard(
                      vendorCard: _vendors[index],
                      textColor: oddIndex == 0 ? Constants.kPrimaryColor : Constants.kWhiteColor,
                      bgImage: oddIndex == 0 ? Constants.kVendorBgOne : Constants.kVendorBgTwo,
                      isDark: oddIndex == 0 ? false : true,
                      buttonTextColor: Constants.kPrimaryColor);
                },
              ),
            ],
          ),

        // Center(
        //   child: GText(
        //     textData: "QUICK ACCESS",
        //     textMaxLines: 2,
        //     textSize: 12.sp,
        //     textColor: Constants.kPrimaryColor,
        //     textFont: Constants.kFontMedium,
        //   ),
        // ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: BouncingScrollPhysics(),
            itemCount: menu.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: 1.5,
              crossAxisCount: 2,
              crossAxisSpacing: 15.0,
              mainAxisSpacing: 15.0,
            ),
            itemBuilder: (BuildContext context, int index) {
              return InkWell(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  switch (menu[index].buttonType) {
                    case DashButtonType.payBills:
                      // var payBillSelection;
                      // if (Platform.isAndroid) {
                      //   payBillSelection = await payBillOptionAndroid(context);
                      // } else if (Platform.isIOS) {
                      //   payBillSelection = await payBillOptionIos(context);
                      // }
                      // if (payBillSelection == Constants.mySelf) {
                      //   Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //       builder: (context) => PayBill(
                      //         hasOldBalance: false,
                      //       ),
                      //     ),
                      //   );
                      // }
                      // if (payBillSelection == Constants.others) {
                      //   Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //       builder: (context) => PayBillForOthers(),
                      //     ),
                      //   );
                      // }

                      mixpanel?.track('Pay for Others Tab');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PayBillForOthers(),
                        ),
                      );

                      break;
                    case DashButtonType.meter:
                      mixpanel?.track('Add Account');
                      Navigator.pushNamed(context, AddAccount.id);
                      break;
                    case DashButtonType.complaints:
                      Navigator.pushNamed(context, ComplaintsList.id);
                      break;
                    case DashButtonType.reportRequests:
                      Navigator.pushNamed(context, RequestedReports.id);
                      break;
                    case DashButtonType.autoPayments:
                      Navigator.pushNamed(context, AutoPayments.id);
                      break;
                    default:
                      break;
                  }
                },
                child: Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Constants.kGreyColor.withOpacity(0.1),
                            spreadRadius: 3,
                            blurRadius: 2.0,
                            offset: Offset(1, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Image(
                            image: menu[index].assetImage,
                            height: 40.h,
                          ),
                          Constants.kSizeHeight_5,
                          Container(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Center(
                              child: GText(
                                textData: menu[index].title,
                                textColor: Constants.kAccentColor,
                                textSize: 12.sp,
                                textMaxLines: 2,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    if (menu[index].alertCount > 0)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: BlinkingWidget(
                          widget: Icon(
                            Icons.error,
                            color: Constants.kWarningLightColor,
                            size: 20.h,
                          ),
                        ),
                      )
                  ],
                ),
              );
            },
          ),
        ),

        if (_loadingPaymentHistory)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  child: SizedBox(
                    height: 3.h,
                    child: BarLoader(
                      barColor: Constants.kPrimaryColor,
                      thickness: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),

        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Constants.kSizeHeight_20,
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GText(
                  textData: "Recent Transactions",
                  textMaxLines: 2,
                  textSize: 12.sp,
                  textFont: Constants.kFontMedium,
                ),
              ),
              for (int i = 0; i < _payments.length; i++)
                Transaction(
                  payment: _payments[i],
                ),
              Constants.kSizeHeight_20,
              if (_payments.length > 0)
                if (_meters.length > 0)
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.all(20),
                        elevation: 1,
                        shape: StadiumBorder(),
                        backgroundColor: Constants.kPrimaryColor,
                      ),
                      icon: Icon(
                        Icons.list_alt_rounded,
                        size: 40,
                      ),
                      label: GText(
                        textData: "Request Customer Statement",
                        textSize: 13.sp,
                        textColor: Constants.kWhiteColor,
                        textFont: Constants.kFontMedium,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Report(
                              customer: widget.customer,
                              reportType: 'statement',
                              billingReportType: 'multiple',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              Constants.kSizeHeight_20,
            ],
          ),
        ),
        Constants.kSizeHeight_20,
      ],
    );
  }

  _onRequestSuccess(List<dynamic> meters) async {
    for (var i = 0; i < meters.length; i++) {
      _meter = Meter.map(meters[i]);
      await _localDb.addMeter(_meter);
    }
    if (mounted) setState(() => this._meters = meters);
  }

  _onVendorsRequestSuccess(List<dynamic> vendors) async {
    for (var i = 0; i < vendors.length; i++) {
      _vendor = Vendor.map(vendors[i]);
      await _localDb.addVendor(_vendor);
    }
    if (mounted) setState(() => this._vendors = vendors);
  }

  _onRequestFailed(dynamic errorText) async {
    if (mounted) {
      // showDialog(
      //   context: context,
      //   builder: (_) => ErrorDialog(
      //     content: errorText
      //         .toString()
      //         .replaceAll(RegExp(Constants.errorFilter), ""),
      //   ),
      // );
      showBasicsFlash(
        context,
        errorText.toString().replaceAll(RegExp(Constants.errorFilter), ""),
        textColor: Constants.kWhiteColor,
        bgColor: Constants.kWarningLightColor,
      );
    }
  }

  final List<MenuData> menu = [
    MenuData(assetImage: Constants.kMeterIcon, title: 'Add Account', alertCount: 0, buttonType: DashButtonType.meter),
    MenuData(assetImage: Constants.kPaymentIcon, title: 'Pay For Others', alertCount: 0, buttonType: DashButtonType.payBills),
    MenuData(assetImage: Constants.kComplaintIconIcon, title: 'Complaints', alertCount: 0, buttonType: DashButtonType.complaints),
    MenuData(assetImage: Constants.kActivityHistoryIcon, title: 'Statements', alertCount: 0, buttonType: DashButtonType.reportRequests),
    // MenuData(
    //     assetImage: Constants.kAutoPaymentIconIcon,
    //     title: 'Auto Payments',
    //     alertCount: 0,
    //     buttonType: DashButtonType.autoPayments),
  ];
}
