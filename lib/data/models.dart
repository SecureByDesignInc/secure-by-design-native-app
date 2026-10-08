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
  });
  final String id;
  final String title;
  final String category;
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
