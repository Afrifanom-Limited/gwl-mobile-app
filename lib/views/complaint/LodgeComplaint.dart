import 'dart:io';

import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/DropDownFormField.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Menu.dart';
import 'package:gwcl/helpers/PageTransitions.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/helpers/TextFields.dart';
import 'package:gwcl/helpers/Utils.dart';
import 'package:gwcl/models/Complaint.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/complaint/ComplaintsList.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../mixpanel.dart';

class LodgeComplaint extends StatefulWidget {
  static const String id = "/lodge_complaint";
  final dynamic message;

  const LodgeComplaint({Key? key, this.message}) : super(key: key);
  @override
  _LodgeComplaintState createState() => _LodgeComplaintState();
}

class _LodgeComplaintState extends State<LodgeComplaint> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  String _complaintTypeValue = "";
  List<File> _images = List<File>.empty(growable: true);
  bool _loading = false;
  late Complaint _complaint;
  void _submitForm() async {
    FocusScope.of(context).requestFocus(FocusNode());
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      HapticFeedback.vibrate();
      return;
    } else if (_complaintTypeValue == "") {
      HapticFeedback.vibrate();
      _onRequestFailed("Complaint Type is required");
      return;
    } else {
      if (mounted) setState(() => _loading = true);
      // List<File> files = List.empty(growable: true);
      // for (var i = 0; i < _images.length; i++) {
      //   var file = await compressImage(_images[i].path);
      //   files.add(file);
      // }
      RestDataSource _request = new RestDataSource();
      _request.postFile(context, url: Endpoints.complaints_add, files: _images, data: {
        "complaint_type": _complaintTypeValue,
        "message": _messageController.text,
      }).then((Map response) async {
        if (mounted) setState(() => _loading = false);
        if (response[Constants.success]) {
          mixpanel?.track('Lodge Complaints');
          setState(() {
            _messageController.text = "";
            _complaintTypeValue = '';
          });
          _complaint = Complaint.map(response[Constants.response]);
          _onRequestSuccess(_complaint);
        } else {
          _onRequestFailed(response[Constants.message]);
        }
      });
    }
  }

  _initAll() async {
    var status = await Permission.storage.status;
    if (status.isLimited) {
      await Permission.storage.request();
    }

    if (Platform.isIOS) {
      var mediaLibrary = await Permission.mediaLibrary.status;
      if (mediaLibrary.isLimited) {
        await Permission.mediaLibrary.request();
      }
    }
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _requestPermissions();
    _lifecycleListener = AppLifecycleListener(
      onResume: _checkPermissions,
    );
    super.initState();
    if (widget.message != null) {
      _messageController.text = widget.message;
    }
    _initAll();
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
              title: "Lodge New Complaint",
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
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 10.h),
                            child: GText(
                              textData: "Complaint Type *",
                              textSize: 12.sp,
                              textColor: Constants.kPrimaryColor,
                            ),
                          ),
                          DropDownFormField(
                            value: _complaintTypeValue,
                            inputDecoration: circularInputDecoration(title: "", circularRadius: 10.w, useDropDownPadding: true, suffix: Icon(Icons.keyboard_arrow_down_outlined, size: 22.sp)),
                            onSaved: (value) {
                              setState(() {
                                _complaintTypeValue = value;
                              });
                            },
                            onChanged: (value) {
                              setState(() {
                                _complaintTypeValue = value;
                              });
                            },
                            dataSource: Menu.complaintType,
                            required: true,
                            validator: (value) {
                              if (value.toString() == 'null' || value == '') {
                                return 'Complaint type is required';
                              }
                              return null;
                            },
                            textField: 'display',
                            valueField: 'value',
                          ),
                          Constants.kSizeHeight_10,
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 10.h),
                            child: GText(
                              textData: "Message *",
                              textSize: 12.sp,
                              textColor: Constants.kPrimaryColor,
                            ),
                          ),
                          TextFormField(
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
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
                              title: "",
                            ),
                          ),
                          Constants.kSizeHeight_10,
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 10.h),
                            child: GText(
                              textData: "Attach photo evidence to complaint (optional) ",
                              textSize: 12.sp,
                              textColor: Constants.kPrimaryColor,
                            ),
                          ),
                          OutlinedButton(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 6.h),
                              child: GText(
                                textData: "Open photo gallery",
                                textColor: Constants.kPrimaryColor,
                                textSize: 12.sp,
                              ),
                            ),
                            onPressed: () {
                              _loadImageAssets();
                            },
                          ),
                          if (_images.length > 0) Constants.kSizeHeight_20,
                          if (_images.length > 0)
                            Container(
                              height: 150.h,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Constants.kGreyColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: _images.length < 1
                                  ? Center(
                                      child: GText(
                                        textData: "Selected images will be displayed here",
                                        textSize: 10.sp,
                                      ),
                                    )
                                  : ListView(
                                      padding: EdgeInsets.all(10.w),
                                      scrollDirection: Axis.horizontal,
                                      children: List.generate(_images.length, (index) {
                                        return Column(
                                          children: <Widget>[
                                            SizedBox(
                                              height: 80.h,
                                              width: 80.w,
                                              child: new Container(
                                                padding: EdgeInsets.all(1.w),
                                                child: Image.file(
                                                  _images[index],
                                                  fit: BoxFit.fitHeight,
                                                ),
                                              ),
                                            ),
                                            OutlinedButton(
                                              onPressed: () {
                                                List<File> mPhotos = Utils.arrayRemove(_images, index);
                                                setState(() {
                                                  _images = mPhotos;
                                                });
                                              },
                                              child: GText(
                                                textData: "Remove",
                                                textSize: 10.sp,
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                    ),
                            ),
                          Constants.kSizeHeight_20,
                          buildElevatedButton(
                            borderRadius: 10.w,
                            title: "Submit",
                            onPressed: () {
                              _submitForm();
                            },
                          ),
                          Constants.kSizeHeight_50,
                          Constants.kSizeHeight_50,
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

  bool _permissionReady = false;
  AppLifecycleListener? _lifecycleListener;
  static const List<Permission> _permissions = [Permission.storage, Permission.camera];

  Future<void> _requestPermissions() async {
    final Map<Permission, PermissionStatus> statues = await _permissions.request();
    if (statues.values.every((status) => status.isGranted)) {
      _permissionReady = true;
    }
  }

  Future<void> _checkPermissions() async {
    _permissionReady = (await Future.wait(_permissions.map((e) => e.isGranted))).every((isGranted) => isGranted);
  }

  Future<void> _loadImageAssets() async {
    if (!_permissionReady) {
      openAppSettings();
      return;
    }

    setState(() => _images = List<File>.empty(growable: true));

    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> result = await picker.pickMultiImage(
        maxWidth: 760,
        imageQuality: 80,
        limit: 5,
        maxHeight: 760,
      );

      if (result.isNotEmpty) {
        if (result.length > 5) {
          _images = result.sublist(0, 5).map((file) => File(file.path)).toList();
        } else {
          _images = result.map((file) => File(file.path)).toList();
        }
      }
    } catch (e) {
      print(e.toString());
    }

    if (!mounted) return;
    setState(() {});
  }

  _onRequestSuccess(Complaint complaint) async {
    // var _localDb = new LocalDatabase();
    // await _localDb.addComplaint(complaint);
    setState(() => _images = List<File>.empty(growable: true));
    coolAlert(
      context,
      CoolAlertType.success,
      barrierDismissible: false,
      title: "Success",
      subtitle: "Complaint submitted successfully. Your ticket number is ${complaint.ticketId}",
      confirmBtnText: "View All Complaints",
      showCancelBtn: false,
      onConfirmBtnTap: () {
        Navigator.pushReplacement(
          context,
          FadeRoute(
            page: ComplaintsList(),
          ),
        );
      },
    );
  }

  _onRequestFailed(dynamic errorText) async {
    showDialog(
      context: context,
      builder: (_) => ErrorDialog(
        content: errorText.toString().replaceAll(RegExp(Constants.errorFilter), ""),
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
