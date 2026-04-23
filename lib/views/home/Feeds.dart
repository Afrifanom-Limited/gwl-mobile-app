import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gwcl/helpers/ColumnBuilder.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/LocalNotifications.dart';
import 'package:gwcl/helpers/ReactionButton.dart';
import 'package:gwcl/helpers/ReadMore.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/models/Feed.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Feeds extends StatefulWidget {
  final bool newFeedsAvailable;
  final ValueChanged<bool>? onNewFeedsAvailable;
  const Feeds({
    Key? key,
    required this.newFeedsAvailable,
    this.onNewFeedsAvailable,
  }) : super(key: key);

  @override
  State<Feeds> createState() => _FeedsState();
}

class _FeedsState extends State<Feeds> {
  ScrollController _scrollController = ScrollController();
  var _feeds = List.empty(growable: true);
  bool _loading = false, _loadingMore = false, _refreshing = false, _hasMoreRecords = false;
  var currentUrl = Endpoints.feeds;
  var currentSearchValue = "";
  int _page = 1;

  bool _hasNewFeeds({
    required List<dynamic> previousFeeds,
    required List<dynamic> latestFeeds,
  }) {
    if (previousFeeds.isEmpty || latestFeeds.isEmpty) return false;

    final previousIds = previousFeeds
        .map((feed) => feed["feed_id"]?.toString())
        .whereType<String>()
        .toSet();
    final latestIds = latestFeeds
        .map((feed) => feed["feed_id"]?.toString())
        .whereType<String>()
        .toSet();

    return latestIds.difference(previousIds).isNotEmpty;
  }

  _loadFeeds() async {
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    var _cachedFeeds = _localStorage.getString(Constants.feeds);
    if (_cachedFeeds != null) {
      setState(() => _feeds = jsonDecode(_cachedFeeds));
    }
    _fetchFeeds();
    return;
  }

  _fetchFeeds() async {
    setState(() => hasData(_feeds) ? _refreshing = true : _loading = true);
    SharedPreferences _localStorage = await SharedPreferences.getInstance();
    final previousFeeds = List<dynamic>.from(_feeds);
    RestDataSource _request = new RestDataSource();
    setState(() {
      currentUrl = Endpoints.feeds;
      currentSearchValue = "";
    });
    if (mounted)
      _request.get(context, url: currentUrl).then((Map response) {
        if (response[Constants.success]) {
          var records = response[Constants.response]["records"];
          final hasNew = _hasNewFeeds(
            previousFeeds: previousFeeds,
            latestFeeds: List<dynamic>.from(records),
          );
          widget.onNewFeedsAvailable?.call(hasNew);
          var _totalPage = response[Constants.response]["total_page"];
          if (_totalPage > _page) {
            if (mounted) {
              setState(() {
                this._page = _page + 1;
                _hasMoreRecords = true;
              });
            }
          }
          if (mounted) {
            setState(() {
              this._feeds = records;
              _refreshing = false;
              _loading = false;
            });
            _localStorage.setString(Constants.feeds, json.encode(records));
          }
        } else {
          if (mounted)
            setState(() {
              _refreshing = false;
              _loading = false;
            });
          // _onRequestFailed(Constants.unableToRefresh);
        }
      });
  }

