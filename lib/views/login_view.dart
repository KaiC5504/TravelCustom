import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;
import 'package:travelcustom/constants/routes.dart';
// import 'package:travelcustom/utilities/display_error.dart';

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
          ShowPassword(
            PasswordController: _password,
          ),

          //register button
          ElevatedButton(
            onPressed: () async {
              final email = _email.text;
              final password = _password.text;

              if (email.isEmpty || password.isEmpty) {
                String errorMessage = 'Please fill in all fields';
                // ignore: use_build_context_synchronously
                displayCustomErrorMessage(context, errorMessage);
                return;
              }

              try {
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: email,
                  password: password,
                );
                // ignore: use_build_context_synchronously
                Navigator.of(context).pushNamedAndRemoveUntil(
                  travelRoute,
                  (route) => false,
                );
              } on FirebaseAuthException catch (e) {
                if (e.code == 'invalid-credential') {
                  devtools.log('Invalid credentials');
                  String errorMessage = 'Invalid credentials';
                  // ignore: use_build_context_synchronously
                  displayCustomErrorMessage(context, errorMessage);
                } else {
                  String errorMessage = e.code;
                  // ignore: use_build_context_synchronously
                  displayCustomErrorMessage(context, errorMessage);
                }
              } catch (e) {
                String errorMessage = e.toString();
                devtools.log(e.toString());
                // ignore: use_build_context_synchronously
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

class CustomErrorMessage extends StatelessWidget {
  const CustomErrorMessage({
    super.key,
    required this.errorMessage,
  });

  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      height: 90,
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 210, 127, 121),
        borderRadius: BorderRadius.all(
          Radius.circular(20),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Warning",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              errorMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

void displayCustomErrorMessage(BuildContext context, String errorMessage) {
  showModalBottomSheet(
    context: context,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
        },
        child: Container(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {},
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
                child: CustomErrorMessage(errorMessage: errorMessage),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class ShowPassword extends StatefulWidget {
  // ignore: non_constant_identifier_names
  final TextEditingController PasswordController;

  // ignore: non_constant_identifier_names
  const ShowPassword({super.key, required this.PasswordController});

  @override
  // ignore: library_private_types_in_public_api
  _ShowPasswordState createState() => _ShowPasswordState();
}

class _ShowPasswordState extends State<ShowPassword> {
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
