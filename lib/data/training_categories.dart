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
/// courses keep the website's order (1.1, 1.2, … 1.19, then 2.1–2.3). The
/// website's coming-soon tiles (1.16 and 1.17) have no material and aren't in the app.
const trainingCategories = [
  TrainingCategory(
      'foundations',
      'Network Foundations',
      'Build the network one system at a time: the domain controllers, DNS, '
          'domain time, STIG measurement and Group Policy hardening, DHCP, '
          'tiered administration, the Linux repository, the logging pipeline, '
          'the workstation fleet, Windows updates, the living inventory, '
          'business services, and proven recovery.',
      'directory', [
    'dc01-dc02',
    'dns-configuration',
    'domain-time',
    'stig-scap',
    'harden-baseline',
    'dhcp',
    'tiered-admin',
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
      'trust',
      'Certificates & Trust',
      'Build the two-tier PKI: an offline Root CA, the issuing CA, the '
          'pki.sbd.test publication site, and certificate templates.',
      'risk',
      ['two-tier-pki']),
  TrainingCategory(
      'authorization',
      'Network Authorization',
      'Take the network you built through the Risk Management Framework steps '
          'of NIST SP 800-37, with the JSIG mapped in: prepare, categorize, and '
          'select; implement and assess; then authorize and monitor.',
      'journal',
      ['rmf-boe-ato', 'rmf-body-of-evidence', 'rmf-authorization-to-operate']),
];

TrainingCategory categoryFor(LearningPath path) => trainingCategories.firstWhere(
    (category) => category.contains(path),
    orElse: () => TrainingCategory(
        path.category, path.category, path.subtitle, path.icon, [path.id]));
