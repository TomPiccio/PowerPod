import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:power_pod/widgets/logo_header.dart';

class LoadingPage extends StatelessWidget {
  final String podNum;
  final bool to_open;

  const LoadingPage({required this.podNum, required this.to_open});

  @override
  Widget build(BuildContext context) {
    // Listen to Firebase value change
    FirebaseDatabase.instance.ref('pod_$podNum').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null &&
          data['request_to_open'] == false &&
          data['request_to_close'] == false) {
        Navigator.pop(context); // Pop the loading page when both are false
      }
    });

    return Scaffold(
      backgroundColor: Colors.white, // Optional: Set background color
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Container(
              width: 400,
              height: 800,
              decoration: BoxDecoration(
                color: Color.fromRGBO(255, 255, 255, 1),
              ),
              child: SingleChildScrollView(
                child: Center(
                  child: Container(
                    width: 360,
                    height: 650,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: const Color(0xFFF7FEFB)),
                    child: Stack(
                      children: [
                        LogoHeader(),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LoadingIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                '${to_open ? "Opening" : "Closing"} Pod $podNum...',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
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
      ),
    );
  }
}

class LoadingIndicator extends StatefulWidget {
  const LoadingIndicator({Key? key}) : super(key: key);

  @override
  _LoadingIndicatorState createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorTween;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true); // Repeats the animation forward and backward

    _colorTween = ColorTween(
      begin: Colors.green,
      end: Colors.blue,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorTween,
      builder: (context, child) {
        return CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color?>(_colorTween.value),
        );
      },
    );
  }
}
