import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_Service.dart';
import '../pages/signup.dart';
import '../pages/rent.dart';

class LoginWidget extends StatefulWidget {
  @override
  _LoginWidgetState createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? _errorMessage;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = null; // Clear general errors
      });

      try {
        await AuthService.signin(
          email: emailController.text,
          password: passwordController.text,
          context: context,
        );
      } catch (e) {
        // Catch and show error from the service
        setState(() {
          _errorMessage = "Login failed: ${e.toString()}";
        });
      }
    } else {
      setState(() {
        _errorMessage = "Incorrect email or password.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Optional: Set background color
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Container(
              width: 360,
              height: 800,
              decoration: BoxDecoration(
                color: Color.fromRGBO(255, 255, 255, 1),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Shrinks to content size
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Centers vertically
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // Centers horizontally
                  children: <Widget>[
                    SizedBox(
                      width: 272,
                      height: 150,
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min, // Shrinks to content size
                        mainAxisAlignment:
                            MainAxisAlignment.center, // Centers vertically
                        crossAxisAlignment:
                            CrossAxisAlignment.center, // Centers horizontally
                        children: <Widget>[
                          Container(
                            width: 95,
                            height: 74,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/images/Powerpod.png'),
                                fit: BoxFit.fitWidth,
                              ),
                            ),
                          ),
                          SizedBox(height: 8), // Spacing between text & image
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [Colors.green, Colors.blue],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ).createShader(
                                  Rect.fromLTWH(
                                    0,
                                    0,
                                    bounds.width,
                                    bounds.height,
                                  ),
                                );
                              },
                              child: Text(
                                'Power Pod',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 30,
                                  fontWeight: FontWeight.normal,
                                  height: 1.5,
                                  decoration: TextDecoration.none,
                                  color:
                                      Colors
                                          .white, // Required for ShaderMask to work
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    FittedBox(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          color: Color.fromRGBO(255, 255, 255, 1),
                          border: Border.all(
                            color: Color.fromRGBO(217, 217, 217, 1),
                            width: 1,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,

                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    SizedBox(
                                      width: 300,
                                      child: TextFormField(
                                        controller: emailController,
                                        decoration: InputDecoration(
                                          hintText: 'Email Address',
                                          border: OutlineInputBorder(),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Email is required';
                                          }
                                          final emailRegex = RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                          );
                                          if (!emailRegex.hasMatch(value)) {
                                            return 'Enter a valid email address';
                                          }
                                          return null; // All good!
                                        },
                                      ),
                                    ),

                                    SizedBox(height: 16),

                                    SizedBox(
                                      width: 300,
                                      child: TextFormField(
                                        controller:
                                            passwordController, // Change this to the password controller
                                        obscureText: true,
                                        decoration: InputDecoration(
                                          hintText:
                                              'Password', // Update the hint text
                                          border: OutlineInputBorder(),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Password'; // Update validation message
                                          }
                                          return null;
                                        },
                                      ),
                                    ),

                                    SizedBox(height: 16),
                                    Center(
                                      child: Container(
                                        width:
                                            300, // makes the container fill horizontal space
                                        alignment:
                                            Alignment
                                                .center, // centers the button inside the full-width container
                                        child: GestureDetector(
                                          onTap: _submitForm,
                                          child: Container(
                                            width: 300,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              gradient: LinearGradient(
                                                begin: Alignment(1, 0),
                                                end: Alignment(0, 1),
                                                colors: [
                                                  Color.fromRGBO(
                                                    52,
                                                    208,
                                                    155,
                                                    1,
                                                  ),
                                                  Color.fromRGBO(
                                                    58,
                                                    131,
                                                    244,
                                                    1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                            child: Text(
                                              'LOGIN',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Color.fromRGBO(
                                                  245,
                                                  245,
                                                  245,
                                                  1,
                                                ),
                                                fontFamily: 'Inter',
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            _errorMessage != null
                                ? Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red),
                                )
                                : SizedBox.shrink(),

                            Container(
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(255, 255, 255, 1),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,

                                children: <Widget>[
                                  Text(
                                    'Don’t Have an account?',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Color.fromRGBO(30, 30, 30, 1),
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      letterSpacing:
                                          0 /*percentages not used in flutter. defaulting to zero*/,
                                      fontWeight: FontWeight.normal,
                                      height: 1.5 /*PERCENT not supported*/,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Container(
                                    decoration: BoxDecoration(),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 0,
                                      vertical: 0,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,

                                      children: <Widget>[
                                        InkWell(
                                          onTap: () {
                                            // Navigate to SignupWidget
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => SignupWidget(),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'Sign Up',
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                              color: Color.fromRGBO(
                                                0,
                                                153,
                                                81,
                                                1,
                                              ),
                                              fontFamily: 'Inter',
                                              fontSize: 16,
                                              letterSpacing: 0,
                                              fontWeight: FontWeight.normal,
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),
                            Container(
                              decoration: BoxDecoration(),
                              padding: EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,

                                children: <Widget>[
                                  Text(
                                    'Forgot password?',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color.fromRGBO(0, 153, 81, 1),
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      letterSpacing:
                                          0 /*percentages not used in flutter. defaulting to zero*/,
                                      fontWeight: FontWeight.normal,
                                      height: 1.5 /*PERCENT not supported*/,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
