import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:travelcustom/constants/routes.dart';
import 'package:travelcustom/views/login_view.dart';
import 'package:travelcustom/views/planning.dart';
import 'package:travelcustom/views/platform_page.dart';
import 'package:travelcustom/views/profile_view.dart';
import 'package:travelcustom/views/travel_main.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Get.find instead of Get.put to use existing controller
    final controller = Get.find<NavigationController>();

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
                  onPressed: () => controller.changeTab(0),
                ),
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.earthAsia,
                      color: controller.selectedIndex.value == 1
                          ? Colors.white
                          : Colors.grey),
                  onPressed: () => controller.changeTab(1),
                ),
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.map,
                      color: controller.selectedIndex.value == 2
                          ? Colors.white
                          : Colors.grey),
                  onPressed: () => controller.changeTab(2),
                ),
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.user,
                      color: controller.selectedIndex.value == 3
                          ? Colors.white
                          : Colors.grey),
                  onPressed: () => controller.changeTab(3),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Obx(
        () => IndexedStack(
          index: controller.selectedIndex.value,
          children: controller.screens,
        ),
      ),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex;
  final bool showAddDayDialog;
  final String? initialSideNote;

  NavigationController({
    int initialIndex = 0,
    this.showAddDayDialog = false,
    this.initialSideNote,
  }) : selectedIndex = initialIndex.obs;

  late final List<Widget> screens;

  @override
  void onInit() {
    super.onInit();

    // Add listener for route arguments
    ever(selectedIndex, (index) {
      if (Get.arguments != null) {
        bool showDialog = Get.arguments['showAddDayDialog'] ?? false;
        String? sideNote = Get.arguments['initialSideNote'];
        if (showDialog) {
          screens[2] = PlanningView(
            showAddDayDialog: true,
            initialSideNote: sideNote,
          );
          // Clear the arguments by navigating without arguments
          Get.offAllNamed('/home');
          // Reset the screen after a short delay
          Future.delayed(const Duration(milliseconds: 100), () {
            screens[2] = PlanningView(
              showAddDayDialog: false,
              initialSideNote: null,
            );
          });
        }
      }
    });

    screens = [
      const TravelView(),
      FirebaseAuth.instance.currentUser != null
          ? const PlatformPage()
          : const LoginView(),
      FirebaseAuth.instance.currentUser != null
          ? PlanningView(
              showAddDayDialog: showAddDayDialog,
              initialSideNote: initialSideNote,
            )
          : const LoginView(),
      FirebaseAuth.instance.currentUser != null
          ? const ProfilePage()
          : const LoginView(),
    ];
  }

  void changeTab(int index) {
    if (index == selectedIndex.value) return; // Don't navigate if already on the tab
    
    selectedIndex.value = index;
    // Only handle navigation for non-plan routes
    if (!Get.currentRoute.startsWith(planRoute)) {
      Get.until((route) => route.isFirst);
    }
  }

  // Add this method for handling plan navigation
  void navigateToPlan({bool showDialog = false, String? sideNote}) {
    selectedIndex.value = 2; // Plan tab index
    if (showDialog) {
      // Store the arguments temporarily
      Map<String, dynamic> args = {
        'showAddDayDialog': true,
        'initialSideNote': sideNote,
      };
      Get.offAllNamed('/home', arguments: args);
      
      // Reset the screen after navigation
      Future.delayed(const Duration(milliseconds: 100), () {
        screens[2] = PlanningView(
          showAddDayDialog: false,
          initialSideNote: null,
        );
      });
    }

    // Update the planning view with new arguments
    screens[2] = PlanningView(
      showAddDayDialog: showDialog,
      initialSideNote: sideNote,
    );
  }
}
