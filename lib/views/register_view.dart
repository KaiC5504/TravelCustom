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
  late final TextEditingController _agencyCode;
  String _selectedRole = 'Traveller';

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    _agencyCode = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _agencyCode.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    final email = _email.text;
    final password = _password.text;
    final agencyCode = _agencyCode.text;

    if (email.isEmpty ||
        password.isEmpty ||
        (_selectedRole == 'Travel Agency' && agencyCode.isEmpty)) {
      String errorMessage = 'Please fill in all fields';
      displayCustomErrorMessage(context, errorMessage);
      devtools.log('Empty fields');
      return;
    }

    if (_selectedRole == 'Travel Agency' && agencyCode != '1212') {
      String errorMessage = 'Invalid agency code';
      displayCustomErrorMessage(context, errorMessage);
      devtools.log('Invalid agency code');
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      devtools.log(userCredential.toString());

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String planId = await _createTravelPlan(user.uid);

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': email,
          'password': password,
          'name': '',
          'planId': planId,
          'favourites': [],
          'role': _selectedRole, // Store role with proper capitalization
          'agencyCode': _selectedRole == 'Travel Agency' ? agencyCode : null,
        });

        Navigator.of(context).pushNamedAndRemoveUntil(
          loginRoute,
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        devtools.log('Weak Password');
        String errorMessage = 'Password needs to be at least 6 characters';
        displayCustomErrorMessage(context, errorMessage);
      } else if (e.code == 'email-already-in-use') {
        devtools.log('Email Registered');
        String errorMessage = 'Email already registered';
        displayCustomErrorMessage(context, errorMessage);
      } else if (e.code == 'invalid-email') {
        devtools.log('Invalid Email');
        String errorMessage = 'Invalid email format';
        displayCustomErrorMessage(context, errorMessage);
      }
    } catch (e) {
      devtools.log('Error during registration: $e');
    }
  }

  Future<String> _createTravelPlan(String userId) async {
    try {
      DocumentReference newPlanRef =
          await FirebaseFirestore.instance.collection('travel_plans').add({
        'days': [],
        'end': Timestamp.now(),
        'plan_name': '',
        'start': Timestamp.now(),
        'userId': userId,
      });
      devtools.log('New travel plan created with ID: ${newPlanRef.id}');
      return newPlanRef.id;
    } catch (e) {
      devtools.log('Error creating travel plan: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 162, 136, 222),
        scrolledUnderElevation: 0,
      ),
      backgroundColor: Colors.grey[200],
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

          Center(
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(15),
              child: DropdownButtonFormField<String>(
                value: _selectedRole,
                items: ['Traveller', 'Travel Agency']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(
                            role,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Register as',
                  labelStyle: const TextStyle(fontSize: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor:
                      Colors.grey[200], // Match email and password background
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  constraints: BoxConstraints.tight(const Size.fromHeight(60)),
                ),
                style: const TextStyle(color: Colors.black, fontSize: 18),
                dropdownColor: Colors.white,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                isExpanded: true,
                menuMaxHeight: 300, // Ensure the dropdown menu appears lower
              ),
            ),
          ),
          if (_selectedRole == 'Travel Agency')
            Center(
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(15),
                child: TextField(
                  controller: _agencyCode,
                  decoration: InputDecoration(
                    labelText: 'Agency Code',
                    labelStyle: const TextStyle(fontSize: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor:
                        Colors.grey[200], // Match email and password background
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 10),
                    constraints:
                        BoxConstraints.tight(const Size.fromHeight(60)),
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),

          //register button
          ElevatedButton(
            onPressed: _registerUser,
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
