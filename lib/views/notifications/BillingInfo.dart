// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Loaders.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/models/Feed.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:intl/intl.dart';

class BillingInfo extends StatefulWidget {
  final bool openFirstBill;

  const BillingInfo({Key? key, this.openFirstBill = false}) : super(key: key);

  @override
  _BillingInfoState createState() => _BillingInfoState();
}

class _BillingInfoState extends State<BillingInfo> {
  final RestDataSource _restDataSource = RestDataSource();
  final DateFormat _monthYearFormat = DateFormat('MMM yyyy');
  final NumberFormat currencyFormatter = NumberFormat.currency(
    name: 'GHS ',
    symbol: 'GHS ',
    decimalDigits: 2,
  );

  bool _loading = true;
  bool _refreshing = false;
  List<Feed> _billFeeds = [];
  List<bool> _expandedCards = [];

  @override
  void initState() {
    super.initState();
    _fetchBillFeeds();
  }

  Future<void> _fetchBillFeeds() async {
    try {
      setState(() {
        _refreshing = true;
      });

      // Use API call to get dynamic data
      final response = await _restDataSource.get(
        context,
        url: Endpoints.feeds_v3_bills,
      );

      // Print the response map
      print("API response: ${response.toString()}");

      // Check if response contains records and it's a list
      List<dynamic> feedsData = [];

      // Check if we have a valid response with records
      if (response['records'] != null && response['records'] is List) {
        feedsData = response['records'] as List;
        print(
            'Successfully retrieved ${feedsData.length} billing records from API');
      } else {
        // Try to access response data differently in case the structure is nested
        if (response['response'] != null && response['response'] is Map) {
          var responseData = response['response'];
          if (responseData['records'] != null &&
              responseData['records'] is List) {
            feedsData = responseData['records'] as List;
            print(
                'Retrieved ${feedsData.length} billing records from nested response');
          }
        }

        if (feedsData.isEmpty) {
          print('API response format unexpected: ${response.toString()}');
          // Show empty state instead of falling back to static data
        }
      }

      if (!mounted) return;

      if (feedsData.isNotEmpty) {
        final List<Feed> processedFeeds = [];

        for (var feed in feedsData) {
          try {
            if (feed != null) {
              final processedFeed = Feed.map(feed);

              // Check if billData exists and add it to the message for processing
              if (feed['billData'] != null && feed['billData'] is Map) {
                processedFeed.billData = feed['billData'];

                // Only add feeds that have billData with an account_number
                if (feed['billData']['account_number'] != null &&
                    feed['billData']['account_number'].toString().isNotEmpty) {
                  // Get account number and date for logging
                  String accountNumber =
                      feed['billData']['account_number'].toString();
                  String billPeriod = '';

                  if (processedFeed.dateCreated != null) {
                    try {
                      DateTime date =
                          DateTime.parse(processedFeed.dateCreated.toString());
                      billPeriod = DateFormat('yyyy-MM').format(date);
                    } catch (e) {
                      billPeriod = processedFeed.dateCreated.toString();
                    }
                  }

                  // Add bill to the processed list
                  processedFeeds.add(processedFeed);
                  print(
                      "Added bill: Account=$accountNumber, Period=$billPeriod");
                }
              }
            }
          } catch (e) {
            // Silently handle feed mapping errors
          }
        }

        if (!mounted) return;
        setState(() {
          _billFeeds = processedFeeds;
          _loading = false;
          _refreshing = false;

          // Set the first bill to be expanded if openFirstBill is true and there are bills
          if (widget.openFirstBill && processedFeeds.isNotEmpty) {
            _expandedCards =
                List.generate(processedFeeds.length, (index) => index == 0);
          } else {
            _expandedCards =
                List.generate(processedFeeds.length, (index) => false);
          }
        });
      } else {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _refreshing = false;
          _billFeeds = [];
          _expandedCards = [];
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return ErrorDialog(
                content: 'No billing information available',
              );
            },
          );
        }
      }
    } catch (e, stackTrace) {
      print('Exception details: $e');
      print('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return ErrorDialog(
              content:
                  'An error occurred while loading billing information: ${e.toString()}',
            );
          },
        );
      }
    }
  }

  // Helper method to safely parse string values to double
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background color
        Container(
          color: Constants.kPrimaryColor.withValues(alpha: 0.05),
        ),
        // Content
        _loading
            ? Center(
                child: CircularLoader(
                  loaderColor: Constants.kPrimaryColor,
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  _fetchBillFeeds();
                },
                child: Stack(
                  children: [
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
                    _buildBillingInfoList(),
                  ],
                ),
              ),
      ],
    );
  }

  Widget _buildBillingInfoList() {
    if (_billFeeds.isEmpty && !_loading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: GText(
            textData: "No billing information available",
            textAlign: TextAlign.center,
            textSize: 16.sp,
            textColor: Constants.kGreyColor,
            textMaxLines: 5,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8.w),
      itemCount: _billFeeds.length,
      itemBuilder: (context, index) {
        final billing = _billFeeds[index];
        // Use billData directly from the Feed object instead of parsing it from the message
        final billData = billing.billData;

        print(
            "Rendering bill card #${index + 1}: Account=${billData['account_number']}, Date=${_formatDateFromString(billing.dateCreated.toString())}");

        return _buildBillingCard(billing, billData, index);
      },
    );
  }

  Widget _buildBillingCard(
      Feed billing, Map<String, dynamic> billData, int index) {
    final isExpanded = _expandedCards[index];

    // Set header color for billing feeds
    final headerGradientColors = [
      Constants.kPrimaryColor,
      Constants.kPrimaryColor.withValues(alpha: 0.8),
    ];

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.white.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with curved background and toggle functionality
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedCards[index] = !_expandedCards[index];
                  });
                  HapticFeedback.lightImpact();
                },
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15.r),
                  topRight: Radius.circular(15.r),
                  bottomLeft: isExpanded ? Radius.zero : Radius.circular(15.r),
                  bottomRight: isExpanded ? Radius.zero : Radius.circular(15.r),
                ),
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: 80.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: headerGradientColors,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15.r),
                      topRight: Radius.circular(15.r),
                      bottomLeft:
                          isExpanded ? Radius.zero : Radius.circular(15.r),
                      bottomRight:
                          isExpanded ? Radius.zero : Radius.circular(15.r),
                    ),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Billing icon
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt_long,
                            color: Constants.kWhiteColor,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GText(
                                textData: billing.dateCreated != null
                                    ? ' ${_formatDateFromString(billing.dateCreated.toString())}'
                                    : ' N/A',
                                textSize: 14.sp,
                                textFont: Constants.kFontBold,
                                textColor: Colors.white.withValues(alpha: 0.9),
                              ),
                              SizedBox(height: 4.h),
                              GText(
                                textData: () {
                                  String accNum =
                                      billData['account_number'] ?? 'N/A';

                                  // Remove any 'ACCOUNT #:' prefix if it exists
                                  if (accNum
                                      .toUpperCase()
                                      .contains('ACCOUNT')) {
                                    accNum = accNum
                                        .replaceAll(
                                            RegExp(r'ACCOUNT\s*#?\s*:',
                                                caseSensitive: false),
                                            '')
                                        .trim();
                                  }

                                  return '$accNum';
                                }(),
                                textSize: 13.sp,
                                textFont: Constants.kFontBold,
                                textColor: Colors.white.withValues(alpha: 0.9),
                                textMaxLines: 1,
                                textOverflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 6.h),
                              GText(
                                textData: billData['account_name'] ?? '',
                                textSize: 12.sp,
                                textColor: Constants.kWhiteColor,
                              ),
                            ],
                          ),
                        ),
                        // Replace status badge with toggle arrow
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Constants.kWhiteColor,
                            size: 24.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bill details - only show when expanded
              if (isExpanded) _buildBillingDetails(billData),
              // _buildBillingDetails(billData, statusText, statusColor),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for detail rows used in billing details
  Widget _buildDetailRow(String label, String value,
      {bool isBold = false,
      bool isHighlighted = false,
      bool largeText = false,
      Color? highlightColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GText(
            textData: label,
            textSize: largeText ? 16.sp : 14.sp,
            textColor: Colors.grey[700],
            textFont: isBold ? Constants.kFontMedium : Constants.kFont,
          ),
          GText(
            textData: value,
            textSize: largeText ? 16.sp : 14.sp,
            textFont: isBold ? Constants.kFontBold : Constants.kFont,
            textColor: isHighlighted
                ? (highlightColor ?? Constants.kPrimaryColor)
                : Colors.black87,
          ),
        ],
      ),
    );
  }

  // Build billing details widget
  Widget _buildBillingDetails(Map<String, dynamic> billData) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Consumption section
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 45, 92, 131).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GText(
                  textData: 'Water Consumption',
                  textSize: 16.sp,
                  textFont: Constants.kFontMedium,
                  textColor: Constants.kPrimaryColor,
                ),
                SizedBox(height: 8.h),
                _buildDetailRow(
                  'Previous Reading',
                  billData['previous_reading']?.toString() ?? 'N/A',
                ),
                SizedBox(height: 6.h),
                _buildDetailRow(
                  'Current Reading',
                  billData['new_reading']?.toString() ?? 'N/A',
                ),
                SizedBox(height: 6.h),
                _buildDetailRow(
                  'Consumption',
                  '${billData['water_usage_rate']?.toString() ?? 'N/A'} m³',
                  isBold: true,
                ),
                SizedBox(height: 6.h),
                // _buildDetailRow(
                //   'Rate',
                //   billData['rate'] != null &&
                //           billData['water_usage_rate'].toString().isNotEmpty
                //       ? 'GHS ${billData['water_usage_rate']}/m³'
                //       : 'N/A',
                // ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Charges section
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
              // border: statusText.toLowerCase() == 'unpaid' ||
              //         statusText.toLowerCase() == 'overdue'
              //     ? Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5)
              //     : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GText(
                  textData: 'Charges',
                  textSize: 16.sp,
                  textFont: Constants.kFontMedium,
                  textColor: Constants.kPrimaryColor,
                ),
                SizedBox(height: 8.h),
                _buildDetailRow(
                  'Water Amount',
                  currencyFormatter
                      .format(_parseDouble(billData['water_amout'])),
                ),
                if (billData['fire_tax'] != null)
                  Padding(
                    padding: EdgeInsets.only(top: 6.h),
                    child: _buildDetailRow(
                      '1% Fire',
                      currencyFormatter
                          .format(_parseDouble(billData['fire_tax'])),
                    ),
                  ),
                if (billData['rural_tax'] != null)
                  Padding(
                    padding: EdgeInsets.only(top: 6.h),
                    child: _buildDetailRow(
                      '2% Rural',
                      currencyFormatter
                          .format(_parseDouble(billData['rural_tax'])),
                    ),
                  ),
                if (billData['service_charge'] != null &&
                    _parseDouble(billData['service_charge']) > 0)
                  Padding(
                    padding: EdgeInsets.only(top: 6.h),
                    child: _buildDetailRow(
                      'Service Charge',
                      currencyFormatter
                          .format(_parseDouble(billData['service_charge'])),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: _buildDetailRow(
                    'Month Total',
                    billData['month_total'] != null
                        ? currencyFormatter
                            .format(_parseDouble(billData['month_total']))
                        : 'N/A',
                    isBold: true,
                  ),
                ),
                SizedBox(height: 6.h),
                _buildDetailRow(
                  'Previous Balance',
                  billData['previous_balance'] != null
                      ? currencyFormatter
                          .format(_parseDouble(billData['previous_balance']))
                      : 'N/A',
                ),
                if (billData['credit_adj'] != null)
                  _buildDetailRow(
                    'Credit Adjustment',
                    currencyFormatter
                        .format(_parseDouble(billData['credit_adj'])),
                  ),
                SizedBox(height: 6.h),
                if (billData['due_by'] != null)
                  _buildDetailRow(
                    'Due By',
                    billData['due_by'],
                  ),
              ],
            ),
          ),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  // Helper method to format date from API string format
  String _formatDateFromString(String dateString) {
    try {
      // API date format is like "2025-04-10T04:13:35.000Z"
      DateTime parsedDate = DateTime.parse(dateString);
      return _monthYearFormat.format(parsedDate);
    } catch (e) {
      print("Error parsing date: $e");
      return "N/A";
    }
  }
}
