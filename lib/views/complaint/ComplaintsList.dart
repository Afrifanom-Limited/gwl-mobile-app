import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/LocalNotifications.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/models/Complaint.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/views/complaint/ChatComponents.dart';
import 'package:gwcl/views/complaint/LodgeComplaint.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:gwcl/helpers/Functions.dart';

class ComplaintsList extends StatefulWidget {
  static const String id = "/complaints_list";
  final dynamic customer;
  const ComplaintsList({Key? key, this.customer}) : super(key: key);

  @override
  _ComplaintsListState createState() => _ComplaintsListState();
}

class _ComplaintsListState extends State<ComplaintsList> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  bool _loading = false, _refreshing = false;
  var _complaints = List.empty(growable: true), _customer;
  late Complaint _complaint;

  _loadComplaints() async {
    try {
      var _localDb = new LocalDatabase();
      var _res = await _localDb.getComplaints();
      if (mounted) {
        setState(() => this._complaints = _res);
        _fetchComplaints();
        return;
      }
    } catch (e) {}
  }

  _fetchComplaints() async {
    setState(() => hasData(_complaints) ? _refreshing = true : _loading = true);
    RestDataSource _request = new RestDataSource();
    _request.get(context, url: Endpoints.complaints).then((Map response) {
      if (response[Constants.success]) {
        var records = response[Constants.response]["records"];
        _onRequestSuccess(records);
      } else {
        if (mounted)
          setState(() {
            _refreshing = false;
            _loading = false;
          });
        _onRequestFailed(Constants.unableToRefresh);
      }
    });
  }

  _loadCustomerInfo() async {
    var _localDb = new LocalDatabase();
    _customer = await _localDb.getCustomer();
    if (mounted) {
      _loadComplaints();
    }
  }

  @override
  void initState() {
    _loadCustomerInfo();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LocalNotification.removeBadger();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
              title: "My Complaints",
              actionButton: Container(
                margin: EdgeInsets.only(top: 18.h, right: 10.w),
                child: IconButton(
                  icon: _refreshing
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
                    _fetchComplaints();
                  },
                ),
              ),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            _fetchComplaints();
          },
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(image: Constants.kBgTwo, fit: BoxFit.cover, colorFilter: ColorFilter.linearToSrgbGamma()),
                ),
              ),
              _refreshing
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          child: SizedBox(
                            height: 3.h,
                            child: BarLoader(
                              barColor: Constants.kPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Constants.indexHorizontalSpace,
                  vertical: Constants.indexVerticalSpace,
                ),
                child: !hasData(_complaints)
                    ? Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: GText(
                              textData: "No active complaints to display. "
                                  "To lodge a complaint, kindly tap on any"
                                  " of the '+' icons on this screen",
                              textAlign: TextAlign.center,
                              textSize: 13.sp,
                              textColor: Constants.kGreyColor,
                              textMaxLines: 5,
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: BouncingScrollPhysics(),
                        padding: EdgeInsets.only(bottom: 60.h),
                        separatorBuilder: (BuildContext context, int index) {
                          return Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              height: 0.5,
                              width: MediaQuery.of(context).size.width / 1.3,
                              child: Divider(),
                            ),
                          );
                        },
                        itemCount: _complaints.length,
                        itemBuilder: (BuildContext context, int index) {
                          Map complaint = _complaints[index];
                          return ComplaintItem(
                            key: UniqueKey(),
                            complaint: complaint,
                            counter: complaint['unread_chat_count'] != "null" ? int.parse(complaint['unread_chat_count'].toString()) : 0,
                            customer: _customer,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          elevation: 20,
          hoverColor: Constants.kPrimaryColor,
          backgroundColor: Constants.kPrimaryColor,
          autofocus: true,
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pushReplacementNamed(context, LodgeComplaint.id);
          },
          child: Icon(Icons.add),
          tooltip: 'Lodge Complaint',
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  _onRequestSuccess(List<dynamic> complaints) async {
    var _localDb = new LocalDatabase();
    for (var i = 0; i < complaints.length; i++) {
      _complaint = Complaint.map(complaints[i]);
      await _localDb.addComplaint(_complaint);
    }
    var _res = await _localDb.getComplaints();
    if (mounted) {
      setState(() => this._complaints = _res);
      setState(() {
        _refreshing = false;
        _loading = false;
      });
    }
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
    //   bgColor: Constants.kWarningLightColor,
    // );
  }
}
