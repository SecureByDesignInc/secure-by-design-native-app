import 'models.dart';

/// App presentation only. Course IDs and server progress groups stay stable.
class TrainingCategory {
  const TrainingCategory(this.id, this.title, this.description, this.icon,
      this.pathIds);
  final String id, title, description, icon;
  final List<String> pathIds;
  bool contains(LearningPath path) => pathIds.contains(path.id);
}

/// Every published course belongs to exactly one category; within a category
/// courses keep the website's order (1.1, 1.2, … 1.12, then 2.1). The
/// website's coming-soon tiles (1.9 and 1.10) have no material and aren't in the app.
/// Course 1.1 holds what courses 1.1–1.8 taught (20 October 2026).
const trainingCategories = [
  TrainingCategory(
      'foundations',
      'Network Foundations',
      'Build the network one system at a time: the identity foundation '
          '(domain controllers, DNS, domain time, STIG hardening, PKI, DHCP '
          'and tiered administration), the Linux repository, the logging '
          'pipeline, the workstation fleet, Windows updates, the living '
          'inventory, business services, and proven recovery.',
      'directory', [
    'identity-foundation',
    'linux-repository',
    'logging-pipeline',
    'audit-repository',
    'splunk-analysis',
    'workstation-fleet',
    'patch-protect',
    'management-server',
    'business-services',
    'prove-recovery',
  ]),
  TrainingCategory(
      'authorization',
      'Network Authorization',
      'Take the network you built through the Risk Management Framework steps '
          'of NIST SP 800-37, with the JSIG mapped in: prepare, categorize, and '
          'select; implement and assess; then authorize and monitor.',
      'journal',
      // One course since 15 October 2026 on the website (2.1, RMF to ATO); the app matches since 20 October 2026.
      ['rmf-boe-ato']),
];

TrainingCategory categoryFor(LearningPath path) => trainingCategories.firstWhere(
    (category) => category.contains(path),
    orElse: () => TrainingCategory(
        path.category, path.category, path.subtitle, path.icon, [path.id]));
