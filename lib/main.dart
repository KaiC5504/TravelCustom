import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:travelcustom/constants/routes.dart';
import 'package:travelcustom/firebase_options.dart';
import 'package:travelcustom/utilities/navigation_bar.dart';
import 'package:travelcustom/views/favourite_view.dart';
import 'package:travelcustom/views/login_view.dart';
import 'package:travelcustom/views/profile_edit.dart';
import 'package:travelcustom/views/profile_view.dart';
import 'package:travelcustom/views/register_view.dart';
import 'package:travelcustom/views/search_view.dart';
import 'package:travelcustom/views/travel_main.dart';
import 'package:travelcustom/views/travel_plan_view.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( 
      title: 'TravelCustom',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 136, 101, 197)),
        useMaterial3: true,
      ),
      home: const CustomBottomNavigationBar(),
      initialRoute: '/home',
      defaultTransition: Transition.fadeIn,
      getPages: [
        GetPage(
          name: '/home',
          page: () => const HomePage(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/navi',
          page: () => const CustomBottomNavigationBar(),
          binding: BindingsBuilder(() {
            final args = Get.arguments as Map<String, dynamic>?;
            Get.put(NavigationController(
              initialIndex: args?['initialIndex'] ?? 0,
              showAddDayDialog: args?['showAddDayDialog'] ?? false,
              initialSideNote: args?['initialSideNote'],
            ), permanent: true);
          }),
          transition: Transition.fadeIn,
        ),
        GetPage(name: registerRoute, page: () => const RegisterView()),
        GetPage(name: loginRoute, page: () => const LoginView()),
        GetPage(name: travelRoute, page: () => const TravelView()),
        GetPage(name: searchRoute, page: () => const SearchPage()),
        GetPage(name: profileRoute, page: () => const ProfilePage()),
        GetPage(name: naviRoute, page: () => const CustomBottomNavigationBar()),
        GetPage(name: planRoute, page: () => const TravelPlanView()),
        GetPage(name: favouriteRoute, page: () => const FavouritePage()),
        GetPage(name: editRoute, page: () => const ProfileEditPage()),
      ],
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              return const TravelView();
            } else {
              return const LoginView();
            }
          default:
            return const CircularProgressIndicator();
        }
      },
    );
  }
}
