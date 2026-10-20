import 'models.dart';
import 'published_catalog.dart';

const adSource =
    'https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview';
const rmfSource = 'https://csrc.nist.gov/projects/risk-management/about-rmf';
const splunkSource =
    'https://help.splunk.com/en/splunk-enterprise/get-started/overview/9.1/about-splunk-enterprise/about-splunk-enterprise';

const foundationResources = <LearningResource>[
  LearningResource(
    id: 'ms-ad',
    title: 'Active Directory fundamentals',
    publisher: 'Microsoft Learn',
    description: 'Read the official introduction to directory services.',
    url: adSource,
    category: 'Technology',
    icon: 'directory',
  ),
  LearningResource(
    id: 'nist-rmf',
    title: 'The Risk Management Framework',
    publisher: 'NIST',
    description: 'Explore the lifecycle and its supporting publications.',
    url: rmfSource,
    category: 'Risk & compliance',
    icon: 'risk',
  ),
  LearningResource(
    id: 'splunk',
    title: 'Explore Splunk Enterprise',
    publisher: 'Splunk',
    description: 'Connect data inputs, events, searches, and reports.',
    url: splunkSource,
    category: 'Technology',
    icon: 'monitoring',
  ),
  LearningResource(
    id: 'journal',
    title: 'Security Journal',
    publisher: 'Secure By Design',
    description: 'Keep exploring technical and compliance topics.',
    url: 'https://securebydesigninc.com/blogs',
    category: 'Secure By Design',
    icon: 'journal',
  ),
  LearningResource(
    id: 'career',
    title: 'Community · Career Goals & Support',
    publisher: 'Secure By Design',
    description: 'Explore your next step in cybersecurity.',
    // The careers forms are retired (website server/index.js); the worksheet lives here.
    url: 'https://securebydesigninc.com/career-goals',
    category: 'Secure By Design',
    icon: 'career',
  ),
  LearningResource(
    id: 'video',
    title: 'Watch the walkthroughs',
    publisher: 'Secure By Design · YouTube',
    description: 'Follow Jon’s explanations and practical demonstrations.',
    url: 'https://www.youtube.com/channel/UCItxo3KJms-IuQKdFzFXqRg',
    category: 'Secure By Design',
    icon: 'video',
  ),
];

/// The training catalog the app is showing: the one built into this release,
/// or a newer one the website published and [ContentFeed] verified on an
/// earlier launch. It changes only at startup, never under an open lesson.
class Catalog {
  const Catalog({
    required this.version,
    required this.categories,
    required this.paths,
    required this.comingSoon,
  });
  final String version;
  final List<TrainingCategory> categories;
  final List<LearningPath> paths;
  final List<ComingSoonCourse> comingSoon;
}

const bundledCatalog = Catalog(
    version: bundledCatalogVersion,
    categories: bundledCategories,
    paths: bundledPaths,
    comingSoon: bundledComingSoon);

Catalog _current = bundledCatalog;
Catalog get currentCatalog => _current;

/// Replaces the catalog. Call before the app's first frame (or in tests).
void useCatalog(Catalog catalog) => _current = catalog;

/// The website's courses, in Training Hub order.
List<LearningPath> get publishedPaths => _current.paths;

/// Every course the app can open. Since October 2026 that is exactly the
/// website's catalog: the app-only sample lessons were retired.
List<LearningPath> get learningPaths => _current.paths;

/// Official references first, then each course's materials once (a material
/// two courses share keeps one ID).
List<LearningResource> get resources => <LearningResource>[
  ...foundationResources.where((resource) => resource.id != 'journal'),
  ...{
    for (final path in publishedPaths)
      for (final material in path.materials) material.id: material
  }.values,
];
