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
  const Feeds({Key? key}) : super(key: key);

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
    RestDataSource _request = new RestDataSource();
    setState(() {
      currentUrl = Endpoints.feeds;
      currentSearchValue = "";
    });
    if (mounted)
      _request.get(context, url: currentUrl).then((Map response) {
        if (response[Constants.success]) {
          var records = response[Constants.response]["records"];
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
      color: Constants.kWhiteColor.withOpacity(0.8),
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
  // bool _isLiked = false;
  final _fullDateFormat = DateFormat("dd MMMM, yyyy hh:mm aaa");
  String _formatDate(DateTime date, DateFormat format) {
    try {
      return _fullDateFormat.format(date);
      // return DateFormat.jm().format(date);
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

  @override
  void initState() {
    super.initState();
    // _isLiked = widget.feed.isLiked(widget.feed.isLikedByMe);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var media = widget.feed.media;
    if (media.toString().toLowerCase() == 'null' || media.toString().toLowerCase() == '') {
      media = [];
    } else {
      media = widget.feed.media.split(',');
    }
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      GText(
                        textData: "${widget.feed.author}",
                        textFont: Constants.kFontLight,
                        textSize: 12.sp,
                      ),
                      SizedBox(height: 3.h),
                      GText(
                        textData: "${_formatDate(DateTime.parse(widget.feed.dateCreated), _fullDateFormat)}",
                        textFont: Constants.kFontLight,
                        textSize: 9.sp,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Constants.kSizeHeight_10,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GText(
                    textData: "${widget.feed.title}",
                    textSize: 13.sp,
                    textMaxLines: 5,
                    textDecoration: TextDecoration.underline,
                  ),
                  Constants.kSizeHeight_5,
                  ReadMoreText(
                    "${widget.feed.message}",
                    trimLines: 2,
                    colorClickableText: Constants.kPrimaryColor,
                    trimMode: TrimMode.Line,
                    trimCollapsedText: 'Show more',
                    trimExpandedText: ' ',
                    style: TextStyle(fontSize: 13.sp),
                    moreStyle: TextStyle(fontSize: 13.sp, fontFamily: Constants.kFontMedium, color: Constants.kPrimaryColor),
                    lessStyle: TextStyle(fontSize: 13.sp, fontFamily: Constants.kFontMedium, color: Constants.kRedColor),
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
                  Constants.kSizeHeight_10,
                ],
              ),
            ),
            if (media.length > 0)
              CarouselSlider.builder(
                itemCount: media.length,
                itemBuilder: (BuildContext context, int index, int pageViewIndex) {
                  return IntrinsicHeight(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: GestureDetector(
                        onTap: () => viewImages(context, media, index),
                        child: CachedNetworkImage(
                            placeholder: (context, url) => Center(
                                  child: Container(
                                    height: 180.h,
                                    width: MediaQuery.of(context).size.width,
                                    color: Constants.kPrimaryLightColor,
                                    child: SizedBox(),
                                  ),
                                ),
                            imageUrl: getImagePath(media[index]),
                            alignment: Alignment.center,
                            fit: BoxFit.fitWidth,
                            width: MediaQuery.of(context).size.width),
                      ),
                    ),
                  );
                },
                options: CarouselOptions(
                  viewportFraction: 1.0,
                  initialPage: 0,
                  reverse: false,
                  enableInfiniteScroll: false,
                  enlargeCenterPage: true,
                  onPageChanged: (index, reason) {
                    setState(() => _currentMediaIndex = index);
                  },
                  scrollDirection: Axis.horizontal,
                ),
              ),
            Constants.kSizeHeight_5,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Row(
                children: [
                  // Padding(
                  //   padding:
                  //       const EdgeInsets.only(top: 8.0, left: 8.0, bottom: 8.0),
                  //   child: widget.feed.isLiked(widget.feed.isLikedByMe)
                  //       ? Row(
                  //           children: [
                  //             Icon(Icons.thumb_up,
                  //                 size: 20.sp, color: Constants.kGreenLightColor),
                  //             Constants.kSizeWidth_5,
                  //             GText(
                  //                 textData:
                  //                     "You and ${NumberFormat.compact().format(widget.feed.reactions)} others liked this")
                  //           ],
                  //         )
                  //       : Builder(builder: (BuildContext context) {
                  //           return ThumbsUpIconAnimator(
                  //             isLiked: _isLiked,
                  //             size: 24.sp,
                  //             onTap: () {
                  //               HapticFeedback.lightImpact();
                  //               setState(() => _isLiked = !_isLiked);
                  //               if (_isLiked) {
                  //                 _submitImpression('like');
                  //               }
                  //             },
                  //           );
                  //         }),
                  // ),
                  // Spacer(),
                  if (media.length > 1)
                    PhotoCarouselIndicator(
                      photoCount: media.length,
                      activePhotoIndex: _currentMediaIndex,
                    ),
                ],
              ),
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
