import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:power_pod/pages/home.dart';
import 'package:power_pod/pages/loading.dart';
import 'package:power_pod/widgets/logo_header.dart';
import '../services/auth_Service.dart';
import '../pages/signup.dart';

class RentInstructionPage extends StatefulWidget {
  final int podNumber;
  final bool to_rent;

  // Constructor with default values using named optional parameters
  const RentInstructionPage({this.podNumber = 1, this.to_rent = true, Key? key})
    : super(key: key);

  @override
  RentInstructionPageState createState() => RentInstructionPageState();
}

class RentInstructionPageState extends State<RentInstructionPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  Future<void> uploadUserDetailsRent(int podNumber) async {
    final user = FirebaseAuth.instance.currentUser;
    final userUid = FirebaseAuth.instance.currentUser?.uid;

    if (user == null) {
      print("User not logged in");
      return;
    }

    try {
      // Get Firestore user document
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!docSnapshot.exists) {
        print("User document does not exist in Firestore");
        return;
      }

      final data = docSnapshot.data();

      if (data == null || !data.containsKey('email')) {
        print("Email not found in Firestore");
        return;
      }

      final email = data['email'];

      if (!data.containsKey('contact')) {
        print("Contact number not found in Firestore");
        return;
      }

      final contactNumber = data['contact'];

      // Upload to Realtime Database
      await FirebaseDatabase.instance
          .ref('pod_$podNumber/renter_email')
          .set(email);

      await FirebaseDatabase.instance
          .ref('pod_$podNumber/renter_contact_number')
          .set(contactNumber);

      final currentTime = DateTime.now();
      final returnByTime = currentTime.add(Duration(hours: 24));

      // Format to 'yyyy-MM-dd HH:mm:ss'
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      final formattedReturnByTime = dateFormat.format(returnByTime);

      await FirebaseDatabase.instance
          .ref('pod_$podNumber/return_by')
          .set(formattedReturnByTime);

      await FirebaseDatabase.instance
          .ref('pod_$podNumber/renter_user_id')
          .set(userUid);

