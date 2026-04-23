import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gwcl/helpers/ColumnBuilder.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/LocalNotifications.dart';
import 'package:gwcl/helpers/ReadMore.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/models/Notification.dart';
import 'package:gwcl/system/LocalDatabase.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/AppHeaders.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:gwcl/templates/Modals.dart';
import 'package:gwcl/views/notifications/BillingTabs.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:gwcl/helpers/TimeAgo.dart' as timeAgo;

class Notifications extends StatefulWidget {
  static const String id = "/notifications";
  @override
  _NotificationsState createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  ScrollController _scrollController = ScrollController();
  bool _loading = false, _loadingMore = false, _refreshing = false, _hasMoreRecords = false;
  var _notifications = List.empty(growable: true);
  late NotificationModel _notificationModel;
  int _page = 1;

  _loadNotifications() async {
    var _localDb = new LocalDatabase();
    var _res = await _localDb.getNotifications();
    if (mounted) {
      setState(() => this._notifications = _res);
      _fetchNotifications();
      return;
    }
  }

  _fetchNotifications() async {
    setState(() => hasData(_notifications) ? _refreshing = true : _loading = true);
    RestDataSource _request = new RestDataSource();
    if (mounted)
      _request.get(context, url: Endpoints.notifications).then((Map response) {
        if (response[Constants.success]) {
          var records = response[Constants.response]["records"];
          var _totalPage = response[Constants.response]["total_page"];
          if (_totalPage > _page) {
            setState(() {
              this._page = _page + 1;
              _hasMoreRecords = true;
            });
          }
          _onRequestSuccess(records);
        } else {
          if (mounted)
            setState(() {
              _refreshing = false;
              _loading = false;
            });
          _onRequestFailed(Constants.unableToRefresh);
        }
        _setNotificationsAsRead();
      });
  }

