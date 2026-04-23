import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/helpers/Text.dart';
import 'package:gwcl/models/Feed.dart';
import 'package:gwcl/system/RestDataSource.dart';
import 'package:intl/intl.dart';

class Payments extends StatefulWidget {
  final bool openFirstBill;

  const Payments({Key? key, this.openFirstBill = false}) : super(key: key);

  @override
  _PaymentsState createState() => _PaymentsState();
}

class _PaymentsState extends State<Payments> {
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

      final response = await _restDataSource.get(
        context,
        url: Endpoints.feeds_v3_payments,
      );

      print("--------- > Payment API response: $response");

      // Check if response contains 'records' directly or nested in 'response'
      List<dynamic>? feedsData;

      // Try to find the data in different possible locations
      if (response['records'] != null && response['records'] is List) {
        feedsData = response['records'] as List;
        print('Found ${feedsData.length} payment records directly in response["records"]');
      } else if (response['response'] != null && response['response'] is Map) {
        var responseData = response['response'] as Map;
        if (responseData['records'] != null &&
            responseData['records'] is List) {
          feedsData = responseData['records'] as List;
          print('Found ${feedsData.length} payment records in nested response["response"]["records"]');
        }
      } else if (response['data'] != null && response['data'] is List) {
        feedsData = response['data'] as List;
        print('Found ${feedsData.length} payment records in response["data"]');
      }

