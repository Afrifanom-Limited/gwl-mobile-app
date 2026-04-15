import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/TextFields.dart';
import 'package:gwcl/models/Customer.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class EditEmailAddress extends StatefulWidget {
  static const String id = "/edit_email_address";
  final String? emailAddress;

  const EditEmailAddress({Key? key, this.emailAddress}) : super(key: key);
  @override
  _EditEmailAddressState createState() => _EditEmailAddressState();
}

class _EditEmailAddressState extends State<EditEmailAddress> {
  final _formKey = GlobalKey<FormState>();
  final _emailAddressController = TextEditingController();
  bool _loading = false;
  late Customer _customerData;

  @override
  void initState() {
    if (widget.emailAddress != null &&
        widget.emailAddress.toString().toLowerCase() != 'null')
      _emailAddressController.text = widget.emailAddress!;
    super.initState();
  }

  void _submitForm() async {
    FocusScope.of(context).requestFocus(FocusNode());
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      HapticFeedback.vibrate();
      return;
    } else if (_emailAddressController.text == widget.emailAddress) {
      setState(() => _loading = true);
      await Future.delayed(const Duration(seconds: 1), () {
        setState(() => _loading = false);
        Navigator.pop(context, true);
      });
    } else {
      setState(() => _loading = true);
      RestDataSource _request = new RestDataSource();
      _request.post(
        context,
        url: Endpoints.customers_editemail,
        data: {"email": _emailAddressController.text},
      ).then((Map response) async {
        if (mounted) setState(() => _loading = false);
        if (response[Constants.success]) {
          _customerData = Customer.map(response[Constants.response]);
          _onRequestSuccess(_customerData);
        } else {
          _onRequestFailed(response[Constants.message]);
        }
      });
    }
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
              title: "Change/Add Email",
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
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Constants.indexHorizontalSpace,
                  vertical: Constants.indexVerticalSpace,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5.w, vertical: 10.h),
                            child: GText(
                              textData: "Email Address *",
                              textSize: 12.sp,
                            ),
                          ),
                          TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            controller: _emailAddressController,
                            validator: (value) => validateEmail(value!),
                            onFieldSubmitted: (v) {
                              FocusScope.of(context).nextFocus();
                            },
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(50),
                            ],
                            style: circularTextStyle(),
                            decoration: circularInputDecoration(
                              title: "Email Address",
                            ),
                          ),
                          Constants.kSizeHeight_20,
                          buildElevatedButton(
                            title: "Submit",
                            onPressed: () {
                              _submitForm();
                            },
                          ),
                        ],
                      ),
                    ),
                    Constants.kSizeHeight_20,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _onRequestSuccess(Customer customer) async {
    var _localDb = new LocalDatabase();
    await _localDb.updateCustomer(customer);
    Navigator.pop(context, true);
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
