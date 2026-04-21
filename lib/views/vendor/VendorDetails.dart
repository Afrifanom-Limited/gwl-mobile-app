import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/FlashHelper.dart';
import 'package:gwcl/helpers/LiquidWave.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/home/Home.dart';
import 'package:gwcl/views/transactions/VendorTopup.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Functions.dart';

class VendorDetails extends StatefulWidget {
  final dynamic vendorInfo;

  const VendorDetails({Key? key, required this.vendorInfo}) : super(key: key);
  @override
  _VendorDetailsState createState() => _VendorDetailsState();
}

class _VendorDetailsState extends State<VendorDetails> {
  bool _loading = false;
  var _vendor;

  _loadVendor() {
    if (mounted) setState(() => this._vendor = widget.vendorInfo);
  }

  _backToHome(var vendorId) async {
    var _localDb = new LocalDatabase();
    await _localDb.removeVendor(vendorId.toString());
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Home(index: 0)), (route) => false);
    }
  }

  _removeVendor(var vendorId) {
    setState(() => _loading = true);
    RestDataSource _request = new RestDataSource();
    _request.get(context, url: Endpoints.vendors_delete.replaceFirst("{id}", "$vendorId")).then((Map response) {
      if (mounted) setState(() => _loading = false);
      if (response[Constants.success]) {
        _backToHome(vendorId);
      } else {
        showBasicsFlash(context, "Unable to remove account.", textColor: Constants.kWhiteColor, bgColor: Constants.kWarningLightColor);
      }
    });
  }

  @override
  void initState() {
    _loadVendor();
    super.initState();
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
              title: "Vendor Info",
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
                        title: "Vendor Number",
                        body: "${_vendor["account_number"]}",
                      ),
                    ),
                    Constants.kSizeHeight_10,
                    GText(
                      textData: "Your balance is",
                      textColor: Constants.kPrimaryColor,
                      textSize: 10.sp,
                      textAlign: TextAlign.center,
                    ),
                    Constants.kSizeHeight_5,
                    Center(
                      child: ShadowText(
                        textData: "GHS ${_vendor["balance"].toString()}",
                        textStyle: TextStyle(
                          color: Constants.kPrimaryColor,
                          fontSize: 18.sp,
                        ),
                      ),
                    ),
                    Constants.kSizeHeight_10,
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 20.0)],
                      ),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.w),
                            side: BorderSide(
                              color: Constants.kWhiteColor,
                            ),
                          ),
                        ),
                        child: GText(
                          textData: "Topup Wallet",
                          textSize: 13.sp,
                          textColor: Constants.kWhiteColor,
                          textFont: Constants.kFontLight,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VendorTopup(
                                vendor: _vendor,
                                hasOldBalance: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Constants.kSizeHeight_20,
                    Table(
                      border: TableBorder.symmetric(
                          inside: BorderSide(
                        width: 1,
                      )),
                      columnWidths: {
                        0: FractionColumnWidth(.45),
                      },
                      children: [
                        tableRow("Name", "${_vendor["account_name"]}"),
                        tableRow("Vendor Number", "${_vendor["account_number"]}"),
                        tableRow("Telephone", "${_vendor["telephone"]}"),
                        tableRow("Email", "${_vendor["email"] == '' ? 'N/A' : _vendor["email"]}"),
                        tableRow("Level", "${_vendor["structure_level_name"]}"),
                        tableRow("Region", "${_vendor["structure_name"]}"),
                      ],
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
                                "(${_vendor["account_number"]})"
                                " ?",
                            confirmText: "Yes",
                            confirmTextColor: Constants.kPrimaryColor,
                            confirm: () => _removeVendor(_vendor["vendor_id"]),
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
}
