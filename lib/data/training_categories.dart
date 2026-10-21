import 'catalog.dart';
import 'models.dart';

export 'models.dart' show TrainingCategory;

/// The website's Training Hub categories, in its order (since 20 October 2026:
/// Build the Network, then Network Authorization). The app shows the same
/// groups as the website rather than its own.
List<TrainingCategory> get trainingCategories => currentCatalog.categories;

TrainingCategory categoryFor(LearningPath path) => trainingCategories.firstWhere(
    (category) => category.contains(path),
    orElse: () => TrainingCategory(path.categoryId, path.category, path.subtitle,
        icon: path.icon));

/// A category's courses in the website's order.
extension CategoryCourses on TrainingCategory {
  List<String> get pathIds =>
      publishedPaths.where(contains).map((path) => path.id).toList();
  List<ComingSoonCourse> get comingSoon => currentCatalog.comingSoon
      .where((course) => course.categoryId == id)
      .toList();
}
