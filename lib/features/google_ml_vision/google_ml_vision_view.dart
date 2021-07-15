import 'package:flutter/material.dart';
import 'package:voice_and_face_detecting/constants/app_constants.dart';
import 'package:voice_and_face_detecting/utils/extensions/google_ml_type_extensions.dart';

class GoogleMLVisionView extends StatefulWidget {
  const GoogleMLVisionView({Key? key}) : super(key: key);

  @override
  _GoogleMLVisionViewState createState() => _GoogleMLVisionViewState();
}

class _GoogleMLVisionViewState extends State<GoogleMLVisionView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example List'),
      ),
      body: ListView.builder(
        itemCount: GoogleMLVisionViewType.values.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: ListTile(
              title: Text(
                GoogleMLVisionViewType.values[index]
                    .getGoogleMLVisionTypeText(),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return GoogleMLVisionViewType.values[index]
                        .getGoogleMLVisionView();
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
