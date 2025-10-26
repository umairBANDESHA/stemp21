import 'package:flutter/material.dart';
import 'app_colors.dart';

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  _GetStartedPageState createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen height and width for responsiveness
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Responsive App logo
              Image.asset(
                'assets/images/stemp.png',
                height: screenHeight * 0.3, // 30% of screen height
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 30),

              // Second picture under logo - WIDE
              Image.asset(
                'assets/images/under.png',
                height: screenHeight * 0.2, // 20% of screen height
                width: double.infinity, // full screen width
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 50),

              // Taglines
              Text(
                "Building Future Innovation Through STEM Education\n Driving Economic Growth And Sustainability",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenHeight * 0.018,
                  color: AppColors.textDarkBlue.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "\nFor Admins, Sub-Admin & Teachers",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenHeight * 0.018,
                  color: AppColors.textDarkBlue.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
