import 'package:flutter/material.dart';
import '../Model/Constructionsite/ConstructionSiteModel.dart';

class WorkerTooltip extends StatelessWidget {
  final ConstructionSite site;
  const WorkerTooltip({super.key, required this.site});

  @override
  Widget build(BuildContext context) {
    // Static workers (replace these with your demo names)
    final List<String> staticPresent = ["Alice", "Bob"];
    final List<String> staticAbsent = ["Charlie", "Diana"];

    return Card(
      elevation: 8,
      margin: const EdgeInsets.only(bottom: 50, left: 10, right: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    site.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Present:",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800]),
              ),
              ...staticPresent.map((name) => Row(
                children: [
                  const Icon(Icons.check, color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Text(name),
                ],
              )),
              if (staticAbsent.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  "Absent:",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[800]),
                ),
                ...staticAbsent.map((name) => Row(
                  children: [
                    const Icon(Icons.close, color: Colors.red, size: 18),
                    const SizedBox(width: 6),
                    Text(name),
                  ],
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}