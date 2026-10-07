import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_by_design_app/data/learning_store.dart';
import 'package:secure_by_design_app/data/models.dart';
import 'package:secure_by_design_app/screens/course_screen.dart';
import 'package:secure_by_design_app/screens/path_screen.dart';
import 'package:secure_by_design_app/theme.dart';
import 'package:secure_by_design_app/widgets/lesson_video.dart';

Lesson _lesson({String youtubeId = ''}) => Lesson(
      id: 'test:video-lesson',
      title: 'Watch the DNS flow',
      minutes: 5,
      summary: 'A short walkthrough of the lesson.',
      sections: const [LessonSection('One idea', 'The idea, explained.')],
      question: 'Ready?',
      answers: const ['Yes', 'No'],
      correctAnswer: 0,
      explanation: 'Correct.',
      sourceUrl: 'https://securebydesigninc.com/training',
      sourceLabel: 'Secure By Design training',
      youtubeId: youtubeId,
    );

LearningPath _path(Lesson lesson, {String trailerYoutubeId = ''}) =>
    LearningPath(
      id: 'test-video-path',
      title: 'Video path',
      category: 'Network build',
      description: 'A test path.',
      icon: 'video',
      lessons: [lesson],
      subtitle: 'Testing the video layer',
      studyTime: '1 short lesson',
      trailerYoutubeId: trailerYoutubeId,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a lesson with a video shows the artwork-first player',
      (tester) async {
    final store = await LearningStore.load();
    addTearDown(store.dispose);
    final lesson = _lesson(youtubeId: 'VIDEO1234ab');
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: LessonScreen(
            store: store, lesson: lesson, path: _path(lesson))));
    await tester.pumpAndSettle();
    expect(find.byType(LessonVideo), findsOneWidget);
    expect(find.byKey(const ValueKey('play-VIDEO1234ab')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a text-only lesson keeps the reading experience unchanged',
      (tester) async {
    final store = await LearningStore.load();
    addTearDown(store.dispose);
    final lesson = _lesson();
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: LessonScreen(
            store: store, lesson: lesson, path: _path(lesson))));
    await tester.pumpAndSettle();
    expect(find.byType(LessonVideo), findsNothing);
    expect(find.text('One idea'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a course with a trailer leads its overview with the video',
      (tester) async {
    final store = await LearningStore.load();
    addTearDown(store.dispose);
    final lesson = _lesson();
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: CourseScreen(
            store: store,
            path: _path(lesson, trailerYoutubeId: 'TRAILER123a'))));
    await tester.pumpAndSettle();
    expect(find.byType(LessonVideo), findsOneWidget);
    expect(find.text('COURSE TRAILER'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a course without a trailer shows no video block',
      (tester) async {
    final store = await LearningStore.load();
    addTearDown(store.dispose);
    final lesson = _lesson();
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: CourseScreen(store: store, path: _path(lesson))));
    await tester.pumpAndSettle();
    expect(find.byType(LessonVideo), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
