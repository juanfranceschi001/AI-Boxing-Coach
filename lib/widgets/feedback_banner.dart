import 'package:flutter/material.dart';
import '../models/form_issue.dart';

/// On-screen correction banner. Updates as soon as an issue is debounced
/// as "active" (no cooldown), since it's less intrusive than a spoken cue.
class FeedbackBanner extends StatelessWidget {
  final List<FormIssueType> activeIssues;

  const FeedbackBanner({super.key, required this.activeIssues});

  @override
  Widget build(BuildContext context) {
    if (activeIssues.isEmpty) {
      return const SizedBox.shrink();
    }
    final primary = activeIssues.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        primary.cue,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
