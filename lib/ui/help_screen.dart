import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    (
      'Why isn\'t my bus showing up?',
      'The driver needs to have started their trip and enabled location sharing. If nothing appears after a few minutes, confirm your bus number in Edit Profile matches the one the driver is using.',
    ),
    (
      'How is the ETA calculated?',
      'It\'s estimated from the bus\'s recent speed and its distance to your stop. It can be unavailable if the bus is stationary or just started moving.',
    ),
    (
      'When do I get notified?',
      'You\'ll get a notification when the bus is about 10 minutes from your stop, based on its live speed and distance. If speed can\'t be measured yet (e.g. the bus just started moving), you\'ll instead be notified once it\'s within 300 meters. Notifications are skipped if muted or during a quiet-hours window in Settings.',
    ),
    (
      'How do I change my bus stop?',
      'Go to Edit Profile, tap Edit next to Bus Stop Location, then tap the map to drop a new pin or use your current location.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                for (final faq in _faqs)
                  ExpansionTile(
                    title: Text(faq.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedAlignment: Alignment.topLeft,
                    children: [
                      Text(faq.$2, style: TextStyle(color: Colors.grey[700], height: 1.4)),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Contact',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const ListTile(
              leading: Icon(Icons.email_outlined),
              title: Text('School Transport Office'),
              subtitle: Text('Reach out for anything not covered above'),
            ),
          ),
        ],
      ),
    );
  }
}
