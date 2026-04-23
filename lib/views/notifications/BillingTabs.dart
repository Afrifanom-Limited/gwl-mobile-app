import 'package:flutter/material.dart';
import 'package:gwcl/helpers/Constants.dart';
  import 'package:gwcl/views/notifications/BillingInfo.dart';
  import 'package:gwcl/views/notifications/Payments.dart';

class BillingTabs extends StatefulWidget {
  const BillingTabs({Key? key}) : super(key: key);

  @override
  _BillingTabsState createState() => _BillingTabsState();
}

class _BillingTabsState extends State<BillingTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Constants.kWhiteColor,
          // color: Constants.kPrimaryColor,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Constants.kPrimaryColor,
            // indicatorColor: Colors.white,
            labelColor: Constants.kPrimaryColor,
            // labelColor: Colors.white,
            unselectedLabelColor: Constants.kGreyColor,
            tabs: const [
              Tab(text: 'Billing'),
              Tab(text: 'Payments'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              BillingInfo(openFirstBill: true),
              Payments(
                openFirstBill: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
