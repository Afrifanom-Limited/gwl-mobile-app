import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/FlashHelper.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/models/Vendor.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/views/vendor/VendorDetails.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VendorCard extends StatefulWidget {
  final dynamic vendorCard;
  final Color textColor, buttonTextColor;
  final AssetImage bgImage;
  final bool isDark;
  const VendorCard({
    Key? key,
    required this.vendorCard,
    this.textColor = Constants.kPrimaryColor,
    this.bgImage = Constants.kMeterBgOne,
    this.buttonTextColor = Constants.kPrimaryColor,
    required this.isDark,
  }) : super(key: key);

  @override
  _VendorCardState createState() => _VendorCardState();
}

class _VendorCardState extends State<VendorCard> {
  bool _loading = false;
  late Vendor _resVendor;
  var _vendor;

  _refreshVendor() async {
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    if (mounted) setState(() => _loading = true);
    RestDataSource _request = new RestDataSource();
    _request
        .get(context,
            url: Endpoints.vendors_refresh
                .replaceFirst("{id}", "${_vendor["vendor_id"]}"))
        .then((Map response) async {
      if (mounted) setState(() => _loading = false);
      if (response[Constants.success]) {
        _resVendor = Vendor.map(response[Constants.response]);
        var _localDb = new LocalDatabase();
        await _localDb.updateVendor(_resVendor);
        if (mounted)
          setState(() {
            _vendor = response[Constants.response];
          });
        await _localStorage.setBool(Constants.canUpdateVendor, true);
      } else {
        showBasicsFlash(context, Constants.unableToRefresh.toString(),
            textColor: Constants.kWhiteColor,
            bgColor: Constants.kWarningLightColor);
      }
    });
  }

  _checkAndReloadVendor() async {
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    // Check and load vendor info
    var _canUpdateVendor = _localStorage.getBool(Constants.canUpdateVendor);
    if (_canUpdateVendor == null) {
      Timer(new Duration(seconds: 2), _refreshVendor);
    }
  }

  _loadVendorInfo() {
    if (mounted) setState(() => this._vendor = widget.vendorCard);
    _checkAndReloadVendor();
  }

  @override
  void initState() {
    super.initState();
    _loadVendorInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
      decoration: BoxDecoration(
        image: DecorationImage(image: widget.bgImage, fit: BoxFit.cover),
        borderRadius: BorderRadius.all(
          Radius.circular(10.w),
        ),
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
      child: ListTile(
        onTap: (){
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VendorDetails(
                vendorInfo: _vendor,
              ),
            ),
          );
        },
        contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        title: GText(
          textData: "${_vendor["account_number"]}",
          textSize: 12.sp,
          textColor: widget.textColor.withOpacity(0.9),
          textFont: Constants.kFontMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Constants.kSizeHeight_5,
            GText(
              textData: "${_vendor["account_name"]}",
              textSize: 14.sp,
              textColor: widget.textColor.withOpacity(0.9),
            ),
            Constants.kSizeHeight_5,
            Row(
              children: [
                GText(
                  textData: "Your balance is",
                  textColor: widget.textColor.withOpacity(0.9),
                  textSize: 12.sp,
                ),
                Constants.kSizeWidth_5,
                ShadowText(
                  textData: "GHS ${_vendor["balance"].toString()}",
                  textStyle: TextStyle(color: widget.textColor, fontSize: 16.sp),
                ),
              ],
            ),
          ],
        ),
        trailing: InkWell(
          child: _loading
              ? Container(
                  margin: EdgeInsets.only(right: 5),
                  width: 16.w,
                  height: 16.h,
                  child: CircularLoader(
                    loaderColor: widget.textColor,
                    strokeWidth: 2.0,
                    isSmall: true,
                    isDark: widget.isDark,
                  ),
                )
              : Icon(
                  Icons.refresh_outlined,
                  color: widget.textColor,
                  size: 20.sp,
                ),
          onTap: () {
            HapticFeedback.lightImpact();
            _refreshVendor();
          },
        ),
      ),
    );
  }
}
