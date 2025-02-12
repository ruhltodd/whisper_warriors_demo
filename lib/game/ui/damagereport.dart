import 'package:flutter/material.dart';

class DamageReportOverlay extends StatelessWidget {
  final String report;

  const DamageReportOverlay({required this.report, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      padding: EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              report,
              style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle restart or return to menu
              },
              child: Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
