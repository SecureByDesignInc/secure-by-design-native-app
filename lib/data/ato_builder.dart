/// The ATO Package Builder Hub (owner direction, 19 October 2026: the ATO
/// Package Builder is its own section; course 2.1 and the ATO Template Library
/// stay in the Training Hub). These mirror the website's
/// app/grc-rmf-training/package-builder-hub.tsx: keep the two in step.
library;

const atoBuilderUrl = 'https://securebydesigninc.com/grc-rmf-training/workspace';
const atoTemplatesUrl = 'https://securebydesigninc.com/grc-rmf-training/templates';
const rmfCourseId = 'rmf-boe-ato';

/// One of the seven RMF steps, the course 2.1 modules that teach it, and the
/// work the learner does for it in the package builder.
class RmfStep {
  const RmfStep(this.id, this.title, this.modules, this.task);
  final String id, title;
  final List<String> modules;
  final String task;

  String get moduleRange => modules.length == 1
      ? 'Module ${modules.first}'
      : 'Modules ${modules.first}–${modules.last}';

  /// The Network Authorization lessons for this step (training:rmf-boe-ato:01 …).
  List<String> get lessonIds =>
      [for (final module in modules) 'training:$rmfCourseId:$module'];

  /// The ATO Template Library has no Authorize section.
  bool get hasTemplates => id != 'authorize';
  String get templatesUrl => '$atoTemplatesUrl#$id';
}

const rmfSteps = [
  RmfStep('prepare', 'Prepare', ['01', '02'],
      'Register the Secure By Design enclave, describe it and its authorization boundary, and name everyone in an authorization role.'),
  RmfStep('categorize', 'Categorize', ['03'],
      'Add its information types, set the confidentiality, integrity and availability impacts, and explain the categorization.'),
  RmfStep('select', 'Select', ['04'],
      'Select the controls in scope from NIST SP 800-53 Rev. 5 and explain how they were chosen and tailored.'),
  RmfStep('implement', 'Implement', ['05', '06'],
      'Write an implementation statement for each control, link the evidence that proves it, and submit it to the assessor.'),
  RmfStep('assess', 'Assess', ['07', '08', '09'],
      'In the assessor’s seat, record a result for every assessment objective, validate or return each control, and plan every weakness in the POA&M.'),
  RmfStep('authorize', 'Authorize', ['10', '11'],
      'Write the executive summary and route the package through the ISSM, the assessor and the Authorizing Official to a decision.'),
  RmfStep('monitor', 'Monitor', ['12'],
      'Keep the authorization current: track the termination date, overdue POA&M milestones, changes, reassessments and the annual review.'),
];

/// What the builder keeps for a learner's enclave.
const builderKeeps = [
  ('System record and controls',
      'The enclave, its boundary, its roles, its categorization and the controls in scope.'),
  ('Body of Evidence',
      'Each control’s implementation statement and the evidence linked to it.'),
  ('POA&M', 'Every weakness from the assessment, with its milestones.'),
  ('Approval chain and decision',
      'The ISSM, assessor and Authorizing Official reviews, and the decision with its termination date.'),
  ('Continuous monitoring',
      'Termination dates, overdue milestones, changes, reassessments and the annual review.'),
];
