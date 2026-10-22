class LessonSection {
  const LessonSection(this.heading, this.body);
  final String heading;
  final String body;
}

/// One knowledge check: a question, its answers, and why the answer is right.
class QuizQuestion {
  const QuizQuestion(
      this.question, this.answers, this.correctAnswer, this.explanation);
  final String question;
  final List<String> answers;
  final int correctAnswer;
  final String explanation;
}

/// The website's interactive course guide for one lesson: the checklist and
/// observations it keeps in the account (scripts/course-guide/renderer.js),
/// keyed by [chapter]. Lab mode reads and writes the same records.
class LessonGuide {
  const LessonGuide({
    required this.id,
    required this.chapter,
    this.checklist = const [],
    this.stepTitles = const [],
  });

  /// The guide's account record, `sbd-<course>`.
  final String id;

  /// The lesson's chapter in that guide; checks are `<chapter>-<index>`.
  final String chapter;
  final List<String> checklist;
  final List<String> stepTitles;
  String checkKey(int index) => '$chapter-$index';
}

/// One step of a lesson, as lab mode presents it.
class LabStep {
  const LabStep(this.title, this.body);
  final String title;
  final String body;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.minutes,
    required this.summary,
    required this.sections,
    required this.question,
    required this.answers,
    required this.correctAnswer,
    required this.explanation,
    required this.sourceUrl,
    required this.sourceLabel,
    this.youtubeId = '',
    this.objectives = const [],
    this.moreQuestions = const [],
    this.recap = const [],
    this.nextStep = '',
    this.guide,
  });
  final String id;
  final String title;
  final int minutes;
  final String summary;
  final List<LessonSection> sections;
  final String question;
  final List<String> answers;
  final int correctAnswer;
  final String explanation;
  final String sourceUrl;
  final String sourceLabel;

  /// YouTube video id for the lesson walkthrough; empty means text-only.
  final String youtubeId;
  bool get hasVideo => youtubeId.isNotEmpty;

  /// What the learner will be able to do after this lesson.
  final List<String> objectives;

  /// Knowledge checks after the first one ([question] … [explanation]).
  final List<QuizQuestion> moreQuestions;

  /// Key points to remember and the step that follows this lesson.
  final List<String> recap;
  final String nextStep;

  /// The website guide's checklist for this lesson, when it has one.
  final LessonGuide? guide;

  static final _stepHeading = RegExp(r'^Step (\d+)$');

  /// The numbered build steps, titled from the website guide where it names
  /// them, for lab mode's one-step-at-a-time view.
  List<LabStep> get labSteps {
    final steps = sections.where((s) => _stepHeading.hasMatch(s.heading)).toList();
    final titles = guide?.stepTitles ?? const <String>[];
    return [
      for (var i = 0; i < steps.length; i++)
        LabStep(i < titles.length && titles[i].isNotEmpty ? titles[i] : steps[i].heading,
            steps[i].body),
    ];
  }

  String _section(String heading) => sections
      .firstWhere((s) => s.heading == heading,
          orElse: () => const LessonSection('', ''))
      .body;

  /// The console (GUI) check, where the lesson has one (Site, 22 October 2026).
  String get labConsole => _section('Check it in the console');

  /// The commands that inspect the result, shown with a copy button. With a
  /// console check they are the optional command-line route.
  String get labCommands => _section('Inspect your configuration');
  String get labSuccess => _section('What success looks like');
  String get labEvidence => _section('Keep your evidence');

  /// Every knowledge check in order. All must be answered correctly to
  /// complete the lesson; rewards are still earned once per lesson.
  List<QuizQuestion> get questions => [
        QuizQuestion(question, answers, correctAnswer, explanation),
        ...moreQuestions,
      ];
}

class LearningPath {
  const LearningPath({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.lessons,
    this.subtitle = '',
    this.published = false,
    this.studyTime = '',
    this.topics = 0,
    this.materials = const [],
    this.number = '',
    this.trailerYoutubeId = '',
    this.categoryId = '',
  });
  final String id;
  final String title;
  final String category;

  /// The website's Training Hub category, such as `network-build`.
  final String categoryId;
  final String description;
  final String icon;
  final List<Lesson> lessons;
  final String subtitle;
  final bool published;
  final String studyTime;
  final int topics;
  final List<LearningResource> materials;
  final String number;

  /// YouTube video id for the course trailer; empty means no trailer yet.
  final String trailerYoutubeId;
  bool get hasTrailer => trailerYoutubeId.isNotEmpty;
  int get minutes => lessons.fold(0, (sum, lesson) => sum + lesson.minutes);
}

class LearningResource {
  const LearningResource({
    required this.id,
    required this.title,
    required this.publisher,
    required this.description,
    required this.url,
    required this.category,
    required this.icon,
    this.syncable = true,
  });
  final String id;
  final String title;
  final String publisher;
  final String description;
  final String url;
  final String category;
  final String icon;

  /// False when the website's bookmark catalog does not list this material
  /// yet. It can still be saved, but only on this device.
  final bool syncable;
}

/// A Training Hub category, with the website's ID, title and description.
class TrainingCategory {
  const TrainingCategory(this.id, this.title, this.description,
      {this.icon = 'directory'});
  final String id, title, description, icon;
  bool contains(LearningPath path) => path.categoryId == id;
}

/// A catalog tile the website labels "Coming soon": it has no lessons yet, so
/// the app shows it in its place and never opens it.
class ComingSoonCourse {
  const ComingSoonCourse({
    required this.id,
    required this.number,
    required this.title,
    required this.description,
    required this.categoryId,
    this.subtitle = '',
  });
  final String id, number, title, subtitle, description, categoryId;
}

/// A state page in the website's Community & Careers Hub.
class CommunityState {
  const CommunityState(this.code, this.name, this.slug);
  final String code, name, slug;
  String get url => 'https://securebydesigninc.com/community/$slug';
}
