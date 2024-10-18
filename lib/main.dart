import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:travelcustom/constants/routes.dart';
import 'package:travelcustom/firebase_options.dart';
import 'package:travelcustom/utilities/navigation_bar.dart';
import 'package:travelcustom/views/favourite_view.dart';
import 'package:travelcustom/views/login_view.dart';
import 'package:travelcustom/views/profile_view.dart';
import 'package:travelcustom/views/register_view.dart';
import 'package:travelcustom/views/search_view.dart';
import 'package:travelcustom/views/travel_main.dart';
import 'package:travelcustom/views/travel_plan_view.dart';

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
      home: const CustomBottomNavigationBar(),
      routes: {
        registerRoute: (context) => const RegisterView(),
        loginRoute: (context) => const LoginView(),
        travelRoute: (context) => const TravelView(),
        searchRoute: (context) => const SearchPage(),
        profileRoute: (context) => const ProfilePage(),
        naviRoute: (context) => const CustomBottomNavigationBar(),
        planRoute: (context) => const TravelPlanView(),
        favouriteRoute: (context) => const FavouritePage(),
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





// enum MenuAction { logout }

// class TravelView extends StatefulWidget {
//   const TravelView({super.key});

//   @override
//   State<TravelView> createState() => _TravelViewState();
// }

// class _TravelViewState extends State<TravelView> {
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('TravelCustom',
//             style: TextStyle(color: Colors.black, fontSize: 30)),
//         backgroundColor: const Color.fromARGB(255, 182, 204, 216),
//         actions: [
//           PopupMenuButton<MenuAction>(
//             onSelected: (value) async {
//               switch (value) {
//                 case MenuAction.logout:
//                   final userLogout = await showLogOutDialog(context);
//                   if (userLogout) {
//                     await FirebaseAuth.instance.signOut();
//                     // ignore: use_build_context_synchronously
//                     Navigator.of(context).pushNamedAndRemoveUntil(
//                       loginRoute,
//                       (_) => false,
//                     );
//                   }
//                   break;
//               }
//             },
//             itemBuilder: (context) {
//               return const [
//                 PopupMenuItem<MenuAction>(
//                   value: MenuAction.logout,
//                   child: Center(
//                     child: Text(
//                       'Logout',
//                       style: TextStyle(
//                           color: Color.fromARGB(255, 12, 9, 9),
//                           fontSize: 15,
//                           fontFamily: 'Roboto'),
//                     ),
//                   ),
//                 ),
//               ];
//             },
//             color: Color(0xFFD4EAF7),
//             position: PopupMenuPosition.under,
//             offset: const Offset(0, 6),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//           )
//         ],
//       ),
//       body: const Text('TravelCustom'),
//     );
//   }
// }

// Future<bool> showLogOutDialog(BuildContext context) {
//   return showDialog<bool>(
//     context: context,
//     builder: (context) {
//       return AlertDialog(
//         title: const Text('Log out'),
//         content: const Text('Are you sure you want to log out?'),
//         actions: [
//           TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(false);
//               },
//               child: const Text('Cancel')),
//           TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(true);
//               },
//               child: const Text('Log out')),
//         ],
//       );
//     },
//   ).then((value) => value ?? false);
// }
