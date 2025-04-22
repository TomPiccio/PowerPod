import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:power_pod/widgets/logo_header.dart';
import '../services/auth_Service.dart';
import 'package:oktoast/oktoast.dart';

class verification extends StatefulWidget {
  @override
  verificationState createState() => verificationState();
}

class verificationState extends State<verification> {
  User? user;
  bool emailSent = false;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;

    if (user != null && !user!.emailVerified && !emailSent) {
      user!.sendEmailVerification();
      emailSent = true;
      showToast(
        'Verification email sent. Please check your inbox.',
        backgroundColor: Colors.green,
        position: ToastPosition.bottom,
        radius: 8.0,
        textStyle: TextStyle(color: Colors.white),
      );
    }
  }

  void resendVerificationEmail() async {
    if (user != null && !user!.emailVerified) {
      await user!.sendEmailVerification();
      showToast(
        'Verification email re-sent!',
        backgroundColor: Colors.blue,
        position: ToastPosition.bottom,
        radius: 8.0,
        textStyle: TextStyle(color: Colors.white),
      );
    }
  }

  void checkVerificationStatus() async {
    await user?.reload();
    user = FirebaseAuth.instance.currentUser;

    if (user!.emailVerified) {
      showToast(
        'Email verified! 🎉',
        backgroundColor: Colors.green,
        position: ToastPosition.bottom,
        radius: 8.0,
        textStyle: TextStyle(color: Colors.white),
      );

      // You can navigate to the main app or dashboard here
      // Navigator.pushReplacementNamed(context, '/home');
    } else {
      showToast(
        'Still not verified. Check your inbox or spam folder.',
        backgroundColor: Colors.orange,
        position: ToastPosition.bottom,
        radius: 8.0,
        textStyle: TextStyle(color: Colors.white),
      );
    }
  }

  void _checkAndSendEmailVerification() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      showToast(
        'Verification email sent to ${user.email}. Please check your inbox.',
        position: ToastPosition.bottom,
        backgroundColor: Colors.orange,
        textStyle: TextStyle(color: Colors.white),
      );
    } else if (user != null && user.emailVerified) {
      showToast(
        'Your email is already verified!',
        position: ToastPosition.bottom,
        backgroundColor: Colors.green,
        textStyle: TextStyle(color: Colors.white),
      );
    } else {
      showToast(
        'No user logged in.',
        position: ToastPosition.bottom,
        backgroundColor: Colors.red,
        textStyle: TextStyle(color: Colors.white),
      );
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
              width: 320,
              height: 800,
              decoration: BoxDecoration(
                color: Color.fromRGBO(255, 255, 255, 1),
              ),
              child: SingleChildScrollView(
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 320,
                        height: 650,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FEFB),
                        ),
                        child: Stack(
                          children: [
                            LogoHeader(),
                            Center(
                              child: Column(
                                children: [
                                  SizedBox(height: 250),
                                  Text(
                                    "Please verify your email",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  SizedBox(height: 10),

                                  // Resend Verification Button
                                  SizedBox(
                                    width: 329,
                                    height: 50,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: resendVerificationEmail,
                                        borderRadius: BorderRadius.circular(8),
                                        splashColor: Colors.white24,
                                        child: Ink(
                                          padding: const EdgeInsets.all(12),
                                          decoration: ShapeDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: [
                                                Color(0xFF34D09B),
                                                Color(0xFF3A83F4),
                                              ],
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              side: BorderSide(
                                                color: Color(0xFF34D09B),
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "Resend Verification Email",
                                              style: TextStyle(
                                                color: Color(0xFFF5F5F5),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 10),

                                  // I Have Verified Button
                                  SizedBox(
                                    width: 329,
                                    height: 50,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: checkVerificationStatus,
                                        borderRadius: BorderRadius.circular(8),
                                        splashColor: Colors.white24,
                                        child: Ink(
                                          padding: const EdgeInsets.all(12),
                                          decoration: ShapeDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: [
                                                Color(0xFF34D09B),
                                                Color(0xFF3A83F4),
                                              ],
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              side: BorderSide(
                                                color: Color(0xFF34D09B),
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "I Have Verified",
                                              style: TextStyle(
                                                color: Color(0xFFF5F5F5),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
