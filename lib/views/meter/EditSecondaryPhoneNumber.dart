import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/helpers/TextFields.dart';
import 'package:gwcl/models/Meter.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/home/Home.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditSecondaryPhoneNumber extends StatefulWidget {
  final dynamic meterInfo;

  const EditSecondaryPhoneNumber({Key? key, required this.meterInfo})
      : super(key: key);
  @override
  _EditSecondaryPhoneNumberState createState() =>
      _EditSecondaryPhoneNumberState();
}

class _EditSecondaryPhoneNumberState extends State<EditSecondaryPhoneNumber> {
  final _formKey = GlobalKey<FormState>();
  final _secondaryPhoneController = TextEditingController();
  bool _loading = false;
  var _meter;

  _loadMeter() {
    setState(() {
      this._meter = widget.meterInfo;
      _secondaryPhoneController.text =
          _meter["secondary_phone_number"] == 'null'
              ? ''
              : getActualPhone(_meter["secondary_phone_number"]);
    });
  }

  void _submitForm() async {
    FocusScope.of(context).requestFocus(FocusNode());
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      HapticFeedback.vibrate();
      return;
    } else {
      setState(() => _loading = true);
      RestDataSource _request = new RestDataSource();
      _request.post(
        context,
        url: Endpoints.meters_edit_secondary_phone_number
            .replaceFirst("{id}", "${_meter["meter_id"]}"),
        data: {
          "secondary_phone_number": getMsisdn(_secondaryPhoneController.text),
        },
      ).then((Map response) async {
        if (mounted) setState(() => _loading = false);
        if (response[Constants.success]) {
          _meter = Meter.map(response[Constants.response]);
          _onRequestSuccess(_meter);
        } else {
          _onRequestFailed(response[Constants.message]);
        }
      });
    }
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
                title: "Edit Secondary Phone Number",
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
                child: Column(children: <Widget>[
                  Constants.kSizeHeight_10,
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 10.h),
                          child: GText(
                            textData: "Secondary Phone Number *",
                            textSize: 12.sp,
                            textColor: Constants.kPrimaryColor,
                          ),
                        ),
                        TextFormField(
                          keyboardType: TextInputType.number,
                          controller: _secondaryPhoneController,
                          validator: (value) => validatePhone(value!),
                          textInputAction: TextInputAction.next,
                          toolbarOptions: ToolbarOptions(
                            paste: true,
                            cut: true,
                            copy: true,
                            selectAll: true,
                          ),
                          onFieldSubmitted: (v) {
                            FocusScope.of(context).nextFocus();
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          style: TextStyle(fontSize: 16.sp),
                          decoration: circularInputDecoration(
                            title: "",
                          ),
                        ),
                        Constants.kSizeHeight_20,
                        buildElevatedButton(
                            title: "Submit",
                            onPressed: () {
                              _submitForm();
                            }),
                        Constants.kSizeHeight_5,
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _onRequestSuccess(Meter meter) async {
    var _localDb = new LocalDatabase();
    await _localDb.updateMeter(meter);
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => Home(
            index: 0,
            message: "Phone Number has been updated successfully",
          ),
        ),
        (route) => false);
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
