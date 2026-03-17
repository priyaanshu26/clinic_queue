import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label = status.toUpperCase().replaceAll('_', ' ').replaceAll('-', ' ');

    switch (status.toLowerCase()) {
      case 'waiting':
      case 'queued':
        color = Colors.orange;
        break;
      case 'in-progress':
      case 'in_progress':
      case 'scheduled':
        color = Colors.blue;
        break;
      case 'done':
      case 'completed':
        color = Colors.green;
        break;
      case 'skipped':
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
