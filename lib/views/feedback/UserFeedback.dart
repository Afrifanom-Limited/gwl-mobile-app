import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/complaint/LodgeComplaint.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/TextFields.dart';
import 'package:reviews_slider/reviews_slider.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/system/RestDataSource.dart';

class UserFeedback extends StatefulWidget {
  static const String id = "/feedback";
  @override
  _UserFeedbackState createState() => _UserFeedbackState();
}

class _UserFeedbackState extends State<UserFeedback> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  bool _loading = false;
  var _rating = 3;

  void _submitForm() async {
    FocusScope.of(context).requestFocus(FocusNode());
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      HapticFeedback.vibrate();
      return;
    } else {
      if (mounted) setState(() => _loading = true);
      RestDataSource _request = new RestDataSource();
      _request.post(context, url: Endpoints.feedbacks_add, data: {
        "rating": _rating,
        "message": _messageController.text,
      }).then((Map response) async {
        if (mounted) setState(() => _loading = false);
        if (response[Constants.success]) {
          _onRequestSuccess();
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
                title: "User Experience Feedback",
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Constants.kSizeHeight_20,
                      Center(
                        child: GText(
                          textData:
                              "How would you assess your experience so far?",
                          textSize: 12.sp,
                        ),
                      ),
                      Constants.kSizeHeight_10,
                      Center(
                        child: ReviewSlider(
                          optionStyle: TextStyle(
                            color: Constants.kPrimaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.sp,
                          ),
                          onChange: (value) {
                            setState(() => _rating = value);
                          },
                          initialValue: _rating,
                          options: [
                            'Terrible',
                            'Poor',
                            'Average',
                            'Good',
                            'Excellent'
                          ],
                        ),
                      ),
                      Constants.kSizeHeight_10,
                      TextFormField(
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        toolbarOptions: ToolbarOptions(
                          paste: true,
                          cut: true,
                          copy: true,
                          selectAll: true,
                        ),
                        enableInteractiveSelection: true,
                        minLines: 3,
                        maxLines: 6,
                        validator: (value) => checkNull(value!, "Message"),
                        controller: _messageController,
                        onFieldSubmitted: (v) {
                          FocusScope.of(context).nextFocus();
                        },
                        style: circularTextStyle(),
                        decoration: circularInputDecoration(
                          circularRadius: 10.w,
                          title: "Add a message...",
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            left: 0.w, right: 0.w, top: 10.h, bottom: 0.h),
                        child: Container(
                          decoration: BoxDecoration(
                              color: Constants.kPrimaryColor.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.w))),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 15.w, vertical: 10.h),
                            child: GText(
                              textData:
                                  "TIP: All submissions here go to the App "
                                  "Review Board. These submissions are used "
                                  "to make improvements to the GWCL APP. "
                                  "However, if you have an actual Complaint, you can "
                                  "use the 'Lodge Complaint' section",
                              textFont: Constants.kFontLight,
                              textSize: 12.sp,
                              textAlign: TextAlign.justify,
                              textColor: Constants.kPrimaryColor,
                              textMaxLines: 10,
                            ),
                          ),
                        ),
                      ),
                      Constants.kSizeHeight_10,
                      buildElevatedButton(
                        borderRadius: 10.w,
                        title: "Submit",
                        onPressed: () {
                          _submitForm();
                        },
                      ),
                      Constants.kSizeHeight_5,
                      buildTextButton(
                        title: "Lodge Complaint",
                        textSize: 14.sp,
                        textColor: Constants.kPrimaryColor,
                        onPressed: () {
                          Navigator.pushNamed(context, LodgeComplaint.id);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _onRequestSuccess() async {
    coolAlert(
      context,
      CoolAlertType.success,
      barrierDismissible: false,
      title: "Success",
      subtitle: "Thanks for your feedback!",
      confirmBtnText: "Done",
      showCancelBtn: false,
      onConfirmBtnTap: () => Navigator.pop(context),
    );
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
