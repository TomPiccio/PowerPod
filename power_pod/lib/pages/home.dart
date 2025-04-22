import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:oktoast/oktoast.dart';
import 'package:power_pod/pages/login.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:power_pod/pages/verification.dart';
import 'package:power_pod/widgets/logo_header.dart';
import '../pages/rent.dart';
import 'package:intl/intl.dart';

Future<String> getFormattedReturnTime(int rentPodNum) async {
  if (rentPodNum > 0) {
    final ref = FirebaseDatabase.instance.ref('pod_$rentPodNum/return_by');
    final snapshot = await ref.get();

    if (snapshot.exists && snapshot.value != null) {
      // Firebase returns either a String or int timestamp
      DateTime returnBy;

      if (snapshot.value is String) {
        returnBy = DateTime.parse(snapshot.value as String);
      } else if (snapshot.value is int) {
        returnBy = DateTime.fromMillisecondsSinceEpoch(snapshot.value as int);
      } else {
        return 'Invalid time';
      }

      DateTime now = DateTime.now();

      // Check if it's a different day
      bool isNextDay =
          returnBy.day != now.day ||
          returnBy.month != now.month ||
          returnBy.year != now.year;

      String formatted = DateFormat('h:mma').format(returnBy).toLowerCase();
      return isNextDay ? '$formatted +1' : formatted;
    } else {
      return 'Unknown';
    }
  } else {
    return '';
  }
}

Future<Widget> getReturnTimeRemainingWidget(int rentPodNum) async {
  if (rentPodNum <= 0) {
    return const Text(
      '-',
      style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Inter'),
    );
  }

  final ref = FirebaseDatabase.instance.ref('pod_$rentPodNum/return_by');
  final snapshot = await ref.get();

  if (!snapshot.exists || snapshot.value == null) {
    return const Text(
      'Unknown time',
      style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Inter'),
    );
  }

  DateTime returnBy;
  if (snapshot.value is String) {
    returnBy = DateTime.parse(snapshot.value as String);
  } else if (snapshot.value is int) {
    returnBy = DateTime.fromMillisecondsSinceEpoch(snapshot.value as int);
  } else {
    return const Text(
      'Invalid time',
      style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Inter'),
    );
  }

  final now = DateTime.now();
  final difference = returnBy.difference(now);
  final isOverdue = difference.isNegative;
  final time = difference.abs();

  String timeText;
  if (time.inHours >= 1) {
    timeText =
        '${time.inHours} hour${time.inHours == 1 ? '' : 's'} ${isOverdue ? 'passed' : 'remaining'}';
  } else {
    timeText =
        '${time.inMinutes} minute${time.inMinutes == 1 ? '' : 's'} ${isOverdue ? 'passed' : 'remaining'}';
  }

  return Text(
    timeText,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontFamily: 'Inter',
    ),
  );
}

Future<Widget> getPodStatusWidget() async {
  final refLastUpdated_1 = FirebaseDatabase.instance.ref('pod_1/lastUpdated');
  final refLastUpdated_2 = FirebaseDatabase.instance.ref('pod_2/lastUpdated');
  final snapshotLastUpdated1 = await refLastUpdated_1.get();
  final snapshotLastUpdated2 = await refLastUpdated_2.get();

  if (!snapshotLastUpdated1.exists ||
      snapshotLastUpdated1.value == null ||
      !snapshotLastUpdated2.exists ||
      snapshotLastUpdated2.value == null) {
    return const Text(
      'Unknown last updated time',
      style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Inter'),
    );
  }

  DateTime lastUpdated1, lastUpdated2;

  if (snapshotLastUpdated1.value is String) {
    lastUpdated1 = DateTime.parse(snapshotLastUpdated1.value as String);
  } else if (snapshotLastUpdated1.value is int) {
    lastUpdated1 = DateTime.fromMillisecondsSinceEpoch(
      snapshotLastUpdated1.value as int,
    );
  } else {
    return const Text(
      'Invalid last updated time for pod 1',
      style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Inter'),
    );
  }

  if (snapshotLastUpdated2.value is String) {
    lastUpdated2 = DateTime.parse(snapshotLastUpdated2.value as String);
  } else if (snapshotLastUpdated2.value is int) {
    lastUpdated2 = DateTime.fromMillisecondsSinceEpoch(
      snapshotLastUpdated2.value as int,
    );
  } else {
    return const Text(
      'Invalid last updated time for pod 2',
      style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Inter'),
    );
  }

  // Get the latest of the two last updated times
  DateTime lastUpdated =
      lastUpdated1.isAfter(lastUpdated2) ? lastUpdated1 : lastUpdated2;

  final now = DateTime.now();
  final difference = now.difference(lastUpdated);

  if (difference.inMinutes > 10) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center, // Centers the row content horizontally
      crossAxisAlignment:
          CrossAxisAlignment
              .center, // Ensures that the items are vertically centered
      children: [
        Image.asset(
          'assets/images/warning.png',
          height: 14, // Adjust the height to match the text size
          width: 14, // Keep width the same to maintain the aspect ratio
        ),
        const SizedBox(width: 8), // Adds space between the icon and the text
        const Text(
          'The Power Pod might be offline!',
          style: TextStyle(
            color: Colors.red,
            fontSize: 14,
            fontFamily: 'Inter',
          ),
          overflow: TextOverflow.ellipsis, // Truncates if text overflows
          maxLines: 1, // Limit text to one line
        ),
      ],
    );
  }

  return const SizedBox.shrink(); // Return an empty widget if no issue
}

