import 'models.dart';
import 'published_catalog.dart';

const adSource =
    'https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview';
const rmfSource = 'https://csrc.nist.gov/projects/risk-management/about-rmf';
const splunkSource =
    'https://help.splunk.com/en/splunk-enterprise/get-started/overview/9.1/about-splunk-enterprise/about-splunk-enterprise';

const foundationPaths = <LearningPath>[
  LearningPath(
    id: 'ad',
    title: 'Active Directory, explained',
    category: 'Technology',
    description: 'Connect the dots between identities, computers, and access.',
    icon: 'directory',
    lessons: [
      Lesson(
        id: 'ad-1',
        title: 'What is Active Directory?',
        minutes: 3,
        summary: 'Start with the directory behind an enterprise network.',
        sections: [
          LessonSection(
            'A shared directory',
            'Active Directory Domain Services (AD DS) organizes information about users, computers, and shared resources. Authorized people and systems use that directory to find what they need.',
          ),
          LessonSection(
            'Picture the workplace',
            'Imagine a company with many employees and computers. A central directory gives administrators a consistent place to manage their identities.',
          ),
        ],
        question: 'What is the directory primarily organizing?',
        answers: [
          'User, computer, and resource information',
          'Only internet browsing history',
          'Only a list of installed apps',
        ],
        correctAnswer: 0,
        explanation:
            'AD DS stores directory objects, including user and computer accounts.',
        sourceUrl: adSource,
        sourceLabel: 'Microsoft Learn · AD DS overview',
      ),
      Lesson(
        id: 'ad-2',
        title: 'Meet the directory objects',
        minutes: 3,
        summary: 'Understand how an account represents a person or computer.',
        sections: [
          LessonSection(
            'Objects hold information',
            'A directory object represents something such as a user account, a computer account, or a shared resource. Its attributes describe that object.',
          ),
          LessonSection(
            'A practical question',
            'Before creating an account, ask what it represents and who should manage it. An object is a directory record, rather than the physical device itself.',
          ),
        ],
        question: 'A computer account in the directory is…',
        answers: [
          'The physical computer hardware',
          'A record representing the computer',
          'A copy of every file on the computer',
        ],
        correctAnswer: 1,
        explanation:
            'The account is a directory object that represents the computer.',
        sourceUrl: adSource,
        sourceLabel: 'Microsoft Learn · AD DS overview',
      ),
      Lesson(
        id: 'ad-3',
        title: 'Identity and access',
        minutes: 3,
        summary: 'Separate proving who you are from deciding what you can use.',
        sections: [
          LessonSection(
            'Two different questions',
            'Authentication establishes identity. Access control determines what an identity is allowed to use. AD DS integrates both into directory security.',
          ),
          LessonSection(
            'Try the distinction',
            'Think about entering an office: showing your badge establishes who you are. Permission to enter a specific room is a separate decision.',
          ),
        ],
        question: 'Which question is about access control?',
        answers: [
          'What is your name?',
          'Can you prove your identity?',
          'Are you allowed to open this resource?',
        ],
        correctAnswer: 2,
        explanation:
            'Access control determines the resources an identity may use.',
        sourceUrl: adSource,
        sourceLabel: 'Microsoft Learn · AD DS overview',
      ),
    ],
  ),
  LearningPath(
    id: 'monitoring',
    title: 'From logs to insight',
    category: 'Technology',
    description:
        'See how security monitoring turns activity into useful questions.',
    icon: 'monitoring',
    lessons: [
      Lesson(
        id: 'monitoring-1',
        title: 'Start with an event',
        minutes: 3,
        summary: 'Understand the activity recorded by a system.',
        sections: [
          LessonSection(
            'An activity record',
            'Systems produce machine data about their activity. Splunk can ingest that data and organize it into searchable events.',
          ),
          LessonSection(
            'A practice example',
            'Suppose a lab records a failed sign-in. Useful questions include when it happened, which account was involved, and which system recorded it. This example uses fictional lab activity.',
          ),
        ],
        question: 'What is a useful first question about an event?',
        answers: [
          'When and where did it happen?',
          'Can we assume it proves an attack?',
          'Should we delete it immediately?',
        ],
        correctAnswer: 0,
        explanation:
            'Start with context before drawing conclusions about an event.',
        sourceUrl: splunkSource,
        sourceLabel: 'Splunk · About Splunk Enterprise',
      ),
      Lesson(
        id: 'monitoring-2',
        title: 'Make data searchable',
        minutes: 3,
        summary: 'Understand the purpose of indexing.',
        sections: [
          LessonSection(
            'From input to search',
            'Splunk Enterprise processes incoming data into events and indexes it. Search lets people explore the indexed activity.',
          ),
          LessonSection(
            'Keep the question focused',
            'In your own lab, decide what you want to understand before choosing a data source. For example: which system recorded the sign-in attempt?',
          ),
        ],
        question: 'Why index incoming data?',
        answers: [
          'To make every event a confirmed incident',
          'To organize data for search',
          'To remove the need to investigate',
        ],
        correctAnswer: 1,
        explanation: 'Indexing helps organize the data so it can be searched.',
        sourceUrl: splunkSource,
        sourceLabel: 'Splunk · About Splunk Enterprise',
      ),
      Lesson(
        id: 'monitoring-3',
        title: 'Ask a better question',
        minutes: 3,
        summary: 'Use a monitoring question to guide the next step.',
        sections: [
          LessonSection(
            'Make a useful view',
            'Splunk supports searches, reports, and alerts to help people use indexed data. Their value depends on the question and the context.',
          ),
          LessonSection(
            'A learning exercise',
            'Compare a single failed sign-in with repeated failures across several accounts. Write down what additional context you would need before deciding how to respond.',
          ),
        ],
        question: 'What should guide a useful monitoring view?',
        answers: [
          'The largest possible number of charts',
          'Assuming every failure is malicious',
          'A clear question and relevant context',
        ],
        correctAnswer: 2,
        explanation:
            'A clear question helps you choose the information that matters.',
        sourceUrl: splunkSource,
        sourceLabel: 'Splunk · About Splunk Enterprise',
      ),
    ],
  ),
  LearningPath(
    id: 'rmf',
    title: 'Make sense of RMF',
    category: 'Risk & compliance',
    description:
        'Understand the decisions behind a risk-based security process.',
    icon: 'risk',
    lessons: [
      Lesson(
        id: 'rmf-1',
        title: 'Begin with the mission',
        minutes: 3,
        summary: 'Understand why a risk framework starts with context.',
        sections: [
          LessonSection(
            'Security has a purpose',
            'NIST’s Risk Management Framework (RMF) integrates security and privacy risk management into the system life cycle. The process starts with Prepare.',
          ),
          LessonSection(
            'A starting exercise',
            'Choose a fictional lab system. Write one sentence describing its purpose, the information it handles, and who is responsible for it.',
          ),
        ],
        question: 'Which RMF step comes first?',
        answers: ['Prepare', 'Authorize', 'Monitor'],
        correctAnswer: 0,
        explanation: 'Prepare establishes context for managing risk.',
        sourceUrl: rmfSource,
        sourceLabel: 'NIST · About the RMF',
      ),
      Lesson(
        id: 'rmf-2',
        title: 'Follow the seven steps',
        minutes: 3,
        summary: 'Connect the process from preparation to monitoring.',
        sections: [
          LessonSection(
            'The lifecycle',
            'The steps are Prepare, Categorize, Select, Implement, Assess, Authorize, and Monitor. They connect system context, controls, evidence, and risk decisions.',
          ),
          LessonSection(
            'Think about the handoff',
            'Implement puts controls in place and documents them. Assess evaluates whether those controls operate as intended.',
          ),
        ],
        question: 'Which step evaluates the implemented controls?',
        answers: ['Categorize', 'Assess', 'Select'],
        correctAnswer: 1,
        explanation:
            'Assess evaluates the controls and their intended results.',
        sourceUrl: rmfSource,
        sourceLabel: 'NIST · About the RMF',
      ),
      Lesson(
        id: 'rmf-3',
        title: 'Keep the picture current',
        minutes: 3,
        summary: 'See why monitoring continues after authorization.',
        sections: [
          LessonSection(
            'A continuing process',
            'Authorization is a risk-based decision by a senior official. Monitor keeps attention on control implementation and changing system risk.',
          ),
          LessonSection(
            'A practical connection',
            'For your fictional lab, name one change that could affect risk. Then name the evidence you would want to review after that change.',
          ),
        ],
        question: 'What is Monitor concerned with?',
        answers: [
          'Only the first day of installation',
          'Replacing every earlier step',
          'Control implementation and changing risk',
        ],
        correctAnswer: 2,
        explanation:
            'Monitoring helps keep the understanding of controls and risk current.',
        sourceUrl: rmfSource,
        sourceLabel: 'NIST · About the RMF',
      ),
    ],
  ),
];

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
    url: 'https://securebydesigninc.com/careers#goals',
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

const learningPaths = <LearningPath>[...publishedPaths, ...foundationPaths];

/// Official references first, then each course's materials once (a material
/// two courses share keeps one ID).
final resources = <LearningResource>[
  ...foundationResources.where((resource) => resource.id != 'journal'),
  ...{
    for (final path in publishedPaths)
      for (final material in path.materials) material.id: material
  }.values,
];
