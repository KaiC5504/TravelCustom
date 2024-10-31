// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;
import 'package:travelcustom/constants/routes.dart';
import 'package:travelcustom/utilities/display_error.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _usernameOrEmail;
  late final TextEditingController _password;

  @override
  void initState() {
    _usernameOrEmail = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _usernameOrEmail.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<String?> _getEmailFromUsername(String username) async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first['email'] as String;
      } else {
        return null;
      }
    } catch (e) {
      devtools.log('Error fetching email for username: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 162, 136, 222),
        scrolledUnderElevation: 0,
      ),
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Center(
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('Login',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            ),
          ),
          //username textfield
          Center(
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(15),
              child: TextField(
                controller: _usernameOrEmail,
                enableSuggestions: false,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Username or Email',
                    border: OutlineInputBorder()),
              ),
            ),
          ),

          //password textfield with show/hide password
          PasswordInput(
            PasswordController: _password,
          ),

          //register button
          ElevatedButton(
            onPressed: () async {
              final usernameOrEmail = _usernameOrEmail.text;
              final password = _password.text;

              if (usernameOrEmail.isEmpty || password.isEmpty) {
                String errorMessage = 'Please fill in all fields';
                displayCustomErrorMessage(context, errorMessage);
                devtools.log('Empty fields');
                return;
              }

              String? email = usernameOrEmail;

              if (!usernameOrEmail.contains('@') &&
                  !usernameOrEmail.contains('.')) {
                email = await _getEmailFromUsername(usernameOrEmail);
                if (email == null) {
                  String errorMessage = 'Username not found';
                  displayCustomErrorMessage(context, errorMessage);
                  devtools.log('Username not found');
                  return;
                }
              }

              try {
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: email,
                  password: password,
                );
                Navigator.of(context).pushNamedAndRemoveUntil(
                  naviRoute,
                  (route) => false,
                );
              } on FirebaseAuthException catch (e) {
                if (e.code == 'invalid-credential') {
                  devtools.log('Invalid credentials');
                  String errorMessage = 'Invalid Email or Password';
                  displayCustomErrorMessage(context, errorMessage);
                } else if (e.code == 'invalid-email') {
                  String errorMessage = 'Invalid email format';
                  displayCustomErrorMessage(context, errorMessage);
                } else {
                  String errorMessage = e.toString();
                  devtools.log(e.toString());
                  displayCustomErrorMessage(context, errorMessage);
                }
              } catch (e) {
                String errorMessage = e.toString();
                devtools.log(e.toString());
                displayCustomErrorMessage(context, errorMessage);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 162, 136, 222),
              foregroundColor: Colors.white,
              elevation: 7,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text('Login', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                registerRoute,
                (route) => false,
              );
            },
            child: const Text("Don't have an account? Register"),
          ),
        ],
      ),
    );
  }
}

class PasswordInput extends StatefulWidget {
  // ignore: non_constant_identifier_names
  final TextEditingController PasswordController;

  // ignore: non_constant_identifier_names
  const PasswordInput({super.key, required this.PasswordController});

  @override
  // ignore: library_private_types_in_public_api
  _PasswordInputState createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(15),
        child: TextField(
          controller: widget.PasswordController,
          obscureText: _isObscured,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'Password',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                }),
          ),
        ),
      ),
    );
  }
}
