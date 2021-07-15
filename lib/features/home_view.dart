import 'package:flutter/material.dart';
import 'package:voice_and_face_detecting/features/google_ml_vision/google_ml_vision_view.dart';
import 'package:voice_and_face_detecting/features/noise_meter_view.dart';
import 'package:voice_and_face_detecting/features/speech_to_text_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;
  List<Widget> _tabScreens = [
    NoiseMeterView(),
    GoogleMLVisionView(),
    SpeechToTextView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabScreens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        currentIndex: _currentIndex,
        items: [
          _bottomBarItem(icon: Icons.volume_up_sharp, label: "Noise Meter"),
          _bottomBarItem(
            icon: Icons.visibility_sharp,
            label: "Google ML Vision",
          ),
          _bottomBarItem(
            icon: Icons.text_rotation_none_sharp,
            label: "Text To Speech",
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _bottomBarItem({
    required IconData icon,
    required String label,
  }) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      label: label,
    );
  }
}
