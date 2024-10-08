// ignore_for_file: use_build_context_synchronously

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
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 162, 136, 222),
      ),
      body: Column(
        children: [
          // Add an image
          Center(
            child: Container(
              width: 150,
              height: 150,
              margin: const EdgeInsets.only(top: 20, bottom: 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/images/login_image.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          //username textfield
          Center(
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(15),
              child: TextField(
                controller: _email,
                enableSuggestions: false,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
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
              final email = _email.text;
              final password = _password.text;

              if (email.isEmpty || password.isEmpty) {
                String errorMessage = 'Please fill in all fields';
                displayCustomErrorMessage(context, errorMessage);
                devtools.log('Empty fields');
                return;
              }

              try {
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: email,
                  password: password,
                );
                Navigator.of(context).pushNamedAndRemoveUntil(
                  travelRoute,
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
