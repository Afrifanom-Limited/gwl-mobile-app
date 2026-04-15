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

class EditAlias extends StatefulWidget {
  final dynamic meterInfo;

  const EditAlias({Key? key, @required this.meterInfo}) : super(key: key);
  @override
  _EditAliasState createState() => _EditAliasState();
}

class _EditAliasState extends State<EditAlias> {
  final _formKey = GlobalKey<FormState>();
  final _aliasController = TextEditingController();
  bool _loading = false;
  var _meter;

  _loadMeter() {
    setState(() {
      this._meter = widget.meterInfo;
      _aliasController.text =
          _meter["meter_alias"] == 'null' ? '' : _meter["meter_alias"];
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
        url: Endpoints.meters_edit_meter_alias
            .replaceFirst("{id}", "${_meter["meter_id"]}"),
        data: {
          "meter_alias": _aliasController.text,
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
                title: "Edit Account Alias",
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
                          padding: EdgeInsets.symmetric(horizontal: 5.w),
                          child: GText(
                            textData: "Account Alias (Name)",
                            textSize: 12.sp,
                            textColor: Constants.kPrimaryColor,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w),
                          child: GText(
                            textData: "Give your account a "
                                "custom name (alias). For example: Kwabena Dougan's Home",
                            textSize: 10.sp,
                            textColor: Constants.kGreyColor,
                          ),
                        ),
                        Constants.kSizeHeight_10,
                        TextFormField(
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          controller: _aliasController,
                          onFieldSubmitted: (v) {
                            FocusScope.of(context).nextFocus();
                          },
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(30),
                          ],
                          validator: (value) =>
                              checkNull(value!, "Meter Alias"),
                          style: circularTextStyle(),
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
            message: "Meter Alias has been updated successfully",
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