      print("Rental Success: email = $email, contact = $contactNumber");
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> clearUserDetailsRent(int podNumber) async {
    try {
      final dbRef = FirebaseDatabase.instance.ref('pod_$podNumber');

      await dbRef.child('renter_email').set(null);
      await dbRef.child('renter_contact_number').set(null);
      await dbRef.child('return_by').set(null);
      await dbRef.child('renter_user_id').set(null);

      print("Rental info cleared for pod $podNumber");
    } catch (e) {
      print("Error clearing rental info: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _currentPage = _controller.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                            Positioned(
                              top: 75,
                              child: SingleChildScrollView(
                                child: Container(
                                  width: 320,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 13,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 5,
                                          ),
                                          child: Text(
                                            '${widget.to_rent ? "Renting" : "Returning"} Pod #${widget.podNumber}',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inter',
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 400,
                                        child: PageView(
                                          controller: _controller,
                                          onPageChanged: (index) {
                                            setState(() {
                                              _currentPage = index;
                                            });
                                          },
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          children: [
                                            Container(
                                              width: 300,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 17,
                                                    vertical: 26,
                                                  ),
                                              clipBehavior: Clip.antiAlias,
                                              decoration: BoxDecoration(),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                spacing: 18,
                                                children: [
                                                  Container(
                                                    width: 100,
                                                    height: 100,
                                                    decoration: BoxDecoration(
                                                      image: DecorationImage(
                                                        image: AssetImage(
                                                          'assets/images/power.png',
                                                        ),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 295,
                                                    child: Text(
                                                      'Scan QR Code',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 24,
                                                        fontFamily: 'Inter',
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        height: 1.20,
                                                        letterSpacing: -0.48,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 295,
                                                    child: Text(
                                                      'Locate a Power Pod station and scan\nthe QR code using your phone’s camera',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 16,
                                                        fontFamily: 'Inter',
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        height: 1.40,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: 300,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 17,
                                                    vertical: 26,
                                                  ),
                                              clipBehavior: Clip.antiAlias,
                                              decoration: BoxDecoration(),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                spacing: 18,
                                                children: [
                                                  Container(
                                                    width: 100,
                                                    height: 100,
                                                    decoration: BoxDecoration(
                                                      image: DecorationImage(
                                                        image: AssetImage(
                                                          'assets/images/flash.png',
                                                        ),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 295,
                                                    child: Text(
                                                      'Scan QR Code',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 24,
                                                        fontFamily: 'Inter',
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        height: 1.20,
                                                        letterSpacing: -0.48,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 295,
                                                    child: Text(
                                                      'Locate a Power Pod station and scan\nthe QR code using your phone’s camera',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 16,
                                                        fontFamily: 'Inter',
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        height: 1.40,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: 300,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 17,
                                                    vertical: 26,
                                                  ),
                                              clipBehavior: Clip.antiAlias,
                                              decoration: BoxDecoration(),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                spacing: 18,
                                                children: [
                                                  Container(
                                                    width: 100,
                                                    height: 100,
                                                    decoration: BoxDecoration(
                                                      image: DecorationImage(
                                                        image: AssetImage(
                                                          'assets/images/warning.png',
                                                        ),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 295,
                                                    child: Text(
                                                      'Scan QR Code',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 24,
                                                        fontFamily: 'Inter',
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        height: 1.20,
                                                        letterSpacing: -0.48,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 295,
                                                    child: Text(
                                                      'Locate a Power Pod station and scan\nthe QR code using your phone’s camera',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 16,
                                                        fontFamily: 'Inter',
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        height: 1.40,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Dots Indicator
                                          Row(
                                            children: List.generate(
                                              _totalPages,
                                              (index) {
                                                return AnimatedContainer(
                                                  duration: Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  margin: EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 16,
                                                  ),
                                                  width:
                                                      _currentPage == index
                                                          ? 12
                                                          : 8,
                                                  height:
                                                      _currentPage == index
                                                          ? 12
                                                          : 8,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color:
                                                        _currentPage == index
                                                            ? Colors.black
                                                            : Colors.grey,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 25),
                                      IgnorePointer(
                                        ignoring:
                                            false, // disables all interactions
                                        child: SizedBox(
                                          width: 329,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () async {
                                                      // Set request_to_open to true
                                                      if (_currentPage == 0) {
                                                        await FirebaseDatabase
                                                            .instance
                                                            .ref(
                                                              'pod_${widget.podNumber}/request_to_open',
                                                            )
                                                            .set(true);
                                                      } else if (_currentPage ==
                                                          1) {
                                                        await FirebaseDatabase
                                                            .instance
                                                            .ref(
                                                              'pod_${widget.podNumber}/request_to_close',
                                                            )
                                                            .set(true);
                                                      }
                                                      // Navigate to the loading screen

                                                      // Navigation logic
                                                      if (_currentPage ==
                                                          _totalPages - 1) {
                                                        // If this is the last page, go to home page
                                                        if (widget.to_rent) {
                                                          await uploadUserDetailsRent(
                                                            widget.podNumber,
                                                          );
                                                        } else {
                                                          await clearUserDetailsRent(
                                                            widget.podNumber,
                                                          );
                                                        }
                                                        Navigator.pushReplacement(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (_) =>
                                                                    Home(), // Replace with your home screen
                                                          ),
                                                        );
                                                      } else {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  _,
                                                                ) => LoadingPage(
                                                                  podNum:
                                                                      '${widget.podNumber}',
                                                                  to_open:
                                                                      _currentPage ==
                                                                      0,
                                                                ),
                                                          ),
                                                        );
                                                        // Otherwise, move to the next onboarding page
                                                        _controller.nextPage(
                                                          duration: Duration(
                                                            milliseconds: 300,
                                                          ),
                                                          curve:
                                                              Curves.easeInOut,
                                                        );
                                                      }
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    splashColor: Colors.white24,
                                                    child: Ink(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            12,
                                                          ),
                                                      decoration: ShapeDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                              begin: Alignment(
                                                                0.00,
                                                                0.50,
                                                              ),
                                                              end: Alignment(
                                                                1.00,
                                                                0.50,
                                                              ),
                                                              colors: [
                                                                const Color(
                                                                  0xFF34D09B,
                                                                ),
                                                                const Color(
                                                                  0xFF3A83F4,
                                                                ),
                                                              ],
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          side: BorderSide(
                                                            width: 1,
                                                            color: const Color(
                                                              0xFF34D09B,
                                                            ),
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            _currentPage == 0
                                                                ? widget.to_rent
                                                                    ? 'Rent Now!'
                                                                    : 'Return'
                                                                : _currentPage ==
                                                                    1
                                                                ? 'Done'
                                                                : 'Back to Home',
                                                            style: TextStyle(
                                                              color: const Color(
                                                                0xFFF5F5F5,
                                                              ), // Text-Brand-On-Brand
                                                              fontSize: 16,
                                                              fontFamily:
                                                                  'Inter',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              height: 1,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
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
