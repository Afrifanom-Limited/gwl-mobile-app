import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/views/meter/AddMeter.dart';
import 'package:gwcl/views/vendor/AddVendor.dart';

import '../../templates/AppHeaders.dart';

class AddAccount extends StatefulWidget {
  static const String id = "/add_account";
  const AddAccount({super.key});

  @override
  State<AddAccount> createState() => _AddAccountState();
}

class _AddAccountState extends State<AddAccount> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.h),
        child: Container(
          color: Constants.kPrimaryColor,
          child: GeneralHeader(title: "Add Account"),
        ),
      ),
      body: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70.h),
          child: Container(
            color: Constants.kWhiteColor,
            height: 40.h,
            margin: EdgeInsets.all(7.h),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              dividerColor: Constants.kPrimaryColor,
              splashBorderRadius: BorderRadius.circular(10.w),
              labelStyle: TextStyle(fontFamily: Constants.kFont, fontSize: 15.sp),
              unselectedLabelStyle: TextStyle(fontFamily: Constants.kFont, fontSize: 15.sp),
              labelColor: Constants.kPrimaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.label,
              dividerHeight: 0,
              tabs: [
                Tab(text: "Customer Account"),
                Tab(text: "Vendor Account"),
              ],
            ),
          ),
        ),
        body: Container(
          child: TabBarView(
            controller: _tabController,
            children: [AddMeter(), AddVendor()],
          ),
        ),
      ),
    );
  }
}