  _setNotificationsAsRead() {
    RestDataSource _request = new RestDataSource();
    if (mounted) _request.get(context, url: Endpoints.notifications_read).then((Map response) {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _loadNotifications();
    super.initState();
    LocalNotification.removeBadger();
    _scrollController.addListener(() {
      double _maxScroll = _scrollController.position.maxScrollExtent;
      double _currentScroll = _scrollController.position.pixels;
      // double _delta = MediaQuery.of(context).size.height * 0.5;
      if (_maxScroll == _currentScroll) {
        if (!_loadingMore) _loadMoreRecords();
      }
    });
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
              title: "Notifications",
            ),
          ),
        ),
        body: BillingTabs(),

      ),
    );
  }
        
        
  //       Stack(
  //         children: [
  //           Container(
  //             decoration: BoxDecoration(
  //               image: DecorationImage(image: Constants.kBgTwo, fit: BoxFit.cover, colorFilter: ColorFilter.linearToSrgbGamma()),
  //             ),
  //           ),
  //           _refreshing
  //               ? Column(
  //                   crossAxisAlignment: CrossAxisAlignment.stretch,
  //                   children: [
  //                     Container(
  //                       child: SizedBox(
  //                         height: 3.h,
  //                         child: BarLoader(
  //                           barColor: Constants.kPrimaryColor,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 )
  //               : Container(),
  //           _loadingMore
  //               ? Column(
  //                   crossAxisAlignment: CrossAxisAlignment.stretch,
  //                   children: [
  //                     Container(
  //                       child: SizedBox(
  //                         height: 1.h,
  //                         child: BarLoader(
  //                           barColor: Constants.kPrimaryColor,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 )
  //               : Container(),
  //           SingleChildScrollView(
  //             physics: BouncingScrollPhysics(),
  //             child: Padding(
  //               padding: EdgeInsets.symmetric(
  //                 horizontal: 10.w,
  //                 vertical: Constants.indexVerticalSpace,
  //               ),
  //               child: Column(
  //                 children: [
  //                   !hasData(_notifications)
  //                       ? Center(
  //                           child: Padding(
  //                             padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
  //                             child: GText(
  //                               textData: _loading ? " " : "No notifications to display",
  //                               textAlign: TextAlign.center,
  //                               textSize: 13.sp,
  //                               textColor: Constants.kGreyColor,
  //                               textMaxLines: 5,
  //                             ),
  //                           ),
  //                         )
  //                       : ColumnBuilder(
  //                           itemCount: _notifications.length,
  //                           itemBuilder: (BuildContext context, int index) {
  //                             Map notification = _notifications[index];
  //                             return NotificationItem(
  //                               key: UniqueKey(),
  //                               notification: notification,
  //                             );
  //                           },
  //                         ),
  //                   Constants.kSizeHeight_50
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  _onRequestSuccess(List<dynamic> notifications) async {
    var _localDb = new LocalDatabase();
    for (var i = 0; i < notifications.length; i++) {
      _notificationModel = NotificationModel.map(notifications[i]);
      await _localDb.addNotification(_notificationModel);
    }
    var _res = await _localDb.getNotifications();
    if (mounted) {
      setState(() => this._notifications = _res);
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

  _loadMoreRecords() {
    if (_hasMoreRecords) {
      HapticFeedback.lightImpact();
      setState(() => _loadingMore = true);
      var _moreRecords = List.empty(growable: true);
      RestDataSource _request = new RestDataSource();
      _request
          .get(
        context,
        url: Endpoints.notifications + "?page=$_page&limit=10",
      )
          .then((Map response) async {
        if (mounted) setState(() => _loadingMore = false);
        if (response[Constants.success]) {
          HapticFeedback.lightImpact();
          _moreRecords = response[Constants.response]["records"];
          var _totalPage = response[Constants.response]["total_page"];
          if (mounted) setState(() => this._notifications.addAll(_moreRecords));
          if (_totalPage > _page) {
            setState(() {
              this._page = _page + 1;
              _hasMoreRecords = true;
            });
          } else {
            setState(() {
              _hasMoreRecords = false;
            });
          }
        } else {
          _onRequestFailed(Constants.unableToRefresh);
        }
      });
    }
  }
}

class NotificationItem extends StatelessWidget {
  final dynamic notification;

  const NotificationItem({Key? key, required this.notification}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData notificationIconData;
    Color _color;
    switch (notification["notification_type"]) {
      case "billing":
        notificationIconData = Icons.date_range;
        _color = Colors.blue;
        break;
      case "payment":
        notificationIconData = Icons.credit_card;
        _color = Colors.green;
        break;
      case "report":
        notificationIconData = Icons.file_download;
        _color = Constants.kPrimaryColor;
        break;
      case "chat":
        notificationIconData = Icons.history_outlined;
        _color = Colors.pink;
        break;
      default:
        notificationIconData = Icons.notifications_active_outlined;
        _color = Constants.kGreyColor;
        break;
    }
    return Card(
      child: Container(
        child: ListTile(
          onTap: () {
            HapticFeedback.lightImpact();
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => Container(
                child: ScreenModal(
                  title: "Message",
                  titleColor: _color,
                  isLoading: false,
                  height: 0.5,
                  body: Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ReadMoreText(
                          "${notification["message"]}",
                          trimLines: 500,
                          colorClickableText: Constants.kPrimaryColor,
                          trimMode: TrimMode.Line,
                          trimCollapsedText: 'Show more',
                          trimExpandedText: ' ',
                          style: TextStyle(fontSize: 14.sp),
                          moreStyle: TextStyle(fontSize: 13.sp, fontFamily: Constants.kFontMedium, color: Constants.kPrimaryColor),
                          lessStyle: TextStyle(fontSize: 13.sp, fontFamily: Constants.kFontMedium, color: Constants.kRedColor),
                          onLinkPressed: (link) {
                            HapticFeedback.lightImpact();
                            launchURL(link);
                          },
                        ),
                        Constants.kSizeHeight_5,
                        GText(
                          textData: "${timeAgo.format(DateTime.parse(notification["date_created"]))}",
                          textFont: Constants.kFontLight,
                          textSize: 10.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          contentPadding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 10.w),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GText(
                textData: "${notification["message"]}",
                textFont: Constants.kFontLight,
                textSize: 13.sp,
                textMaxLines: 10,
              ),
              Constants.kSizeHeight_5,
              GText(
                textData: "${timeAgo.format(DateTime.parse(notification["date_created"]))}",
                textFont: Constants.kFontLight,
                textSize: 10.sp,
              ),
            ],
          ),
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                notificationIconData,
                color: _color,
              ),
              GText(
                textData: notification["status"] == "read" ? "" : "new",
                textFont: Constants.kFontMedium,
                textSize: 10.sp,
                textColor: Constants.kRedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
