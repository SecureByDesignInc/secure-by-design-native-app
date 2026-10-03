class LessonSection {
  const LessonSection(this.heading, this.body);
  final String heading;
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
}

class LearningPath {
  const LearningPath({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.lessons,
  });
  final String id;
  final String title;
  final String category;
  final String description;
  final String icon;
  final List<Lesson> lessons;
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
  });
  final String id;
  final String title;
  final String publisher;
  final String description;
  final String url;
  final String category;
  final String icon;
}
