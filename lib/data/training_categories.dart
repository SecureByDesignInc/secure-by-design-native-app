import 'models.dart';

/// App presentation only. Course IDs and server progress groups stay stable.
class TrainingCategory {
  const TrainingCategory(this.id, this.title, this.description, this.icon,
      this.pathIds);
  final String id, title, description, icon;
  final List<String> pathIds;
  bool contains(LearningPath path) => pathIds.contains(path.id);
}

const trainingCategories = [
  TrainingCategory(
      'foundations',
      'Network Foundations',
      'Build the Windows Server, Active Directory, and DNS foundation.',
      'directory',
      ['dc01-dc02', 'dns-configuration']),
  TrainingCategory(
      'trust',
      'Certificates & Trust',
      'Connect an offline Root CA to your subordinate / issuing CA.',
      'risk',
      ['two-tier-pki']),
  TrainingCategory(
      'authorization',
      'Network Authorization',
      'Apply the Risk Management Framework, assemble the Body of Evidence, '
          'and prepare an Authorization to Operate for the network you built.',
      'journal',
      ['rmf-boe-ato']),
];

TrainingCategory categoryFor(LearningPath path) => trainingCategories.firstWhere(
    (category) => category.contains(path),
    orElse: () => TrainingCategory(
        path.category, path.category, path.subtitle, path.icon, [path.id]));
