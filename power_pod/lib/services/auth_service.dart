import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:power_pod/pages/verification.dart';
import '../pages/login.dart';
import '../pages/home.dart';

class AuthService {
  static Future<void> signup({
    required String email,
    required String password,
    required String name,
    required String contact,
    required BuildContext context,
  }) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'email': email,
            'name': name,
            'contact': contact,
            'createdAt': FieldValue.serverTimestamp(),
          });
      // 🔔 Send email verification
      if (credential.user != null && !credential.user!.emailVerified) {
        await credential.user!.sendEmailVerification();

        showToast(
          'Verification email sent! Please check your inbox.',
          position: ToastPosition.bottom,
          backgroundColor: Colors.green,
          radius: 8,
          textStyle: TextStyle(color: Colors.white),
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => verification()),
      );

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (BuildContext context) => const Home()),
      );
    } on FirebaseAuthException catch (e) {
      String message = '';
      switch (e.code) {
        case 'email-already-in-use':
          message = "This email is already registered.";
        case 'weak-password':
          message = "The password is too weak.";
        case 'invalid-email':
          message = "The email address is invalid.";
        default:
          message = "Signup failed: ${e.message}";
      }
      showToast(
        message,
        duration: Duration(seconds: 3),
        position: ToastPosition.bottom,
        backgroundColor: Colors.black54,
        textStyle: TextStyle(color: Colors.white),
      );
    } catch (e) {
      showToast("Something went wrong");
    }
  }

  static Future<void> signin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (BuildContext context) => const Home()),
      );
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'invalid-email') {
        message = 'No user found for that email.';
      } else if (e.code == 'invalid-credential') {
        message = 'Wrong password provided for that user.';
      }
      showToast(
        message,
        duration: Duration(seconds: 3),
        position: ToastPosition.bottom,
        backgroundColor: Colors.black54,
        textStyle: TextStyle(color: Colors.white),
      );
    } catch (e) {}
  }

  static Future<void> signout({required BuildContext context}) async {
    await FirebaseAuth.instance.signOut();
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (BuildContext context) => LoginWidget()),
    );
  }
}