  _searchFeeds(String searchValue) async {
    setState(() => _loading = true);
    RestDataSource _request = new RestDataSource();
    setState(() {
      currentUrl = Endpoints.feeds + "?search=$searchValue";
      currentSearchValue = searchValue;
    });
    if (mounted)
      _request.get(context, url: currentUrl).then((Map response) {
        if (response[Constants.success]) {
          var records = response[Constants.response]["records"];
          var _totalPage = response[Constants.response]["total_page"];
          if (_totalPage > _page) {
            setState(() {
              this._page = _page + 1;
              _hasMoreRecords = true;
            });
          }
          if (mounted) {
            setState(() {
              this._feeds = records;
              _loading = false;
            });
          }
        } else {
          if (mounted)
            setState(() {
              _loading = false;
            });
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _loadFeeds();
    super.initState();
    LocalNotification.removeBadger();
    _scrollController.addListener(() {
      double _maxScroll = _scrollController.position.maxScrollExtent;
      double _currentScroll = _scrollController.position.pixels;
      if (_maxScroll == _currentScroll) {
        if (!_loadingMore) _loadMoreFeeds();
      }
    });
  }

  _openSearchModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SearchBox(onGo: (String text) async {
            _searchFeeds(text);
            Navigator.pop(context);
          }),
        );
      },
    );
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
        appBar: currentUrl != Endpoints.feeds
            ? AppBar(
                centerTitle: false,
                title: Chip(
                  label: Text("$currentSearchValue"),
                  onDeleted: () {
                    _loadFeeds();
                  },
                ),
              )
            : null,
        floatingActionButton: FloatingActionButton(onPressed: () => _openSearchModal(), backgroundColor: Constants.kNearlyDarkBlueColor, child: Icon(Icons.search)),
        body: RefreshIndicator(
          onRefresh: () async {
            _fetchFeeds();
          },
          child: Stack(
            children: [
              SizedBox(),
              _refreshing
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          child: SizedBox(
                            height: 1.h,
                            child: BarLoader(
                              barColor: Constants.kPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(),
              SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: Constants.indexVerticalSpace,
                  ),
                  child: Column(
                    children: [
                      !hasData(_feeds)
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                                child: GText(
                                  textData: _loading ? " " : "No feeds to display",
                                  textAlign: TextAlign.center,
                                  textSize: 13.sp,
                                  textColor: Constants.kGreyColor,
                                  textMaxLines: 5,
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                ColumnBuilder(
                                  itemCount: _feeds.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    Feed feed = Feed.map(_feeds[index]);
                                    return FeedItem(feed: feed);
                                  },
                                ),
                                _loadingMore
                                    ? Container(
                                        child: CircularLoader(
                                          loaderColor: Constants.kPrimaryColor,
                                          isSmall: true,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Container(),
                              ],
                            ),
                      Constants.kSizeHeight_10
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _onRequestFailed(dynamic errorText) async {
    showDialog(
      context: context,
      builder: (_) => ErrorDialog(
        content: errorText.toString().replaceAll(RegExp(Constants.errorFilter), ""),
      ),
    );
  }

  _loadMoreFeeds() {
    if (_hasMoreRecords) {
      HapticFeedback.lightImpact();
      setState(() => _loadingMore = true);
      var _moreRecords = List.empty(growable: true);
      RestDataSource _request = new RestDataSource();
      _request
          .get(
        context,
        url: currentUrl + "?page=$_page&limit=10",
      )
          .then((Map response) async {
        if (mounted) setState(() => _loadingMore = false);
        if (response[Constants.success]) {
          HapticFeedback.lightImpact();
          _moreRecords = response[Constants.response]["records"];
          var _totalPage = response[Constants.response]["total_page"];
          if (mounted) setState(() => this._feeds.addAll(_moreRecords));
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

class FeedItem extends StatefulWidget {
  final Feed feed;
  const FeedItem({Key? key, required this.feed}) : super(key: key);

  @override
  State<FeedItem> createState() => _FeedItemState();
}

class _FeedItemState extends State<FeedItem> {
  int _currentMediaIndex = 0;
  final _fullDateFormat = DateFormat("dd MMMM, yyyy hh:mm aaa");

  String _formatDate(DateTime date, DateFormat format) {
    try {
      return _fullDateFormat.format(date);
    } catch (e) {}
    return '';
  }

  _submitImpression(reaction) async {
    RestDataSource _request = new RestDataSource();
    if (mounted)
      _request.get(context, url: Endpoints.feeds_seen, queryParams: {
        "feed_id": "${widget.feed.feedId}",
        "impression_type": "$reaction",
      }).then((Map response) {
        debugPrint(response[Constants.success].toString());
      });
  }

  // Helper method to get feed type icon and color
  Widget _getFeedTypeIndicator() {
    IconData icon;
    Color color;

    switch (widget.feed.feedType?.toLowerCase()) {
      case 'tip':
        icon = Icons.lightbulb_outline;
        color = Colors.amber;
        break;
      case 'news':
        icon = Icons.article_outlined;
        color = Colors.blue;
        break;
      case 'alert':
        icon = Icons.warning_amber_outlined;
        color = Colors.red;
        break;
      case 'promo':
        icon = Icons.local_offer_outlined;
        color = Colors.green;
        break;
      default:
        icon = Icons.info_outline;
        color = Constants.kPrimaryColor;
    }

    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(
        icon,
        color: color,
        size: 16.sp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var media = widget.feed.media;
    if (media.toString().toLowerCase() == 'null' ||
        media.toString().toLowerCase() == '') {
      media = [];
    } else {
      media = widget.feed.media.split(',');
    }

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 10.h, horizontal: 2.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with author info and feed type indicator
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Constants.kPrimaryColor.withValues(alpha: 0.2),
                  radius: 20.sp,
                  child: Text(
                    widget.feed.author.isNotEmpty
                        ? widget.feed.author[0].toUpperCase()
                        : "G",
                    style: TextStyle(
                      color: Constants.kPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GText(
                        textData: "${widget.feed.author}",
                        textFont: Constants.kFontMedium,
                        textSize: 14.sp,
                      ),
                      SizedBox(height: 2.h),
                      GText(
                        textData:
                            "${_formatDate(DateTime.parse(widget.feed.dateCreated), _fullDateFormat)}",
                        textFont: Constants.kFontLight,
                        textSize: 10.sp,
                        textColor: Constants.kGreyColor,
                      ),
                    ],
                  ),
                ),
                _getFeedTypeIndicator(),
              ],
            ),

            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Divider(
                height: 1,
                thickness: 1,
                color: Constants.kGreyColor.withValues(alpha: 0.2),
              ),
            ),

            // Title and message
            Padding(
              padding: EdgeInsets.symmetric(vertical: 5.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GText(
                    textData: "${widget.feed.title}",
                    textSize: 14.sp,
                    textMaxLines: 5,
                    textFont: Constants.kFontMedium,
                    textColor: Colors.black,
                  ),
                  SizedBox(height: 12.h),
                  ReadMoreText(
                    "${widget.feed.message}",
                    trimLines: 3,
                    colorClickableText: Constants.kPrimaryColor,
                    trimMode: TrimMode.Line,
                    trimCollapsedText: '\nShow more',
                    trimExpandedText: '\nShow less',
                    style: TextStyle(
                      fontSize: 14.sp,
                      height: 1.5,
                      color: Colors.black.withValues(alpha: 0.8),
                    ),
                    moreStyle: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: Constants.kFontMedium,
                      color: Constants.kPrimaryColor,
                    ),
                    lessStyle: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: Constants.kFontMedium,
                      color: Constants.kPrimaryColor,
                    ),
                    callback: (bool) {
                      HapticFeedback.lightImpact();
                      if (!bool) {
                        _submitImpression('view');
                      }
                    },
                    onLinkPressed: (link) {
                      HapticFeedback.lightImpact();
                      launchURL(link);
                    },
                  ),
                ],
              ),
            ),

            // Media content - Enhanced for better visual appeal
            if (media.length > 0)
              Column(
                children: [
                  SizedBox(height: 16.h),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: CarouselSlider.builder(
                        itemCount: media.length,
                        itemBuilder: (BuildContext context, int index,
                            int pageViewIndex) {
                          return IntrinsicHeight(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.4,
                              ),
                              child: GestureDetector(
                                onTap: () => viewImages(context, media, index),
                                child: Stack(
                                  children: [
                                    CachedNetworkImage(
                                      placeholder: (context, url) => Center(
                                        child: Container(
                                          height: 200.h,
                                          width:
                                              MediaQuery.of(context).size.width,
                                          color: Constants.kPrimaryLightColor,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: Constants.kPrimaryColor,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      imageUrl: getImagePath(media[index]),
                                      alignment: Alignment.center,
                                      fit: BoxFit.cover,
                                      width: MediaQuery.of(context).size.width,
                                      height: 200.h,
                                    ),
                                    // Gradient overlay at the bottom for better visibility of indicators
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      height: 40.h,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(alpha: 0.3),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        options: CarouselOptions(
                          viewportFraction: 1.0,
                          initialPage: 0,
                          reverse: false,
                          enableInfiniteScroll: media.length > 1,
                          enlargeCenterPage: true,
                          onPageChanged: (index, reason) {
                            setState(() => _currentMediaIndex = index);
                          },
                          scrollDirection: Axis.horizontal,
                          autoPlay: media.length > 1,
                          autoPlayInterval: Duration(seconds: 5),
                          autoPlayAnimationDuration:
                              Duration(milliseconds: 800),
                          autoPlayCurve: Curves.fastOutSlowIn,
                        ),
                      ),
                    ),
                  ),
                  if (media.length > 1)
                    Padding(
                      padding: EdgeInsets.only(top: 12.h),
                      child: PhotoCarouselIndicator(
                        photoCount: media.length,
                        activePhotoIndex: _currentMediaIndex,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
class PhotoCarouselIndicator extends StatelessWidget {
  final int photoCount;
  final int activePhotoIndex;

  PhotoCarouselIndicator({
    required this.photoCount,
    required this.activePhotoIndex,
  });

  Widget _buildDot({required bool isActive}) {
    return Container(
      child: Padding(
        padding: EdgeInsets.only(left: 3.0, right: 3.0, top: 8.h),
        child: Container(
          height: isActive ? 7.5 : 6.0,
          width: isActive ? 7.5 : 6.0,
          decoration: BoxDecoration(
            color: isActive ? Constants.kPrimaryColor : Colors.grey,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(photoCount, (i) => i).map((i) => _buildDot(isActive: i == activePhotoIndex)).toList(),
    );
  }
}

class SearchBox extends StatefulWidget {
  final ValueChanged<String> onGo;
  const SearchBox({super.key, required this.onGo});
  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  final _searchController = TextEditingController();
  bool _canSearch = false;

  @override
  void initState() {
    _searchController.addListener(() {
      setState(() => _canSearch = _searchController.text.isNotEmpty);
    });
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: TextStyle(fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'Search ...',
              hintStyle: TextStyle(color: Constants.kGreyColor, fontSize: 14.sp),
              fillColor: Constants.kWhiteColor,
              filled: true,
              border: InputBorder.none,
            ),
          ),
        ),
        TextButton(
            child: Opacity(
                opacity: _canSearch ? 1.0 : 0.3,
                child: GText(
                  textData: 'Go',
                  textColor: Constants.kPrimaryColor,
                  textFont: Constants.kFontMedium,
                  textSize: 16.sp,
                )),
            onPressed: () {
              if (_canSearch) {
                widget.onGo(_searchController.text);
              }
            })
      ],
    );
  }
}
