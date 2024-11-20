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
import 'package:travelcustom/views/try_main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TravelCustom',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 136, 101, 197)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      routes: {
        registerRoute: (context) => const RegisterView(),
        loginRoute: (context) => const LoginView(),
        travelRoute: (context) => const TravelView(),
        searchRoute: (context) => const SearchPage(),
        profileRoute: (context) => const ProfilePage(),
        naviRoute: (context) => const CustomBottomNavigationBar(),
        planRoute: (context) => const TravelPlanView(),
        favouriteRoute: (context) => const FavouritePage(),
        editRoute: (context) => const ProfileEditPage(),
      },
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
