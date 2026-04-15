import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/ColumnBuilder.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/models/Meter.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/meter/MeterComponents.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class Meters extends StatefulWidget {
  static const String id = "/meters";
  final dynamic meters;

  const Meters({Key? key, required this.meters}) : super(key: key);
  @override
  _MetersState createState() => _MetersState();
}

class _MetersState extends State<Meters> {
  ScrollController _scrollController = ScrollController();
  bool _loading = false;
  var _meters = List.empty(growable: true);
  var _localDb = new LocalDatabase();
  late Meter _meter;

  _loadMeters() async {
    setState(() => this._meters = widget.meters);
    var _res = await _localDb.getMeters();
    if (mounted) {
      if (_res.length < 1) {
        _fetchMeters();
      } else {
        setState(() => this._meters = _res);
      }
      return;
    }
  }

  _reloadMeters() async {
    setState(() => _meters = List.empty(growable: true));
    await _localDb.deleteAllMeter();
    _fetchMeters();
  }

  _fetchMeters() async {
    setState(() => _loading = true);
    RestDataSource _request = new RestDataSource();
    _request.get(context, url: Endpoints.meters).then((Map response) {
      if (mounted) setState(() => _loading = false);
      if (response[Constants.success]) {
        var records = response[Constants.response]["records"];
        _onRequestSuccess(records);
      } else {
        _onRequestFailed(Constants.unableToRefresh);
      }
    });
  }

  @override
  void initState() {
    _loadMeters();
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
              title: "My Customer Accounts",
              actionButton: Container(
                margin: EdgeInsets.only(top: 18.h, right: 10.w),
                child: IconButton(
                  icon: _loading
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
                    _reloadMeters();
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
              controller: _scrollController,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Constants.indexHorizontalSpace,
                  vertical: Constants.indexVerticalSpace,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ColumnBuilder(
                      itemCount: _meters.length,
                      itemBuilder: (BuildContext context, int index) {
                        var oddIndex = (index % 2);
                        return MeterCard(
                          meterCard: _meters[index],
                          textColor: Constants.kWhiteColor,
                          bgImage: Constants.kMeterBgTwo,
                          buttonTextColor: Constants.kPrimaryColor,
                          isLarge: true,
                          isDark: true,
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

  _onRequestSuccess(List<dynamic> meters) async {
    for (var i = 0; i < meters.length; i++) {
      _meter = Meter.map(meters[i]);
      await _localDb.addMeter(_meter);
    }
    if (mounted) setState(() => this._meters = meters);
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
