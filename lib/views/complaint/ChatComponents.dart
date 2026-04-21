import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/models/Complaint.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/views/complaint/Conversation.dart';
import 'package:gwcl/helpers/TimeAgo.dart' as timeAgo;
import 'package:gwcl/templates/Dialogs.dart';

class ChatBubble extends StatefulWidget {
  final dynamic chat;
  final dynamic customer;

  const ChatBubble({Key? key, this.chat, this.customer}) : super(key: key);

  @override
  _ChatBubbleState createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  List colors = Colors.primaries;
  static Random random = Random();
  int rNum = random.nextInt(18);
  bool _toggleTime = false;

  bool _isCustomer() {
    bool result = false;
    if (widget.chat["participant_id"] == widget.customer["customer_id"] &&
        widget.chat["participant_type"] == "customer") {
      result = true;
    }
    return result;
  }

  bool _isSent() {
    bool result = false;
    if (widget.chat["status"] == "sent") {
      result = true;
    }
    return result;
  }

  _showHideTime() async {
    setState(() => _toggleTime = true);
    await Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toggleTime = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = _isCustomer()
        ? Constants.kPrimaryColor.withValues(alpha: 0.9)
        : Colors.grey[600];
    final align =
        _isCustomer() ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = _isCustomer()
        ? BorderRadius.only(
            topLeft: Radius.circular(20.0),
            bottomLeft: Radius.circular(20.0),
            bottomRight: Radius.circular(20.0),
          )
        : BorderRadius.only(
            topRight: Radius.circular(20.0),
            bottomLeft: Radius.circular(20.0),
            bottomRight: Radius.circular(20.0),
          );
    return GestureDetector(
      onTap: () => _showHideTime(),
      child: Column(
        crossAxisAlignment: align,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.all(2.0),
            padding: const EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width / 1.3,
              minWidth: 20.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                !_isCustomer()
                    ? Container(
                        decoration: BoxDecoration(
                            color: _isCustomer()
                                ? Colors.grey[20]
                                : Colors.blue[50],
                            borderRadius: radius),
                        constraints: BoxConstraints(
                          minHeight: 25,
                          minWidth: 80,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(5),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 15.w),
                                child: GText(
                                  textData: _isCustomer() ? 'You' : "Support:",
                                  textMaxLines: 1,
                                  textSize: 12.sp,
                                  textColor: Constants.kPrimaryColor,
                                ),
                                alignment: Alignment.centerLeft,
                              ),
                            ],
                          ),
                        ),
                      )
                    : SizedBox(width: 2),
                _isCustomer() ? SizedBox(height: 5) : SizedBox(),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 15.w, vertical: !_isCustomer() ? 7.h : 2.h),
                  child: !_isCustomer()
                      ? GText(
                          textData: widget.chat["message"],
                          textColor: _isCustomer()
                              ? Constants.kWhiteColor
                              : Constants.kWhiteColor,
                          textMaxLines: 80,
                          textSize: 14.sp,
                        )
                      : Container(
                          alignment: Alignment.topLeft,
                          padding: EdgeInsets.symmetric(vertical: 5.h),
                          child: GText(
                            textData: widget.chat["message"],
                            textColor: _isCustomer()
                                ? Constants.kWhiteColor
                                : Constants.kWhiteColor,
                            textMaxLines: 80,
                            textSize: 14.sp,
                          ),
                        ),
                ),
              ],
            ),
          ),
          _toggleTime
              ? Padding(
                  padding: _isCustomer()
                      ? EdgeInsets.only(
                          right: 10,
                          bottom: 10.0,
                        )
                      : EdgeInsets.only(
                          left: 10,
                          bottom: 10.0,
                        ),
                  child: Row(
                    mainAxisAlignment: _isCustomer()
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      Text(
                        "${timeAgo.format(DateTime.parse(widget.chat['date_created']))}",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10.0,
                        ),
                      ),
                      if (_isSent())
                        Padding(
                          padding: EdgeInsets.only(left: 5.w),
                          child: Icon(
                            _isCustomer()
                                ? Icons.check
                                : Icons.remove_red_eye_outlined,
                            size: 12.sp,
                            color: Constants.kGreenLightColor,
                          ),
                        )
                    ],
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}

class ComplaintBubble extends StatelessWidget {
  final String message;

