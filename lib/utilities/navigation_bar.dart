import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:travelcustom/views/platform_page.dart';
import 'package:travelcustom/views/profile_view.dart';
import 'package:travelcustom/views/travel_main.dart';
import 'package:travelcustom/views/travel_plan_view.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());

    return Scaffold(
      backgroundColor: Colors.grey[200],
      bottomNavigationBar: Obx(
        () => Padding(
          padding: const EdgeInsets.only(
              bottom: 20.0,
              left: 20.0,
              right: 20.0), // Add padding for floating effect
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color:
                  const Color.fromARGB(255, 56, 56, 56), // Set background color
              borderRadius: BorderRadius.circular(30), // Rounded corners
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3), // Shadow color
                  spreadRadius: 5,
                  blurRadius: 15,
                  offset: Offset(0, 5), // Shadow position
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.house,
                      color: controller.selectedIndex.value == 0
                          ? Colors.white
                          : Colors.grey),
                  onPressed: () => controller.selectedIndex.value = 0,
                ),
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.map,
                      color: controller.selectedIndex.value == 1
                          ? Colors.white
                          : Colors.grey),
                  onPressed: () => controller.selectedIndex.value = 1,
                ),
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.file,
                      color: controller.selectedIndex.value == 2
                          ? Colors.white
                          : Colors.grey),
                  onPressed: () => controller.selectedIndex.value = 2,
                ),
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.user,
                      color: controller.selectedIndex.value == 3
                          ? Colors.white
                          : Colors.grey),
                  onPressed: () => controller.selectedIndex.value = 3,
                ),
              ],
            ),
          ),
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
    const PlatformPage(),
    const ProfilePage(),
  ];
}
