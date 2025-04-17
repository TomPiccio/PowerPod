// lib/widgets/custom_header.dart
import 'package:flutter/material.dart';

class LogoHeader extends StatelessWidget {
  const LogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      child: Container(
        width: 360,
        height: 83,
        decoration: BoxDecoration(color: const Color(0xFFF1FDF9)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 70,

              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x2334CD9F),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Shrinks to fit content
                mainAxisAlignment:
                    MainAxisAlignment
                        .center, // Aligns elements to the start (left)
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Vertically centers the items
                children: [
                  // Image
                  Container(
                    width: 60, // Adjust the width to fit the image size
                    height: 60, // Adjust the height to fit the image size
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/Powerpod.png'),
                        fit:
                            BoxFit
                                .scaleDown, // Fits without scaling up (avoids distortion)
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 8,
                  ), // Reduced spacing between the image and the text
                  // Text
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        colors: [Colors.green, Colors.blue],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                      );
                    },

                    child: Container(
                      alignment: Alignment.center,
                      height: 60, // Ensure enough height for the text to fit
                      child: Text(
                        'Power Pod',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 30, // Adjust font size to fit better
                          fontWeight: FontWeight.bold,
                          color:
                              Colors.white, // ShaderMask works with this color
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
    );
  }
}
