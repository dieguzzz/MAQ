import 'package:flutter/material.dart';
import '../screens/reports/report_screen.dart';

class QuickReportButton extends StatelessWidget {
  const QuickReportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ReportScreen(),
          ),
        );
      },
      icon: const Icon(Icons.add_alert),
      label: const Text('Reportar'),
      backgroundColor: Colors.red,
    );
  }
}

