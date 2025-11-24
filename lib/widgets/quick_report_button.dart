import 'package:flutter/material.dart';
import 'quick_report_sheet.dart';

class QuickReportButton extends StatelessWidget {
  const QuickReportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const QuickReportSheet(),
        );
      },
      icon: const Icon(Icons.add_alert),
      label: const Text('Reportar'),
      backgroundColor: Colors.red,
    );
  }
}

