enum LearningGoal {
  build('Build a network',
      'Connect Active Directory, DNS, and the systems they serve.'),
  authorize('Understand RMF & authorization',
      'Connect security decisions to evidence and an authorization package.'),
  monitor('Understand security monitoring',
      'Make sense of machine data and the questions it can answer.');

  const LearningGoal(this.label, this.description);
  final String label;
  final String description;
}

enum LearningStart {
  foundations('Start with the foundations',
      'Build understanding with a short, guided lesson.'),
  practical('I’m ready to apply it',
      'Start with a practical course where one is available.');

  const LearningStart(this.label, this.description);
  final String label;
  final String description;
}

/// Device-only choices. These never enter account sync or analytics payloads.
class OnboardingProfile {
  OnboardingProfile({required Set<LearningGoal> goals, required this.start})
      : goals = Set.unmodifiable(goals) {
    if (goals.isEmpty) {
      throw ArgumentError('Choose at least one learning goal.');
    }
  }

  final Set<LearningGoal> goals;
  final LearningStart start;

  List<String> get pathIds => [
        for (final goal in LearningGoal.values.where(goals.contains))
          switch (goal) {
            LearningGoal.build =>
              start == LearningStart.foundations ? 'ad' : 'dc01-dc02',
            LearningGoal.authorize =>
              start == LearningStart.foundations ? 'rmf' : 'rmf-boe-ato',
            LearningGoal.monitor => 'monitoring',
          }
      ];

  String get reason =>
      '${goals.map((g) => g.label).join(' · ')}. ${start.label}.';

  Map<String, Object> toJson() => {
        'goals': goals.map((g) => g.name).toList(),
        'start': start.name,
      };

  static OnboardingProfile? fromJson(Object? value) {
    if (value is! Map || value['goals'] is! List) return null;
    final goals = LearningGoal.values
        .where((g) => (value['goals'] as List).contains(g.name))
        .toSet();
    final starts = LearningStart.values.where((s) => s.name == value['start']);
    if (goals.isEmpty || starts.isEmpty) return null;
    return OnboardingProfile(goals: goals, start: starts.first);
  }
}