  const ComplaintBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = Constants.kPrimaryColor.withValues(alpha: 0.9);
    final align = CrossAxisAlignment.end;
    final radius = BorderRadius.only(
      topLeft: Radius.circular(20.0),
      bottomLeft: Radius.circular(20.0),
      bottomRight: Radius.circular(20.0),
    );
    return Column(
      crossAxisAlignment: align,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.all(2.0),
          padding: const EdgeInsets.all(5.0),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width / 1.3,
            minWidth: 20.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 3),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: Container(
                  alignment: Alignment.topLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: Constants.kPrimaryLightColor,
                            borderRadius: radius),
                        constraints: BoxConstraints(
                          minHeight: 25,
                          minWidth: 80,
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 5.w, vertical: 4.h),
                        child: GText(
                          textData: "Complaint Message:",
                          textMaxLines: 1,
                          textSize: 12.sp,
                          textColor: Constants.kAccentColor,
                        ),
                        alignment: Alignment.centerLeft,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 6.h, horizontal: 7.w),
                        child: GText(
                          textData: message,
                          textColor: Constants.kWhiteColor,
                          textMaxLines: 80,
                          textSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ComplaintItem extends StatefulWidget {
  final dynamic complaint, customer;
  final int counter;

  ComplaintItem({
    Key? key,
    required this.counter,
    required this.complaint,
    required this.customer,
  }) : super(key: key);

  @override
  _ComplaintItemState createState() => _ComplaintItemState();
}

class _ComplaintItemState extends State<ComplaintItem> {
  late Timer _timer;
  dynamic _counter = 0;
  int _maxLoad = 5;
  bool _isDeleted = false;

  _getStatusColor(String string) {
    switch (string) {
      case Constants.complaintOpened:
        return Constants.kWarningLightColor;
      case Constants.complaintClosed:
        return Constants.kGreenLightColor;
      case Constants.complaintPrank:
        return Constants.kRedLightColor;
      default:
        return Constants.kGreyColor;
    }
  }

  _cancelTimer() {
    try {
      _timer.cancel();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  _startPaymentCheck() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      try {
        if (_maxLoad == 0) {
          setState(() => _cancelTimer());
        } else {
          setState(() => _maxLoad--);
          _getComplaintInfo();
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    });
  }

  _getComplaintInfo() async {
    try {
      Complaint _cpl = Complaint.map(widget.complaint);
      var _localDb = new LocalDatabase();
      var _res = await _localDb.getComplaint(_cpl);
      if (mounted && _res != null) {
        setState(() => _counter = _res[0]['unread_chat_count']);
      }
    } catch (e) {}
  }

  _setCounter() {
    setState(() => _counter = widget.counter);
  }

  @override
  void initState() {
    _setCounter();
    super.initState();
    _startPaymentCheck();
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  _removeComplaint() async {
    var _localDb = new LocalDatabase();
    await _localDb.deleteComplaint(widget.complaint["complaint_id"].toString());
    setState(() => _isDeleted = true);
  }

  @override
  Widget build(BuildContext context) {
    return _isDeleted
        ? Container()
        : GestureDetector(
            onLongPress: () async {
              HapticFeedback.lightImpact();
              var optionSelection;
              if (Platform.isAndroid) {
                optionSelection = await optionAndroidDialog(context,
                    optionTitle: "Remove from List");
              } else if (Platform.isIOS) {
                optionSelection = await optionIosDialog(context,
                    optionTitle: "Remove from List");
              }
              if (optionSelection == Constants.delete) {
                _removeComplaint();
              }
            },
            child: Column(
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(0),
                    leading: Column(
                      children: [
                        Image(
                          image: Constants.kComplaintIconIcon,
                          height: 26.h,
                        ),
                        Constants.kSizeHeight_5,
                        Icon(
                          Icons.circle,
                          color: _getStatusColor(
                              widget.complaint["status"].toString()),
                          size: 10.sp,
                        ),
                      ],
                    ),
                    title: Padding(
                      padding: EdgeInsets.symmetric(vertical: 5.h),
                      child: GText(
                        textData: "${widget.complaint['ticket_id']}",
                        textColor: Constants.kPrimaryColor,
                        textFont: Constants.kFontMedium,
                        textSize: 14.sp,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GText(
                          textData:
                              "Complaint Message: ${widget.complaint['message']}",
                          textColor: Constants.kAccentColor,
                          textSize: 12.sp,
                          textFont: Constants.kFontLight,
                          textMaxLines: 2,
                        ),
                        Constants.kSizeHeight_5,
                        Row(
                          children: [
                            GText(
                              textData:
                                  "${timeAgo.format(DateTime.parse(widget.complaint['date_created']))}",
                              textSize: 10.sp,
                            ),
                            if (widget.complaint["status"].toString() ==
                                Constants.complaintClosed)
                              GText(
                                textData:
                                    " - ${widget.complaint["status"].toString().toUpperCase()}",
                                textSize: 10.sp,
                                textColor: _getStatusColor(
                                    widget.complaint["status"].toString()),
                              ),
                          ],
                        ),
                        Constants.kSizeHeight_10,
                      ],
                    ),
                    trailing: _counter == 0
                        ? null
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              if (_counter == 0 ||
                                  _counter == 'null' ||
                                  _counter == null)
                                SizedBox()
                              else
                                Container(
                                  padding: EdgeInsets.all(5.w),
                                  decoration: BoxDecoration(
                                    color: Constants.kWarningColor,
                                    borderRadius: BorderRadius.circular(6.w),
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 14.w,
                                    minHeight: 14.h,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        top: 1, left: 5, right: 5),
                                    child: GText(
                                      textData: "$_counter",
                                      textSize: 10.sp,
                                      textColor: Constants.kWhiteColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                    onTap: () {
                      _cancelTimer();
                      if (mounted) setState(() => _counter = 0);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Conversation(
                            complaint: widget.complaint,
                            customer: widget.customer,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Divider(color: Constants.kPrimaryLightColor, height: 1),
              ],
            ),
          );
  }
}