      if (feedsData != null && feedsData.isNotEmpty) {
        final List<Feed> processedFeeds = [];
        final Set<String> uniqueFeedIds = {}; // Track unique feed_ids to prevent duplicates

        for (var feed in feedsData) {
          try {
            if (feed != null) {
              // Skip this feed if we've already processed one with the same ID
              String feedId = feed['feed_id']?.toString() ?? '';
              if (feedId.isNotEmpty && uniqueFeedIds.contains(feedId)) {
                print('Skipping duplicate feed_id: $feedId');
                continue;
              }
              
              // Add this feed_id to our tracking set
              if (feedId.isNotEmpty) {
                uniqueFeedIds.add(feedId);
              }
              
              final processedFeed = Feed.map(feed);

              // Only include feeds with feed_type 'payment'
              if (processedFeed.feedType?.toLowerCase() == 'payment') {
                // Check if paymentData exists and add it to the feed for processing
                if (feed['paymentData'] != null && feed['paymentData'] is Map) {
                  processedFeed.paymentData = feed['paymentData'];

                  // Only add feeds that have paymentData with transaction details
                  if ((feed['paymentData']['transaction_id'] != null ||
                          feed['paymentData']['trans_id'] != null) &&
                      processedFeed.message != null &&
                      processedFeed.message.toString().isNotEmpty) {
                    processedFeeds.add(processedFeed);
                  }
                } else if (processedFeed.message != null &&
                    processedFeed.message.toString().isNotEmpty) {
                  // If no paymentData but has a message, still add it as a fallback
                  processedFeeds.add(processedFeed);
                }
              }
            }
          } catch (e) {
            print('Error processing payment feed: $e');
            // Silently handle feed mapping errors
          }
        }

        setState(() {
          _billFeeds = processedFeeds;
          _loading = false;
          _refreshing = false;

          // Initialize expanded state for each card
          _expandedCards = List.generate(
            _billFeeds.length,
            (index) => widget.openFirstBill && index == 0,
          );
        });
      } else {
        setState(() {
          _billFeeds = [];
          _loading = false;
          _refreshing = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _refreshing = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text(
                  'Failed to load payment records. Please try again later.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  // Helper method to format date from API string format
  String _formatDateFromString(String dateString) {
    try {
      // API date format is like "2025-04-10T04:13:35.000Z"
      DateTime parsedDate = DateTime.parse(dateString);
      return _monthYearFormat.format(parsedDate);
    } catch (e) {
      // Handle date parsing errors silently
      return "N/A";
    }
  }

  // Process payment data from a feed record
  Map<String, dynamic> _processPaymentData(Feed payment) {
    Map<String, dynamic> paymentDetails = {};

    // Check if we have the paymentData structure
    if (payment.paymentData != null) {
      final paymentData = payment.paymentData;

      // Extract account details
      paymentDetails['account_number'] =
          paymentData['account_number']?.toString() ??
              paymentData['account #']?.toString() ??
              paymentData['account']?.toString() ??
              '';

      paymentDetails['customer_name'] = paymentData['name']?.toString() ??
          paymentData['customer_name']?.toString() ??
          '';

      paymentDetails['address'] = paymentData['address']?.toString() ?? '';
      paymentDetails['district'] = paymentData['district']?.toString() ?? '';

      // Extract payment details
      paymentDetails['transaction_id'] =
          paymentData['transaction_id']?.toString() ??
              paymentData['trans_id']?.toString() ??
              paymentData['transaction']?.toString() ??
              '';

      paymentDetails['payment_date'] =
          paymentData['payment_date']?.toString() ??
              paymentData['date']?.toString() ??
              paymentData['pay_date']?.toString() ??
              '';

      paymentDetails['paid_by'] = paymentData['payment_by']?.toString() ??
          paymentData['paid_by']?.toString() ??
          paymentData['payer']?.toString() ??
          '';

      paymentDetails['amount'] = paymentData['amount']?.toString() ??
          paymentData['amount due']?.toString() ??
          paymentData['payment_amount']?.toString() ??
          '';

      paymentDetails['credit_adj'] = paymentData['credit_adj']?.toString() ??
          paymentData['credit_adj']?.toString() ??
          paymentData['credit_adj']?.toString() ??
          '';

      paymentDetails['reference'] = paymentData['reference']?.toString() ??
          paymentData['ref']?.toString() ??
          paymentData['payment_ref']?.toString() ??
          '';

      // Extract balance from message if available
      if (paymentData['message'] != null) {
        final balanceMatch =
            RegExp(r'Balance on account is\s*([^\n]+)', caseSensitive: false)
                .firstMatch(paymentData['message'].toString());
        if (balanceMatch != null && balanceMatch.groupCount >= 1) {
          paymentDetails['balance'] = balanceMatch.group(1)!.trim();
        }
      }
    }

    // If we couldn't get data from paymentData, try to extract from message
    if ((paymentDetails['account_number']?.isEmpty ?? true) ||
        (paymentDetails['customer_name']?.isEmpty ?? true)) {
      if (payment.message != null && payment.message.toString().isNotEmpty) {
        final message = payment.message.toString();

        // Try to extract account number
        if (paymentDetails['account_number']?.isEmpty ?? true) {
          final accountMatch =
              RegExp(r'(ACCOUNT|ACC) #?:?\s*([^\n\r]+)', caseSensitive: false)
                  .firstMatch(message);
          if (accountMatch != null && accountMatch.groupCount >= 2) {
            paymentDetails['account_number'] = accountMatch.group(2)!.trim();
          } else {
            // Fallback: try to find a pattern that looks like an account number
            final lines = message.split(RegExp(r'\n|\r'));
            for (var line in lines) {
              if (RegExp(r'^\d{4}-\d{4}-\d{4}\s*$').hasMatch(line.trim())) {
                paymentDetails['account_number'] = line.trim();
                break;
              }
            }
          }
        }

        // Try to extract customer name
        if (paymentDetails['customer_name']?.isEmpty ?? true) {
          final nameMatch = RegExp(r'NAME:?\s*([^\n\r]+)', caseSensitive: false)
              .firstMatch(message);
          if (nameMatch != null && nameMatch.groupCount >= 1) {
            paymentDetails['customer_name'] = nameMatch.group(1)!.trim();
          }
        }

        // Try to extract payment amount
        if (paymentDetails['amount']?.isEmpty ?? true) {
          final amountMatch =
              RegExp(r'AMOUNT:?\s*([^\n\r]+)', caseSensitive: false)
                  .firstMatch(message);
          if (amountMatch != null && amountMatch.groupCount >= 1) {
            paymentDetails['amount'] = amountMatch.group(1)!.trim();
          }
        }

        // Try to extract reference
        if (paymentDetails['reference']?.isEmpty ?? true) {
          final refMatch = RegExp(r'Ref:\s*([^\n]+)', caseSensitive: false)
              .firstMatch(message);
          if (refMatch != null && refMatch.groupCount >= 1) {
            paymentDetails['reference'] = refMatch.group(1)!.trim();
          }
        }

        // Try to extract balance
        if (paymentDetails['balance']?.isEmpty ?? true) {
          final balanceMatch =
              RegExp(r'Balance on account is\s*([^\n]+)', caseSensitive: false)
                  .firstMatch(message);
          if (balanceMatch != null && balanceMatch.groupCount >= 1) {
            paymentDetails['balance'] = balanceMatch.group(1)!.trim();
          }
        }
      }
    }

    return paymentDetails;
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
        _buildPaymentsList(),
      ],
    );
  }

  Widget _buildPaymentsList() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Constants.kPrimaryColor),
        ),
      );
    }

    if (_billFeeds.isEmpty && !_loading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: GText(
            textData: "No payment records found",
            textAlign: TextAlign.center,
            textSize: 16.sp,
            textColor: Constants.kGreyColor,
            textMaxLines: 5,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchBillFeeds,
      child: Stack(
        children: [
          _refreshing
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      child: SizedBox(
                        height: 1.h,
                        child: LinearProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Constants.kPrimaryColor),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                )
              : Container(),
          ListView.builder(
            padding: EdgeInsets.all(8.w),
            itemCount: _billFeeds.length,
            itemBuilder: (context, index) {
              return _buildBillingCard(_billFeeds[index], index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBillingCard(Feed payment, int index) {
    // Process payment data
    final paymentData = _processPaymentData(payment);

    // Extract key information for card display
    final accountNumber = paymentData['account_number'] ?? '';

    // Track if card is expanded
    bool isExpanded = _expandedCards[index];

    // Set header gradient colors like in BillingInfo.dart
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
                  // Let the content determine the height
                  constraints: BoxConstraints(),
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
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add icon for payment
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.payment,
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
                                textData: payment.dateCreated != null
                                    ? ' ${_formatDateFromString(payment.dateCreated.toString())}'
                                    : ' N/A',
                                textSize: 14.sp,
                                textFont: Constants.kFontBold,
                                textColor: Colors.white.withValues(alpha: 0.9),
                              ),
                              SizedBox(height: 3.h),
                              GText(
                                textData: () {
                                  String accNum = accountNumber.isNotEmpty
                                      ? accountNumber
                                      : 'N/A';

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
                                // textFont: Constants.kFontBold,r
                                textColor: Colors.white.withValues(alpha: 0.9),
                                textMaxLines: 1,
                                textOverflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Toggle arrow
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

              // Payment details - only show when expanded
              if (isExpanded) _buildPaymentDetails(payment),
            ],
          ),
        ),
      ),
    );
  }

  // Build payment details widget
  Widget _buildPaymentDetails(Feed billing) {
    // Check if we have the paymentData structure
    if (billing.paymentData != null) {
      // Extract data from the paymentData object
      final paymentData = billing.paymentData;

      // Initialize variables for payment details
      String accountNumber = '';
      String customerName = '';
      String transId = '';
      String paymentDate = '';
      String paidBy = '';
      String amount = '';
      String reference = '';
      String balance = '';
      String address = '';
      String district = '';
      String creditAdj = '';

      // Try to extract data using different possible field names
      // Account number - could be 'account_number', 'account #', or 'account'
      accountNumber = paymentData['account_number']?.toString() ??
          paymentData['account #']?.toString() ??
          paymentData['account']?.toString() ??
          '';

      // Customer name
      customerName = paymentData['name']?.toString() ??
          paymentData['customer_name']?.toString() ??
          '';

      // Address and district
      address = paymentData['address']?.toString() ?? '';
      district = paymentData['district']?.toString() ?? '';

      // Transaction ID
      transId = paymentData['transaction_id']?.toString() ??
          paymentData['trans_id']?.toString() ??
          paymentData['transaction']?.toString() ??
          '';

      // Payment date
      paymentDate = paymentData['payment_date']?.toString() ??
          paymentData['date']?.toString() ??
          paymentData['pay_date']?.toString() ??
          '';

      // Paid by
      paidBy = paymentData['payment_by']?.toString() ??
          paymentData['paid_by']?.toString() ??
          paymentData['payer']?.toString() ??
          '';

      // Amount
      amount = paymentData['amount']?.toString() ??
          paymentData['amount due']?.toString() ??
          paymentData['payment_amount']?.toString() ??
          '';

      // Credit adjustment
      creditAdj = paymentData['credit_adj']?.toString() ??
          paymentData['credit_adj']?.toString() ??
          paymentData['credit_adj']?.toString() ??
          '';

      // Reference
      reference = paymentData['reference']?.toString() ??
          paymentData['ref']?.toString() ??
          paymentData['payment_ref']?.toString() ??
          '';

      // If we still don't have account details, try to extract from message
      if ((accountNumber.isEmpty || customerName.isEmpty) &&
          billing.message != null &&
          billing.message.toString().isNotEmpty) {
        final message = billing.message.toString();

        // Try to find account number in the message
        if (accountNumber.isEmpty) {
          final accountMatch =
              RegExp(r'(ACCOUNT|ACC) #?:?\s*([^\n\r]+)', caseSensitive: false)
                  .firstMatch(message);
          if (accountMatch != null && accountMatch.groupCount >= 2) {
            accountNumber = accountMatch.group(2)!.trim();
          } else {
            // Fallback: try to find a pattern that looks like an account number
            final lines = message.split(RegExp(r'\n|\r'));
            for (var line in lines) {
              if (RegExp(r'^\d{4}-\d{4}-\d{4}\s*$').hasMatch(line.trim())) {
                accountNumber = line.trim();
                break;
              }
            }
          }
        }

        // Try to find customer name in the message
        if (customerName.isEmpty) {
          final nameMatch = RegExp(r'NAME:?\s*([^\n\r]+)', caseSensitive: false)
              .firstMatch(message);
          if (nameMatch != null && nameMatch.groupCount >= 1) {
            customerName = nameMatch.group(1)!.trim();
          }
        }
      }

      // Extract balance from message since it might be part of the message in paymentData
      if (paymentData['message'] != null) {
        final balanceMatch =
            RegExp(r'Balance on account is\s*([^\n]+)', caseSensitive: false)
                .firstMatch(paymentData['message'].toString());
        if (balanceMatch != null && balanceMatch.groupCount >= 1) {
          balance = balanceMatch.group(1)!.trim();
        }
      }

      return Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account details
            if (accountNumber.isNotEmpty ||
                customerName.isNotEmpty ||
                address.isNotEmpty ||
                district.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GText(
                      textData: 'Account Details',
                      textSize: 16.sp,
                      textFont: Constants.kFontMedium,
                      textColor: Constants.kPrimaryColor,
                    ),
                    SizedBox(height: 8.h),
                    if (accountNumber.isNotEmpty)
                      _buildPaymentDetailRow('Acc #', accountNumber),
                    if (customerName.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 6.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GText(
                              textData: 'Customer Name',
                              textSize: 14.sp,
                              textColor: Colors.grey[700],
                              textFont: Constants.kFont,
                            ),
                            SizedBox(height: 4.h),
                            GText(
                              textData: customerName,
                              textSize: 14.sp,
                              textFont: Constants.kFont,
                              textColor: Colors.black87,
                              textMaxLines: 2,
                              textOverflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    if (address.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 6.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GText(
                              textData: 'Address',
                              textSize: 14.sp,
                              textColor: Colors.grey[700],
                              textFont: Constants.kFont,
                            ),
                            SizedBox(height: 4.h),
                            GText(
                              textData: address,
                              textSize: 14.sp,
                              textFont: Constants.kFont,
                              textColor: Colors.black87,
                              textMaxLines: 2,
                              textOverflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    if (district.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 6.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GText(
                              textData: 'District',
                              textSize: 14.sp,
                              textColor: Colors.grey[700],
                              textFont: Constants.kFont,
                            ),
                            SizedBox(height: 4.h),
                            GText(
                              textData: district,
                              textSize: 14.sp,
                              textFont: Constants.kFont,
                              textColor: Colors.black87,
                              textMaxLines: 2,
                              textOverflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            if (accountNumber.isNotEmpty || customerName.isNotEmpty)
              SizedBox(height: 16.h),

            // Payment details
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Constants.kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: Constants.kPrimaryColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GText(
                    textData: 'Payment Details',
                    textSize: 16.sp,
                    textFont: Constants.kFontMedium,
                    textColor: Constants.kPrimaryColor,
                  ),
                  SizedBox(height: 8.h),
                  if (transId.isNotEmpty)
                    _buildPaymentDetailRow('Transaction ID', transId),
                  if (paidBy.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: _buildPaymentDetailRow('Paid By', paidBy),
                    ),
                  if (amount.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: _buildPaymentDetailRow('Amount', amount,
                          isBold: true),
                    ),
                  if (creditAdj.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: _buildPaymentDetailRow(
                          'Credit Adjustment', creditAdj,
                          isBold: true),
                    ),
                  if (reference.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: _buildPaymentDetailRow('Reference', reference),
                    ),
                  if (balance.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: _buildPaymentDetailRow('Balance', balance,
                          isBold: true, isHighlighted: true),
                    ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Message card - display the raw message from the feed
            if (billing.message != null &&
                billing.message.toString().isNotEmpty)
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GText(
                      textData: 'Receipt Information',
                      textSize: 16.sp,
                      textFont: Constants.kFontMedium,
                      textColor: Constants.kPrimaryColor,
                    ),
                    SizedBox(height: 8.h),
                    GText(
                      textData: billing.message.toString(),
                      textSize: 14.sp,
                      textFont: Constants.kFont,
                      textColor: Colors.black87,
                      textMaxLines: 15,
                      textOverflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    // Return empty container if no payment data is available
    return Container();
  }

  // Helper method for payment detail rows
  Widget _buildPaymentDetailRow(String label, String value,
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
}
