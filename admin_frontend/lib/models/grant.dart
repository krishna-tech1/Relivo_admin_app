class Grant {
  final String id;
  final String title;
  final String organizer;
  final String country;
  final String category;
  final DateTime deadline;
  final String amount;
  final String description;
  final List<String> eligibilityCriteria;
  final List<String> requiredDocuments;
  final bool isVerified;
  final bool isUrgent;
  final String imageUrl;
  final String applyUrl;

  Grant({
    required this.id,
    required this.title,
    required this.organizer,
    required this.country,
    required this.category,
    required this.deadline,
    required this.amount,
    required this.description,
    required this.eligibilityCriteria,
    required this.requiredDocuments,
    this.isVerified = false,
    this.isUrgent = false,
    this.imageUrl = '',
    this.applyUrl = '',
  });

  // Check if deadline is approaching (within 7 days)
  bool get hasUpcomingDeadline {
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    return difference <= 7 && difference >= 0;
  }

  // Format deadline for display
  String get formattedDeadline {
    return '${deadline.day}/${deadline.month}/${deadline.year}';
  }
}

// Sample data for demonstration
class GrantData {
  static List<Grant> sampleGrants = [
    Grant(
      id: '1',
      title: 'Emergency Housing Assistance',
      organizer: 'UN Refugee Agency',
      country: 'Germany',
      category: 'Housing',
      deadline: DateTime(2026, 2, 15),
      amount: '€5,000',
      description: 'Financial assistance for refugees seeking emergency housing solutions. This grant covers rent deposits, first month\'s rent, and essential furniture.',
      eligibilityCriteria: [
        'Must have valid refugee status',
        'Currently without permanent housing',
        'Residing in Germany for less than 6 months',
        'Income below €1,500/month',
      ],
      requiredDocuments: [
        'Valid refugee ID or asylum seeker certificate',
        'Proof of current housing situation',
        'Income statement or unemployment certificate',
        'Bank account details',
      ],
      isVerified: true,
      isUrgent: true,
      applyUrl: 'https://example.com/apply',
    ),
    Grant(
      id: '2',
      title: 'Education & Training Grant',
      organizer: 'European Education Foundation',
      country: 'France',
      category: 'Education',
      deadline: DateTime(2026, 3, 30),
      amount: '€3,500',
      description: 'Support for refugees pursuing education, vocational training, or professional certification programs.',
      eligibilityCriteria: [
        'Valid refugee or asylum seeker status',
        'Enrolled or accepted in an educational program',
        'Age 18-35',
        'Basic language proficiency',
      ],
      requiredDocuments: [
        'Refugee status documentation',
        'Acceptance letter from educational institution',
        'Academic transcripts (if available)',
        'Language proficiency certificate',
      ],
      isVerified: true,
      isUrgent: false,
      applyUrl: 'https://example.com/apply',
    ),
    Grant(
      id: '3',
      title: 'Healthcare Support Fund',
      organizer: 'International Medical Corps',
      country: 'Sweden',
      category: 'Healthcare',
      deadline: DateTime(2026, 2, 28),
      amount: '€2,000',
      description: 'Medical assistance for refugees requiring healthcare services not covered by standard insurance.',
      eligibilityCriteria: [
        'Refugee or asylum seeker status',
        'Medical need not covered by insurance',
        'Residing in Sweden',
        'Income below poverty threshold',
      ],
      requiredDocuments: [
        'Medical documentation',
        'Refugee status proof',
        'Insurance coverage details',
        'Doctor\'s recommendation letter',
      ],
      isVerified: true,
      isUrgent: true,
      applyUrl: 'https://example.com/apply',
    ),
    Grant(
      id: '4',
      title: 'Small Business Startup Grant',
      organizer: 'Refugee Entrepreneurship Network',
      country: 'Netherlands',
      category: 'Employment',
      deadline: DateTime(2026, 4, 15),
      amount: '€8,000',
      description: 'Funding for refugees looking to start their own small business or social enterprise.',
      eligibilityCriteria: [
        'Valid refugee status',
        'Business plan required',
        'Minimum 1 year residence in Netherlands',
        'Completed entrepreneurship training',
      ],
      requiredDocuments: [
        'Detailed business plan',
        'Refugee status certificate',
        'Proof of residence',
        'Training completion certificate',
        'Financial projections',
      ],
      isVerified: true,
      isUrgent: false,
      applyUrl: 'https://example.com/apply',
    ),
    Grant(
      id: '5',
      title: 'Family Reunification Support',
      organizer: 'Red Cross International',
      country: 'Belgium',
      category: 'Legal',
      deadline: DateTime(2026, 3, 10),
      amount: '€4,500',
      description: 'Legal and financial assistance for family reunification processes.',
      eligibilityCriteria: [
        'Recognized refugee status',
        'Family members in conflict zones',
        'Active reunification case',
        'Financial need demonstrated',
      ],
      requiredDocuments: [
        'Refugee status documentation',
        'Family relationship proof',
        'Legal case documentation',
        'Financial need assessment',
      ],
      isVerified: true,
      isUrgent: true,
      applyUrl: 'https://example.com/apply',
    ),
  ];

  static List<String> categories = [
    'All Categories',
    'Housing',
    'Education',
    'Healthcare',
    'Employment',
    'Legal',
    'Emergency',
  ];

  static List<String> countries = [
    'All Countries',
    'Germany',
    'France',
    'Sweden',
    'Netherlands',
    'Belgium',
    'Austria',
    'Denmark',
    'Norway',
  ];
}
