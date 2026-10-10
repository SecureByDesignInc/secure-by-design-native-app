import 'models.dart';
import 'site_content.dart';

/// The published Training Library courses, as the website currently publishes
/// them (see [SiteContent]). The list changes when newer content arrives.
List<LearningPath> get publishedPaths => SiteContent.instance.paths;
