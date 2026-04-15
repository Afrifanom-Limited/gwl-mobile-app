import 'package:cached_network_image/cached_network_image.dart';
import 'package:gwcl/helpers/Buttons.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/FlashHelper.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/helpers/TextFields.dart';
import 'package:gwcl/models/Chat.dart';
import 'package:gwcl/models/Complaint.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/complaint/ChatComponents.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:reviews_slider/reviews_slider.dart';

class Conversation extends StatefulWidget {
  final dynamic complaint, customer;

  const Conversation(
      {Key? key, required this.complaint, required this.customer})
      : super(key: key);

  @override
  _ConversationState createState() => _ConversationState();
}

class _ConversationState extends State<Conversation>
    with WidgetsBindingObserver {
  var _localDb = new LocalDatabase();
  ScrollController _scrollController = ScrollController();
  final _textController = TextEditingController();
  var _rating = 3, _complaintStatus = "";

  bool _loading = false, _chatsLoading = false, _ratingChanged = false;
  FocusNode? _myFocusNode;
  Color bgColor = Colors.blue.withAlpha(15);

  var _chats = List.empty(growable: true), _photos;
  late Chat _chat;

  _getChatSyncId() {
    DateTime _now = DateTime.now();
    String _formattedDate = DateFormat('yyyyMMddkkmmss').format(_now);
    return _formattedDate;
  }

  _appendMessageToLocalDb() async {
    if (_textController.text == "") {
      return;
    } else {
      String msg = _textController.text;
      final now = DateTime.now();
      var dateTime = DateTime(
          now.year, now.month, now.day, now.hour, now.minute, now.second);
      var chatSyncId = _getChatSyncId();
      var data = {
        "message": _textController.text,
        "complaint_id": widget.complaint["complaint_id"],
        "participant_id": widget.customer["customer_id"],
        "participant_type": "customer",
        "status": "",
        "chat_sync_id": chatSyncId,
        "date_created": dateTime.toString()
      };
      await _localDb.addChat(Chat.map(data));
      if (mounted) setState(() => _textController.text = "");
      _loadChats(false, "chat_sync_id DESC");
      _sendMessageToServer(msg, chatSyncId);
    }
  }

  _sendMessageToServer(String msg, dynamic chatSyncId) {
    RestDataSource _request = new RestDataSource();
    _request.post(
      context,
      url: Endpoints.chats_add,
      data: {
        "complaint_id": widget.complaint["complaint_id"],
        "message": msg,
        "participant_type": "customer",
        "chat_sync_id": "$chatSyncId"
      },
    ).then((Map response) async {
      if (response[Constants.success]) {
        _chat = Chat.map(response[Constants.response]);
        _onChatSubmitSuccess(_chat);
      } else {
        _onRequestFailed(response[Constants.message]);
      }
    });
  }

  _fetchChats() async {
    setState(() => _chatsLoading = true);
    RestDataSource _request = new RestDataSource();
    _request
        .get(context,
            url: Endpoints.chats_index
                .replaceFirst("{fieldName}", "complaint_id")
                .replaceFirst(
                    "{fieldValue}", "${widget.complaint["complaint_id"]}"))
        .then((Map response) {
      if (response[Constants.success]) {
        var records = response[Constants.response]["records"];
        _onRequestSuccess(records);
      } else {
        if (mounted) setState(() => _chatsLoading = false);
        _onRequestFailed(Constants.unableToRefresh);
      }
      if (mounted) _setChatsAsRead();
    });
  }

  _setChatsAsRead() {
    RestDataSource _request = new RestDataSource();
    _request
        .get(context,
            url: Endpoints.chats_read
                .replaceFirst("{id}", "${widget.complaint["complaint_id"]}"))
        .then((Map response) {});
  }

  _setComplaintStatus() {
    setState(() => _complaintStatus = widget.complaint["status"]);
  }

  _loadChats(bool connectToServer, orderBy) async {
    List res =
        await _localDb.getChats(widget.complaint["complaint_id"], orderBy);
    if (res.length > 0) {
      setState(() {
        _chats = res;
        _chatsLoading = false;
      });
    } else {
      setState(() => _chatsLoading = false);
    }
    setState(() => _photos =
        widget.complaint["attached_files"].toString().split(',').toList());
    if (connectToServer) _fetchChats();
  }

  void _reopenComplaint() async {
    setState(() => _loading = true);
    RestDataSource _request = new RestDataSource();
    _request.post(
      context,
      url: Endpoints.complaints_edit
          .replaceFirst("{id}", "${widget.complaint["complaint_id"]}"),
      data: {
        "status": Constants.complaintOpened,
      },
    ).then((Map response) async {
      if (mounted) setState(() => _loading = false);
      if (response[Constants.success]) {
        Complaint _complaintData;
        _complaintData = Complaint.map(response[Constants.response]);
        var _localDb = new LocalDatabase();
        await _localDb.updateComplaint(_complaintData);
        setState(() {
          _complaintStatus = Constants.complaintOpened;
        });
      } else {
        _onRequestFailed(response[Constants.message]);
      }
    });
  }

  void _rateComplaint() async {
    setState(() => _loading = true);
    RestDataSource _request = new RestDataSource();
    _request.post(
      context,
      url: Endpoints.complaints_rating
          .replaceFirst("{id}", "${widget.complaint["complaint_id"]}"),
      data: {
        "rating": _rating,
      },
    ).then((Map response) async {
      if (mounted) setState(() => _loading = false);
      if (response[Constants.success]) {
        Complaint _complaintData;
        _complaintData = Complaint.map(response[Constants.response]);
        var _localDb = new LocalDatabase();
        await _localDb.updateComplaint(_complaintData);
        setState(() => widget.complaint["rating"] = _rating);
        showBasicsFlash(
          context,
          "Rating has been submitted successfully. Thank you",
          textColor: Constants.kWhiteColor,
          bgColor: Constants.kGreenLightColor,
        );
      } else {
        _onRequestFailed(response[Constants.message]);
      }
    });
  }

  @override
  void initState() {
    _setComplaintStatus();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _loadChats(true, "chat_sync_id DESC");
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
      child: SafeArea(
        bottom: true,
        top: false,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(70.h),
            child: Container(
              color: Constants.kPrimaryColor,
              child: GeneralHeader(
                title: "${widget.complaint["ticket_id"]}",
                actionButton: Container(
                  margin: EdgeInsets.only(top: 18.h, right: 10.w),
                  child: IconButton(
                    icon: _chatsLoading
                        ? CircularLoader(
                            loaderColor: Constants.kWhiteColor,
                            isSmall: true,
                            isDark: true,
                          )
                        : Icon(
                            Icons.refresh,
                            color: Constants.kWhiteColor,
                          ),
                    onPressed: () {
                      _loadChats(true, "chat_sync_id DESC");
                    },
                  ),
                ),
              ),
            ),
          ),
          body: Container(
            height: MediaQuery.of(context).size.height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (_chatsLoading)
                  Container(
                    child: SizedBox(
                      height: 3.h,
                      child: BarLoader(
                        barColor: Constants.kPrimaryColor,
                      ),
                    ),
                  ),
                Constants.kSizeHeight_5,
                Flexible(
                  child: ListView.builder(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    itemCount: _chats.length + 1,
                    reverse: true,
                    controller: _scrollController,
                    itemBuilder: (BuildContext context, int index) {
                      if (index == _chats.length) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ComplaintBubble(
                              message: widget.complaint["message"],
                            ),
                            if (_photos != null)
                              if (_photos.length != 1)
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width / 1.3,
                                  height: 60.h,
                                  child: GridView.builder(
                                    itemCount: _photos.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 5),
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      return _photos[index] != ''
                                          ? GestureDetector(
                                              onTap: () => viewImages(
                                                  context, _photos, index),
                                              child: Card(
                                                child: CachedNetworkImage(
                                                  placeholder: (context, url) =>
                                                      Center(
                                                    child: Container(
                                                      height: 240.h,
                                                      width:
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width,
                                                      color: Colors.black26,
                                                      child: SizedBox(),
                                                    ),
                                                  ),
                                                  imageUrl: getImagePath(
                                                      _photos[index]),
                                                  alignment: Alignment.center,
                                                  fit: BoxFit.cover,
                                                  width: MediaQuery.of(context)
                                                      .size
                                                      .width,
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          Center(
                                                    child: Container(
                                                      height: 240.h,
                                                      width:
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width,
                                                      color:
                                                          Constants.kGreyColor,
                                                      child: Center(
                                                          child: Icon(
                                                              Icons.error)),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Container();
                                    },
                                  ),
                                )
                          ],
                        );
                      } else {
                        Map msg = _chats[index];
                        return ChatBubble(
                          customer: widget.customer,
                          chat: msg,
                        );
                      }
                    },
                  ),
                ),
                if (_complaintStatus == Constants.complaintClosed)
                  Constants.kSizeHeight_20,
                if (_complaintStatus == Constants.complaintClosed)
                  Center(
                    child: GText(
                      textData: "This complaint ticket has been closed",
                      textSize: 12.sp,
                      textColor: Constants.kGreenLightColor,
                    ),
                  ),
                if (_complaintStatus == Constants.complaintClosed)
                  if (widget.complaint["rating"] == "" ||
                      widget.complaint["rating"] == "null" ||
                      widget.complaint["rating"] == null)
                    Column(
                      children: [
                        Constants.kSizeHeight_20,
                        Center(
                          child: GText(
                            textData: "How was the help you received?",
                            textSize: 14.sp,
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
                              if (_ratingChanged) _rateComplaint();
                              setState(() => _ratingChanged = true);
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
                      ],
                    ),
                Constants.kSizeHeight_5,
                if (_complaintStatus == Constants.complaintOpened)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 0.0),
                          decoration: BoxDecoration(
                            color: Constants.kPrimaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey[500]!,
                                offset: Offset(0.0, 1.5),
                                blurRadius: 4.0,
                              ),
                            ],
                          ),
                          constraints: BoxConstraints(
                            maxHeight: 190,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(0.0),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: roundedContainer(),
                                ),
                                Constants.kSizeWidth_10,
                                IconButton(
                                  icon: Icon(Icons.send,
                                      color: Constants.kWhiteColor),
                                  onPressed: () => _appendMessageToLocalDb(),
                                ),
                                Constants.kSizeWidth_10,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_complaintStatus == Constants.complaintClosed)
                  Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
                    child: buildElevatedButton(
                      title: "Reopen Ticket",
                      bgColor: Constants.kGreenLightColor,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => ConfirmDialog(
                            title: "Reopen Ticket",
                            content:
                                "Are you sure you want to reopen this complaint ticket?",
                            confirmText: "Yes",
                            confirmTextColor: Constants.kPrimaryColor,
                            confirm: () => _reopenComplaint(),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Card buildComplaintInfoCard({required Widget widget}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 3.0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
        child: widget,
      ),
    );
  }

  Widget roundedContainer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(0.0),
      child: Container(
        color: Constants.kPrimaryLightColor,
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                controller: _textController,
                focusNode: _myFocusNode,
                minLines: 1,
                maxLines: 4,
                style: circularTextStyle(),
                decoration: circularInputDecoration(
                  circularRadius: 0.0,
                  title: "Type your message....",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _onChatSubmitSuccess(Chat chat) async {
    var _localDb = new LocalDatabase();
    await _localDb.updateChat(chat);
    if (mounted) setState(() => _loading = false);
  }

  _onRequestSuccess(List<dynamic> chats) async {
    await _localDb.deleteChat(widget.complaint["complaint_id"]);
    for (var i = 0; i < chats.length; i++) {
      _chat = Chat.map(chats[i]);
      await _localDb.addChat(_chat);
    }
    if (mounted) {
      setState(() => this._chats = chats);
      setState(() => _chatsLoading = false);
    }
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
    //   bgColor: Constants.kWarningLightColor,
    // );
  }
}
