import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:travelcustom/views/profile_view.dart';
import 'package:travelcustom/views/travel_main.dart';
import 'package:travelcustom/views/travel_plan_view.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());

    return Scaffold(
      bottomNavigationBar: Obx(
        () => NavigationBar(
          height: 80,
          elevation: 0,
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected: (index) =>
              controller.selectedIndex.value = index,
          destinations: const [
            NavigationDestination(
                icon: FaIcon(FontAwesomeIcons.house), label: 'Home'),
            NavigationDestination(
                icon: FaIcon(FontAwesomeIcons.suitcaseRolling), label: 'Plan'),
            NavigationDestination(
                icon: FaIcon(FontAwesomeIcons.house), label: 'Home'),
            NavigationDestination(
                icon: FaIcon(FontAwesomeIcons.user), label: 'Profile'),
          ],
        ),
      ),
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  final screens = [
    const TravelView(),
    const TravelPlanView(),
    Container(
      color: Colors.white,
    ),
    const ProfilePage(),
  ];
}
