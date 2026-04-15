import 'package:flutter/material.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/views/index/RegisterCustomer.dart';
import 'package:gwcl/views/index/RegisterNonCustomer.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class CustomerOption extends StatefulWidget {
  static const String id = "customer_option";
  @override
  _CustomerOptionState createState() => _CustomerOptionState();
}

class _CustomerOptionState extends State<CustomerOption> {
  bool _loading = false;

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
        appBar: AppBar(
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Constants.indexHorizontalSpace,
                  vertical: Constants.indexVerticalSpace,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Register As ...",
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).primaryColor),
                        ),
                        Constants.kSizeHeight_10,
                        ClipOval(
                          child: Material(
                            color: Constants.kPrimaryColor.withOpacity(0.2), // button color
                            child: InkWell(
                              splashColor: Constants.kPrimaryColor.withOpacity(0.5),
                              child: SizedBox(width: 40.w, height: 40.h, child: Icon(Icons.close)),
                              onTap: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Constants.kSizeHeight_20,
                    Constants.kSizeHeight_20,
                    Card(
                      elevation: 2,
                      color: Constants.kWhiteColor.withOpacity(0.7),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, RegisterCustomer.id);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: Column(
                            children: <Widget>[
                              ListTile(
                                leading: Icon(
                                  Icons.person,
                                  color: Constants.kPrimaryColor,
                                  size: 35.sp,
                                ),
                                title: GText(
                                  textData: "Customer",
                                  textColor: Constants.kPrimaryColor,
                                  textFont: Constants.kFontMedium,
                                  textSize: 18.sp,
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: GText(
                                    textData: "Gives you access to your GWCL account."
                                        " read billing history make payments, send complaints, etc",
                                    textMaxLines: 5,
                                    textColor: Constants.kPrimaryColor,
                                    textSize: 12.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Constants.kSizeHeight_10,
                    Card(
                      elevation: 2,
                      color: Constants.kWhiteColor.withOpacity(0.7),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, RegisterNonCustomer.id);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: Column(
                            children: <Widget>[
                              ListTile(
                                leading: Icon(
                                  Icons.perm_identity,
                                  color: Constants.kPrimaryColor,
                                  size: 35.sp,
                                ),
                                title: GText(
                                  textData: "Non Customer",
                                  textColor: Constants.kPrimaryColor,
                                  textFont: Constants.kFontMedium,
                                  textSize: 18.sp,
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: GText(
                                    textData: "Gives you access to send general complaints",
                                    textMaxLines: 5,
                                    textColor: Constants.kPrimaryColor,
                                    textSize: 12.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
