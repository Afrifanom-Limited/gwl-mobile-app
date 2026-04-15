import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/views/index/OtpConfirmation.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class RegisterNonCustomer extends StatefulWidget {
  static const String id = "/register_non_customer";

  @override
  _RegisterNonCustomerState createState() => _RegisterNonCustomerState();
}

class _RegisterNonCustomerState extends State<RegisterNonCustomer> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  bool _loading = false, _secureText = true;

  _showHide() {
    setState(() {
      _secureText = !_secureText;
    });
  }

  void _submitForm() async {
    FocusScope.of(context).requestFocus(FocusNode());
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2), () {
      setState(() => _loading = false);
      Navigator.pushNamed(context, OtpConfirmation.id);
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
                          "Non Customer",
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).primaryColor),
                        ),
                        Constants.kSizeHeight_10,
                        ClipOval(
                          child: Material(
                            color: Constants.kPrimaryColor.withOpacity(0.2), // button color
                            child: InkWell(
                              splashColor: Constants.kPrimaryColor.withOpacity(0.5),
                              child: SizedBox(width: 40.w, height: 40.h, child: Icon(Icons.close)),
                              onTap: () {
                                FocusScope.of(context).requestFocus(FocusNode());
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    Constants.kSizeHeight_20,
                    Constants.kSizeHeight_20,
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          TextFormField(
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            controller: _usernameController,
                            onFieldSubmitted: (v) {
                              FocusScope.of(context).nextFocus();
                            },
                            style: TextStyle(fontSize: 16.sp),
                            decoration: InputDecoration(
                              labelText: "Username",
                              helperText: "Create a unique username for your account",
                              helperMaxLines: 3,
                              contentPadding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 18.w),
                            ),
                          ),
                          // TextFormField(
                          //   keyboardType: TextInputType.number,
                          //   textInputAction: TextInputAction.next,
                          //   controller: _accountNumberController,
                          //   onFieldSubmitted: (v) {
                          //     FocusScope.of(context).nextFocus();
                          //   },
                          //   style: TextStyle(fontSize: 16.sp),
                          //   decoration: InputDecoration(
                          //     labelText: "Meter Number",
                          //     helperMaxLines: 3,
                          //     contentPadding: EdgeInsets.symmetric(
                          //         vertical: 18.h, horizontal: 18.w),
                          //   ),
                          //   inputFormatters: <TextInputFormatter>[
                          //     FilteringTextInputFormatter.digitsOnly,
                          //     //_mobileFormatter
                          //   ],
                          // ),
                          // Constants.kSizeHeight_10,
                          // TextFormField(
                          //   keyboardType: TextInputType.text,
                          //   textInputAction: TextInputAction.next,
                          //   controller: _digitalAddressController,
                          //   onFieldSubmitted: (v) {
                          //     FocusScope.of(context).nextFocus();
                          //   },
                          //   style: TextStyle(fontSize: 16.sp),
                          //   decoration: InputDecoration(
                          //     labelText: "Digital Address",
                          //     helperMaxLines: 3,
                          //     contentPadding: EdgeInsets.symmetric(
                          //         vertical: 18.h, horizontal: 18.w),
                          //   ),
                          // ),
                          // Constants.kSizeHeight_5,
                          // Padding(
                          //   padding: EdgeInsets.symmetric(horizontal: 6.w),
                          //   child: GText(
                          //     textData:
                          //     "Digital address of the property/location of the meter",
                          //     textSize: 10.sp,
                          //     textColor: Constants.kGreyColor,
                          //   ),
                          // ),
                          // Constants.kSizeHeight_5,
                          // OutlinedButton(
                          //   child: Padding(
                          //     padding: EdgeInsets.symmetric(vertical: 6.h),
                          //     child: GText(
                          //       textData: "Generate GPGPS",
                          //       textColor: Constants.kPrimaryColor,
                          //       textSize: 12.sp,
                          //     ),
                          //   ),
                          //   onPressed: () async {
                          //     setState(() => _loading = true);
                          //     await Future.delayed(const Duration(seconds: 2),
                          //             () {
                          //           setState(() => _loading = false);
                          //           showSnackBar(
                          //             context,
                          //             message:
                          //             "GhanaPost GPS generated for current location",
                          //           );
                          //         });
                          //   },
                          // ),
                          Constants.kSizeHeight_10,
                          TextFormField(
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            controller: _phoneNumberController,
                            validator: (value) => validatePhone(value!),
                            onFieldSubmitted: (v) {
                              FocusScope.of(context).nextFocus();
                            },
                            style: TextStyle(fontSize: 16.sp),
                            decoration: InputDecoration(
                              labelText: "Phone Number",
                              contentPadding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 18.w),
                            ),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                          ),
                          Constants.kSizeHeight_10,
                          TextFormField(
                            keyboardType: TextInputType.text,
                            controller: _passwordController,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value!.length < 8) return "Password must be at least 8 characters";
                              return null;
                            },
                            obscureText: _secureText,
                            onFieldSubmitted: (v) {
                              FocusScope.of(context).nextFocus();
                            },
                            style: TextStyle(fontSize: 16.sp),
                            decoration: InputDecoration(
                              suffixIcon: IconButton(
                                onPressed: _showHide,
                                icon: Icon(_secureText ? Icons.visibility_off : Icons.visibility),
                              ),
                              labelText: "Password",
                              contentPadding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 18.w),
                            ),
                          ),
                          Constants.kSizeHeight_10,
                          ElevatedButton(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              child: GText(
                                textData: "Continue",
                                textColor: Constants.kWhiteColor,
                                textSize: 16.sp,
                              ),
                            ),
                            onPressed: _submitForm,
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
      ),
    );
  }
}
