import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:power_pod/widgets/logo_header.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:power_pod/widgets/logo_header.dart';

class LoadingPage extends StatefulWidget {
  final String podNum;
  final bool to_open;

  const LoadingPage({required this.podNum, required this.to_open});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  String? errorMsg;

  @override
  void initState() {
    super.initState();

    FirebaseDatabase.instance.ref('pod_${widget.podNum}').onValue.listen((
      event,
    ) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        if (data['request_to_open'] == false &&
            data['request_to_close'] == false) {
          Navigator.pop(context); // Close the loading page
        }

        // Update error message
        setState(() {
          errorMsg = data['error_msg'];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  child: Container(
                    width: 320,
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
                                '${widget.to_open ? "Opening" : "Closing"} Pod ${widget.podNum}...',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (errorMsg != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/images/warning.png',
                                      width: 24,
                                      height: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      errorMsg!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
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
