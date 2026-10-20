import 'catalog.dart';
import 'models.dart';

/// Reads the catalog the website publishes at /app-content/v1/catalog.json
/// (scripts/prepare-app-content.mjs in the website repository). Anything
/// unexpected throws [FormatException], so a damaged or incompatible download
/// is rejected whole and the app keeps the catalog it already has.
Catalog parseCatalogJson(Object? json, {required String version}) {
  final root = _map(json, 'catalog');
  if (root['schema'] != 1) throw const FormatException('Unsupported catalog schema');
  final categories = [
    for (final c in _list(root['categories'], 'categories'))
      _category(_map(c, 'category')),
  ];
  final paths = [
    for (final c in _list(root['courses'], 'courses')) _course(_map(c, 'course')),
  ];
  final comingSoon = [
    for (final c in _list(root['comingSoon'], 'comingSoon'))
      _comingSoon(_map(c, 'coming-soon course')),
  ];
  if (paths.isEmpty) throw const FormatException('The catalog has no courses');
  final ids = <String>{};
  for (final path in paths) {
    if (!categories.any((c) => c.contains(path))) {
      throw FormatException('No category for ${path.id}');
    }
    for (final lesson in path.lessons) {
      if (!ids.add(lesson.id)) throw FormatException('Duplicate lesson ${lesson.id}');
    }
  }
  return Catalog(
      version: version,
      categories: List.unmodifiable(categories),
      paths: List.unmodifiable(paths),
      comingSoon: List.unmodifiable(comingSoon));
}

Map<String, dynamic> _map(Object? value, String what) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('Expected an object for $what');
}

List<dynamic> _list(Object? value, String what) {
  if (value is List<dynamic>) return value;
  throw FormatException('Expected a list for $what');
}

String _text(Map<String, dynamic> map, String key, {bool required = true}) {
  final value = map[key];
  if (value is String && (value.isNotEmpty || !required)) return value;
  if (value == null && !required) return '';
  throw FormatException('Expected text for $key');
}

int _int(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is int && value >= 0) return value;
  throw FormatException('Expected a whole number for $key');
}

List<String> _strings(Object? value, String what) =>
    [for (final item in _list(value ?? const <dynamic>[], what))
      if (item is String) item else throw FormatException('Expected text in $what')];

final _iconKeys = {'directory', 'monitoring', 'risk', 'journal', 'career', 'video'};
String _icon(String value) => _iconKeys.contains(value) ? value : 'directory';

TrainingCategory _category(Map<String, dynamic> c) {
  final id = _text(c, 'id');
  return TrainingCategory(id, _text(c, 'title'), _text(c, 'description'),
      icon: id == 'network-authorization' ? 'journal' : 'directory');
}

ComingSoonCourse _comingSoon(Map<String, dynamic> c) => ComingSoonCourse(
    id: _text(c, 'id'),
    number: _text(c, 'number'),
    title: _text(c, 'title'),
    subtitle: _text(c, 'subtitle', required: false),
    description: _text(c, 'description'),
    categoryId: _text(c, 'categoryId'));

LearningResource _material(Map<String, dynamic> r) {
  final url = _text(r, 'url');
  if (Uri.tryParse(url)?.scheme != 'https') {
    throw const FormatException('Materials must use secure links');
  }
  return LearningResource(
      id: _text(r, 'id'),
      title: _text(r, 'title'),
      publisher: _text(r, 'publisher'),
      description: _text(r, 'description'),
      url: url,
      category: _text(r, 'category'),
      icon: _icon(_text(r, 'icon')),
      syncable: r['syncable'] != false);
}

QuizQuestion _question(Map<String, dynamic> q) {
  final answers = _strings(q['answers'], 'answers');
  final correct = q['correct'];
  if (answers.length < 2 || correct is! int || correct < 0 || correct >= answers.length) {
    throw const FormatException('Invalid knowledge check');
  }
  return QuizQuestion(_text(q, 'question'), answers, correct, _text(q, 'explanation'));
}

final _youtubeId = RegExp(r'^[A-Za-z0-9_-]{11}$');
String _video(Map<String, dynamic> map, String key) {
  final id = _text(map, key, required: false);
  if (id.isEmpty || _youtubeId.hasMatch(id)) return id;
  throw FormatException('Invalid video ID for $key');
}

Lesson _lesson(Map<String, dynamic> l) {
  final quizzes = [
    for (final q in _list(l['quizzes'], 'quizzes')) _question(_map(q, 'quiz')),
  ];
  if (quizzes.isEmpty) throw const FormatException('A lesson needs a knowledge check');
  final first = quizzes.first;
  final guide = l['guide'] == null ? null : _map(l['guide'], 'guide');
  final source = _text(l, 'source');
  if (Uri.tryParse(source)?.scheme != 'https') {
    throw const FormatException('Lessons must link to a secure guide');
  }
  return Lesson(
      id: _text(l, 'id'),
      title: _text(l, 'title'),
      minutes: _int(l, 'minutes'),
      summary: _text(l, 'summary'),
      objectives: _strings(l['objectives'], 'objectives'),
      sections: [
        for (final s in _list(l['sections'], 'sections'))
          LessonSection(_text(_map(s, 'section'), 'heading'),
              _text(_map(s, 'section'), 'body', required: false)),
      ],
      question: first.question,
      answers: first.answers,
      correctAnswer: first.correctAnswer,
      explanation: first.explanation,
      moreQuestions: quizzes.skip(1).toList(),
      recap: _strings(l['recap'], 'recap'),
      nextStep: _text(l, 'next', required: false),
      youtubeId: _video(l, 'youtubeId'),
      guide: guide == null
          ? null
          : LessonGuide(
              id: _text(guide, 'id'),
              chapter: _text(guide, 'chapter'),
              checklist: _strings(guide['checklist'], 'checklist'),
              stepTitles: _strings(guide['stepTitles'], 'stepTitles')),
      sourceUrl: source,
      sourceLabel: 'Open the complete guide');
}

LearningPath _course(Map<String, dynamic> c) => LearningPath(
    id: _text(c, 'id'),
    number: _text(c, 'number', required: false),
    title: _text(c, 'title'),
    subtitle: _text(c, 'subtitle', required: false),
    category: _text(c, 'category'),
    categoryId: _text(c, 'categoryId'),
    description: _text(c, 'description'),
    icon: _icon(_text(c, 'icon')),
    published: true,
    studyTime: _text(c, 'studyTime', required: false),
    topics: _int(c, 'topics'),
    trailerYoutubeId: _video(c, 'trailerYoutubeId'),
    materials: [
      for (final r in _list(c['materials'], 'materials')) _material(_map(r, 'material')),
    ],
    lessons: [
      for (final l in _list(c['lessons'], 'lessons')) _lesson(_map(l, 'lesson')),
    ]);
