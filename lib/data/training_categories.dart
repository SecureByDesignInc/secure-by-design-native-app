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
/// courses keep the website's order (1.1, 1.2, … 1.12, then 2.1–2.3).
const trainingCategories = [
  TrainingCategory(
      'foundations',
      'Network Foundations',
      'Build identity and DNS, harden and segment the network, then add '
          'logging, the workstation fleet, patching, business services, '
          'and proven recovery.',
      'directory', [
    'dc01-dc02',
    'dns-configuration',
    'harden-baseline',
    'connect-segment',
    'tiered-admin',
    'logging-pipeline',
    'workstation-fleet',
    'patch-protect',
    'business-services',
    'prove-recovery',
  ]),
  TrainingCategory(
      'trust',
      'Certificates & Trust',
      'Connect an offline Root CA to your subordinate / issuing CA, then '
          'publish revocation data and certificate templates.',
      'risk',
      ['two-tier-pki', 'pki-services']),
  TrainingCategory(
      'authorization',
      'Network Authorization',
      'Apply the Risk Management Framework, assemble the Body of Evidence, '
          'and prepare an Authorization to Operate for the network you built.',
      'journal',
      ['rmf-boe-ato', 'rmf-body-of-evidence', 'rmf-authorization-to-operate']),
];

TrainingCategory categoryFor(LearningPath path) => trainingCategories.firstWhere(
    (category) => category.contains(path),
    orElse: () => TrainingCategory(
        path.category, path.category, path.subtitle, path.icon, [path.id]));