Future<bool> hasReturnTimePassed(int rentPodNum) async {
  if (rentPodNum > 0) {
    final ref = FirebaseDatabase.instance.ref('pod_$rentPodNum/return_by');
    final snapshot = await ref.get();

    if (snapshot.exists && snapshot.value != null) {
      DateTime returnBy;

      if (snapshot.value is String) {
        returnBy = DateTime.parse(snapshot.value as String);
      } else if (snapshot.value is int) {
        returnBy = DateTime.fromMillisecondsSinceEpoch(snapshot.value as int);
      } else {
        return false;
      }

      final now = DateTime.now();
      return now.isAfter(returnBy);
    }
  }

  return false; // Default to false if podNum is invalid or value doesn't exist
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _dbRef = FirebaseDatabase.instance.ref(); // <-- Make sure you init this
  Map<String, dynamic> pod1Data = {};
  Map<String, dynamic> pod2Data = {};
  Map<String, dynamic> pod3Data = {};
  String?
  userUid; // Store the user's UID, assuming you've already got it from FirebaseAuth.
  int rentPodNum = 0;
  bool isLate = false;
  String? firstName;

  @override
  void initState() {
    super.initState();

    // Assuming you have the user's UID stored (you can get it from FirebaseAuth):
    userUid = FirebaseAuth.instance.currentUser?.uid;

    // List of pod references to avoid repeating code
    List<String> podIds = ['pod_1', 'pod_2', 'pod_3'];

    // Iterate over each pod to listen for changes and handle data
    for (String podId in podIds) {
      _listenToPodData(podId);
      fetchFirstName();
    }

    _checkEmailVerification();
  }

  Future<void> _checkEmailVerification() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && !user.emailVerified) {
      // Navigate to the Verification Page if email is not verified
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => verification()),
      );
    }
  }

  Future<void> fetchFirstName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final fullName = doc['name'] as String;
      final firstWord = fullName.split(' ').first;

      setState(() {
        firstName = firstWord;
      });
    }
  }

  void _listenToPodData(String podId) {
    _dbRef.child(podId).onValue.listen((event) async {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      // Check if the pod is available for the user based on UID
      bool isPodRentedbyUser =
          userUid == data["renter_user_id"] && data["renter_user_id"] != null;
      data["isPodRentedbyUser"] = isPodRentedbyUser;

      int updatedRentPodNum = rentPodNum;
      if (podId == 'pod_1') {
        pod1Data = data;
      } else if (podId == 'pod_2') {
        pod2Data = data;
      } else if (podId == 'pod_3') {
        pod3Data = data;
      }

      // Determine which pod is rented
      if (isPodRentedbyUser) {
        updatedRentPodNum = int.parse(
          podId.split('_')[1],
        ); // extract 1, 2, or 3
      } else if (userUid != null) {
        if (pod1Data["renter_user_id"] == userUid) {
          updatedRentPodNum = 1;
        } else if (pod2Data["renter_user_id"] == userUid) {
          updatedRentPodNum = 2;
        } else if (pod3Data["renter_user_id"] == userUid) {
          updatedRentPodNum = 3;
        } else {
          updatedRentPodNum = 0;
        }
      }

      // Call async function outside setState
      bool updatedIsLate = await hasReturnTimePassed(rentPodNum);

      // Now update state
      setState(() {
        rentPodNum = updatedRentPodNum;
        isLate = updatedIsLate;
      });
    });
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
                                // Wrap with SingleChildScrollView to avoid overflow
                                child: Container(
                                  width:
                                      320, // Set width to match parent container
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 13,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width:
                                            double
                                                .infinity, // Ensure it uses the full width
                                        child: Text(
                                          firstName != null
                                              ? 'Hi $firstName!'
                                              : 'Hi There!',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 20,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 8),

                                      // Second ConstrainedBox (Power Bank Info)
                                      Container(
                                        width:
                                            double
                                                .infinity, // Ensure it uses the full width
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        decoration: ShapeDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment(-0.00, 0.50),
                                            end: Alignment(1.00, 0.50),
                                            colors: [
                                              Color(
                                                rentPodNum != 0
                                                    ? isLate
                                                        ? 0xFFDC1C13
                                                        : 0xFF3897DC
                                                    : 0xFF909090,
                                              ),
                                              Color(
                                                rentPodNum != 0
                                                    ? isLate
                                                        ? 0xFFF07470
                                                        : 0xFF34D09B
                                                    : 0xFF505050,
                                              ),
                                            ],
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 12.0,
                                              ), // Top & bottom padding
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  // Image + Left Text
                                                  Row(
                                                    children: [
                                                      Container(
                                                        width: 39,
                                                        height: 39,
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
                                                        width: 8,
                                                      ), // space between image and text
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            rentPodNum != 0
                                                                ? isLate
                                                                    ? 'NOT YET RETURNED'
                                                                    : 'Currently Renting'
                                                                : 'Not Renting',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 16,
                                                              fontFamily:
                                                                  'Inter',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              height: 1.40,
                                                            ),
                                                          ),
                                                          Text(
                                                            rentPodNum != 0
                                                                ? isLate
                                                                    ? 'Please Return Pod #$rentPodNum'
                                                                    : 'Pod #$rentPodNum'
                                                                : '-',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 14,
                                                              fontFamily:
                                                                  'Inter',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              height: 1.40,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),

                                                  // Right-aligned Column
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                      right: 12.0,
                                                    ), // adjust the value as needed
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: [
                                                        Text(
                                                          rentPodNum != 0
                                                              ? 'Return By'
                                                              : '',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                            fontFamily: 'Inter',
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            height: 1.40,
                                                          ),
                                                        ),
                                                        FutureBuilder<String>(
                                                          future:
                                                              getFormattedReturnTime(
                                                                rentPodNum,
                                                              ),
                                                          builder: (
                                                            context,
                                                            snapshot,
                                                          ) {
                                                            if (snapshot
                                                                    .connectionState ==
                                                                ConnectionState
                                                                    .waiting) {
                                                              return CircularProgressIndicator();
                                                            } else if (snapshot
                                                                .hasError) {
                                                              return Text(
                                                                'Error loading time',
                                                              );
                                                            } else {
                                                              return Text(
                                                                snapshot.data ??
                                                                    'Unknown',
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  fontSize: 16,
                                                                  fontFamily:
                                                                      'Inter',
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  height: 1.40,
                                                                ),
                                                              );
                                                            }
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            Container(
                                              width: double.infinity,
                                              decoration: ShapeDecoration(
                                                shape: RoundedRectangleBorder(
                                                  side: BorderSide(
                                                    width: 1,
                                                    strokeAlign:
                                                        BorderSide
                                                            .strokeAlignCenter,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(5),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.all(
                                                      4.0,
                                                    ), // padding around the image
                                                    child: Container(
                                                      width: 23.08,
                                                      height: 23.08,
                                                      decoration: BoxDecoration(
                                                        image: DecorationImage(
                                                          image: AssetImage(
                                                            'assets/images/clock.png',
                                                          ),
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 8,
                                                  ), // spacing between image and text
                                                  FutureBuilder<Widget>(
                                                    future:
                                                        getReturnTimeRemainingWidget(
                                                          rentPodNum,
                                                        ),
                                                    builder: (
                                                      context,
                                                      snapshot,
                                                    ) {
                                                      if (snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return const CircularProgressIndicator();
                                                      } else if (snapshot
                                                          .hasData) {
                                                        return snapshot.data!;
                                                      } else {
                                                        return const Text(
                                                          'Error',
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 18,
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        decoration: ShapeDecoration(
                                          color: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              width: 1,
                                              color: const Color(0xFFE0E0E0),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          shadows: [
                                            BoxShadow(
                                              color: Color(0x3F3A83F4),
                                              blurRadius: 4,
                                              offset: Offset(0, 4),
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Power Bank #1',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16,
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w700,
                                                    height: 1.40,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 28,
                                                      height: 28,
                                                      decoration: BoxDecoration(
                                                        image: DecorationImage(
                                                          image: AssetImage(
                                                            pod1Data["is_Available"] ==
                                                                    true
                                                                ? pod1Data["power_input_status"] ==
                                                                        true
                                                                    ? 'assets/images/vehicle (1).png'
                                                                    : 'assets/images/power.png'
                                                                : pod1Data["power_input_status"] ==
                                                                    true
                                                                ? 'assets/images/warning.png'
                                                                : 'assets/images/open-hand.png',
                                                          ),
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 8,
                                                    ), // spacing between icon and text
                                                    Text(
                                                      pod1Data["is_Available"] ==
                                                              true
                                                          ? pod1Data["power_input_status"] ==
                                                                  true
                                                              ? "Charging"
                                                              : "Full"
                                                          : pod1Data["power_input_status"] ==
                                                              true
                                                          ? "Error"
                                                          : "Rented",
                                                      style: TextStyle(
                                                        color: Color(
                                                          pod1Data["is_Available"] ==
                                                                  true
                                                              ? pod1Data["power_input_status"] ==
                                                                      true
                                                                  ? 0xFF3A83F4
                                                                  : 0xFF009951
                                                              : pod1Data["power_input_status"] ==
                                                                  true
                                                              ? 0xFFCF1F25
                                                              : 0xFF000000,
                                                        ),
                                                        fontSize: 14,
                                                        fontFamily: 'Inter',
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        height: 1.40,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),

                                            Spacer(),
                                            IgnorePointer(
                                              ignoring:
                                                  rentPodNum != 1 &&
                                                      rentPodNum != 0 ||
                                                  (pod1Data["power_input_status"] ==
                                                          true ||
                                                      (pod1Data["is_Available"] !=
                                                              true) &&
                                                          (pod1Data["isPodRentedbyUser"] !=
                                                              true)), // disables all interactions
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (
                                                              context,
                                                            ) => RentInstructionPage(
                                                              podNumber: 1,
                                                              to_rent:
                                                                  !(pod1Data["is_Available"] ==
                                                                          false &&
                                                                      pod1Data["power_input_status"] ==
                                                                          false &&
                                                                      pod1Data["isPodRentedbyUser"] ==
                                                                          true),
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  splashColor: Colors.white24,
                                                  child: Ink(
                                                    width: 122,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: Color(
                                                        pod1Data["is_Available"] ==
                                                                true
                                                            ? pod1Data["power_input_status"] ==
                                                                    true
                                                                ? 0xFF9E9E9E
                                                                : rentPodNum !=
                                                                    0
                                                                ? 0xFF8FAE9F
                                                                : 0xFF34D09B
                                                            : pod1Data["power_input_status"] ==
                                                                true
                                                            ? 0xFF9E9E9E
                                                            : pod1Data["isPodRentedbyUser"] ==
                                                                true
                                                            ? 0xFF3897DC
                                                            : 0xFF9E9E9E,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        pod1Data["is_Available"] ==
                                                                true
                                                            ? pod1Data["power_input_status"] ==
                                                                    true
                                                                ? "Unavailable"
                                                                : "Rent"
                                                            : pod1Data["power_input_status"] ==
                                                                true
                                                            ? "Unavailable"
                                                            : pod1Data["isPodRentedbyUser"] ==
                                                                true
                                                            ? "Return"
                                                            : "Unavailable",
                                                        style: TextStyle(
                                                          color: Color(
                                                            0xFFF5F5F5,
                                                          ),
                                                          fontSize: 16,
                                                          fontFamily: 'Inter',
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          height: 1,
                                                        ),
                                                        textHeightBehavior:
                                                            TextHeightBehavior(
                                                              applyHeightToFirstAscent:
                                                                  false,
                                                              applyHeightToLastDescent:
                                                                  false,
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
                                      SizedBox(height: 20),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 18,
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        decoration: ShapeDecoration(
                                          color: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              width: 1,
                                              color: const Color(0xFFE0E0E0),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          shadows: [
                                            BoxShadow(
                                              color: Color(0x3F3A83F4),
                                              blurRadius: 4,
                                              offset: Offset(0, 4),
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Power Bank #2',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16,
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w700,
                                                    height: 1.40,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 28,
                                                      height: 28,
                                                      decoration: BoxDecoration(
                                                        image: DecorationImage(
                                                          image: AssetImage(
                                                            pod2Data["is_Available"] ==
                                                                    true
                                                                ? pod2Data["power_input_status"] ==
                                                                        true
                                                                    ? 'assets/images/vehicle (1).png'
                                                                    : 'assets/images/power.png'
                                                                : pod2Data["power_input_status"] ==
                                                                    true
                                                                ? 'assets/images/warning.png'
                                                                : 'assets/images/open-hand.png',
                                                          ),
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 8,
                                                    ), // spacing between icon and text
                                                    Text(
                                                      pod2Data["is_Available"] ==
                                                              true
                                                          ? pod2Data["power_input_status"] ==
                                                                  true
                                                              ? "Charging"
                                                              : "Full"
                                                          : pod2Data["power_input_status"] ==
                                                              true
                                                          ? "Error"
                                                          : "Rented",
                                                      style: TextStyle(
                                                        color: Color(
                                                          pod2Data["is_Available"] ==
                                                                  true
                                                              ? pod2Data["power_input_status"] ==
                                                                      true
                                                                  ? 0xFF3A83F4
                                                                  : 0xFF009951
                                                              : pod2Data["power_input_status"] ==
                                                                  true
                                                              ? 0xFFCF1F25
                                                              : 0xFF000000,
                                                        ),
                                                        fontSize: 14,
                                                        fontFamily: 'Inter',
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        height: 1.40,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),

                                            Spacer(),
                                            IgnorePointer(
                                              ignoring:
                                                  rentPodNum != 2 &&
                                                      rentPodNum != 0 ||
                                                  (pod2Data["power_input_status"] ==
                                                          true ||
                                                      (pod2Data["is_Available"] !=
                                                              true) &&
                                                          (pod2Data["isPodRentedbyUser"] !=
                                                              true)), // disables all interactions
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (
                                                              context,
                                                            ) => RentInstructionPage(
                                                              podNumber: 2,
                                                              to_rent:
                                                                  !(pod1Data["is_Available"] ==
                                                                          false &&
                                                                      pod1Data["power_input_status"] ==
                                                                          false &&
                                                                      pod1Data["isPodRentedbyUser"] ==
                                                                          true),
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  splashColor: Colors.white24,
                                                  child: Ink(
                                                    width: 122,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: Color(
                                                        pod2Data["is_Available"] ==
                                                                true
                                                            ? pod2Data["power_input_status"] ==
                                                                    true
                                                                ? 0xFF9E9E9E
                                                                : rentPodNum !=
                                                                    0
                                                                ? 0xFF8FAE9F
                                                                : 0xFF34D09B
                                                            : pod2Data["power_input_status"] ==
                                                                true
                                                            ? 0xFF9E9E9E
                                                            : pod2Data["isPodRentedbyUser"] ==
                                                                true
                                                            ? 0xFF3897DC
                                                            : 0xFF9E9E9E,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        pod2Data["is_Available"] ==
                                                                true
                                                            ? pod2Data["power_input_status"] ==
                                                                    true
                                                                ? "Unavailable"
                                                                : "Rent"
                                                            : pod2Data["power_input_status"] ==
                                                                true
                                                            ? "Unavailable"
                                                            : pod2Data["isPodRentedbyUser"] ==
                                                                true
                                                            ? "Return"
                                                            : "Unavailable",
                                                        style: TextStyle(
                                                          color: Color(
                                                            0xFFF5F5F5,
                                                          ),
                                                          fontSize: 16,
                                                          fontFamily: 'Inter',
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          height: 1,
                                                        ),
                                                        textHeightBehavior:
                                                            TextHeightBehavior(
                                                              applyHeightToFirstAscent:
                                                                  false,
                                                              applyHeightToLastDescent:
                                                                  false,
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
                                      SizedBox(height: 10),
                                      FutureBuilder<Widget>(
                                        future:
                                            getPodStatusWidget(), // Call the async function here
                                        builder: (context, snapshot) {
                                          // Check if the Future has completed
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const CircularProgressIndicator(); // Loading indicator
                                          } else if (snapshot.hasError) {
                                            return Text(
                                              'Error: ${snapshot.error}',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            );
                                          } else {
                                            return snapshot.data ??
                                                SizedBox.shrink(); // Display the result
                                          }
                                        },
                                      ),
                                      /*
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 18,
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        decoration: ShapeDecoration(
                                          color: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              width: 1,
                                              color: const Color(0xFFE0E0E0),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          shadows: [
                                            BoxShadow(
                                              color: Color(0x3F3A83F4),
                                              blurRadius: 4,
                                              offset: Offset(0, 4),
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Power Bank #3',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16,
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w700,
                                                    height: 1.40,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 28,
                                                      height: 28,
                                                      decoration: BoxDecoration(
                                                        image: DecorationImage(
                                                          image: AssetImage(
                                                            pod3Data["is_Available"] ==
                                                                    true
                                                                ? pod3Data["power_input_status"] ==
                                                                        true
                                                                    ? 'assets/images/vehicle (1).png'
                                                                    : 'assets/images/power.png'
                                                                : pod3Data["power_input_status"] ==
                                                                    true
                                                                ? 'assets/images/warning.png'
                                                                : 'assets/images/open-hand.png',
                                                          ),
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 8,
                                                    ), // spacing between icon and text
                                                    Text(
                                                      pod3Data["is_Available"] ==
                                                              true
                                                          ? pod3Data["power_input_status"] ==
                                                                  true
                                                              ? "Charging"
                                                              : "Full"
                                                          : pod3Data["power_input_status"] ==
                                                              true
                                                          ? "Error"
                                                          : "Rented",
                                                      style: TextStyle(
                                                        color: Color(
                                                          pod3Data["is_Available"] ==
                                                                  true
                                                              ? pod3Data["power_input_status"] ==
                                                                      true
                                                                  ? 0xFF3A83F4
                                                                  : 0xFF009951
                                                              : pod3Data["power_input_status"] ==
                                                                  true
                                                              ? 0xFFCF1F25
                                                              : 0xFF000000,
                                                        ),
                                                        fontSize: 14,
                                                        fontFamily: 'Inter',
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        height: 1.40,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),

                                            Spacer(),
                                            IgnorePointer(
                                              ignoring:
                                                  rentPodNum != 3 &&
                                                      rentPodNum != 0 ||
                                                  (pod3Data["power_input_status"] ==
                                                          true ||
                                                      (pod3Data["is_Available"] !=
                                                              true) &&
                                                          (pod3Data["isPodRentedbyUser"] !=
                                                              true)), // disables all interactions
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (
                                                              context,
                                                            ) => RentInstructionPage(
                                                              podNumber: 3,
                                                              to_rent:
                                                                  !(pod1Data["is_Available"] ==
                                                                          false &&
                                                                      pod1Data["power_input_status"] ==
                                                                          false &&
                                                                      pod1Data["isPodRentedbyUser"] ==
                                                                          true),
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  splashColor: Colors.white24,
                                                  child: Ink(
                                                    width: 122,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: Color(
                                                        pod3Data["is_Available"] ==
                                                                true
                                                            ? pod3Data["power_input_status"] ==
                                                                    true
                                                                ? 0xFF9E9E9E
                                                                : rentPodNum !=
                                                                    0
                                                                ? 0xFF8FAE9F
                                                                : 0xFF34D09B
                                                            : pod3Data["power_input_status"] ==
                                                                true
                                                            ? 0xFF9E9E9E
                                                            : pod3Data["isPodRentedbyUser"] ==
                                                                true
                                                            ? 0xFF3897DC
                                                            : 0xFF9E9E9E,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        pod3Data["is_Available"] ==
                                                                true
                                                            ? pod3Data["power_input_status"] ==
                                                                    true
                                                                ? "Unavailable"
                                                                : "Rent"
                                                            : pod3Data["power_input_status"] ==
                                                                true
                                                            ? "Unavailable"
                                                            : pod3Data["isPodRentedbyUser"] ==
                                                                true
                                                            ? "Return"
                                                            : "Unavailable",
                                                        style: TextStyle(
                                                          color: Color(
                                                            0xFFF5F5F5,
                                                          ),
                                                          fontSize: 16,
                                                          fontFamily: 'Inter',
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          height: 1,
                                                        ),
                                                        textHeightBehavior:
                                                            TextHeightBehavior(
                                                              applyHeightToFirstAscent:
                                                                  false,
                                                              applyHeightToLastDescent:
                                                                  false,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),*/
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
