// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;
import 'package:travelcustom/utilities/display_error.dart';
import 'package:travelcustom/constants/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
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
        title: const Text('Register', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 162, 136, 222),
      ),
      body: Column(
        children: [
          Center(
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('Register',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
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
                final userCredential = await FirebaseAuth.instance
                    .createUserWithEmailAndPassword(
                        email: email, password: password);
                devtools.log(userCredential.toString());
                Navigator.of(context).pushNamedAndRemoveUntil(
                  loginRoute,
                  (route) => false,
                );

                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .set(
                    {
                      'email': email,
                      'password': password,
                      'name': '',
                      'planId': '',
                      'favourites': [],
                    },
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (e.code == 'weak-password') {
                  devtools.log('Weak Password');
                  String errorMessage =
                      'Password need to be at least 6 characters';
                  displayCustomErrorMessage(context, errorMessage);
                } else if (e.code == 'email-already-in-use') {
                  String errorMessage = 'Email already registered';
                  devtools.log('Email Registered');
                  displayCustomErrorMessage(context, errorMessage);
                } else if (e.code == 'invalid-email') {
                  devtools.log('Invalid Email');
                  String errorMessage = 'Invalid email format';
                  displayCustomErrorMessage(context, errorMessage);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 162, 136, 222),
              foregroundColor: Colors.white,
              elevation: 7,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child:
                const Text('Register', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                loginRoute,
                (route) => false,
              );
            },
            child: const Text('Already registered? Login'),
          )
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
