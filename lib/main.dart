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
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  Get.config(
    enableLog: false,
    defaultTransition: Transition.noTransition,
    defaultPopGesture: false,
  );

  Get.put(
      NavigationController(
        initialIndex: 0,
        showAddDayDialog: false,
        initialSideNote: null,
      ),
      permanent: true);

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
      initialRoute: '/home',
      defaultTransition: Transition.noTransition,
      getPages: [
        GetPage(
          name: '/home',
          page: () => const CustomBottomNavigationBar(),
          transition: Transition.noTransition,
        ),
        GetPage(
          name: naviRoute,
          page: () => const CustomBottomNavigationBar(),
          transition: Transition.noTransition,
          middlewares: [
            NavigationMiddleware(),
          ],
        ),
        GetPage(
          name: registerRoute,
          page: () => const RegisterView(),
          preventDuplicates: true,
          transition: Transition.noTransition,
        ),
        GetPage(
          name: loginRoute,
          page: () => const LoginView(),
          preventDuplicates: true,
          transition: Transition.noTransition,
        ),
        GetPage(
          name: travelRoute,
          page: () => const TravelView(),
          preventDuplicates: true,
          transition: Transition.noTransition,
        ),
        GetPage(
          name: searchRoute,
          page: () => const SearchPage(),
          preventDuplicates: true,
          transition: Transition.noTransition,
        ),
        GetPage(
          name: profileRoute,
          page: () => const ProfilePage(),
          preventDuplicates: true,
          transition: Transition.noTransition,
        ),
        GetPage(
          name: favouriteRoute,
          page: () => const FavouritePage(),
          preventDuplicates: true,
          transition: Transition.noTransition,
        ),
        GetPage(
          name: editRoute,
          page: () => const ProfileEditPage(),
          preventDuplicates: true,
          transition: Transition.noTransition,
        ),
      ],
    );
  }
}

class NavigationMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (route == '/home' && Get.arguments != null) {
      return RouteSettings(
        name: route,
        arguments: Get.arguments,
      );
    }
    return null;
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomBottomNavigationBar();
  }
}
