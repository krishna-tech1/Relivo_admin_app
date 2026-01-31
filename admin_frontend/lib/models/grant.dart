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
  final DateTime? createdAt;
  final int? creatorId;
  final int? organizationId;
  final String? creatorRole;
  final String source;

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
    this.createdAt,
    this.creatorId,
    this.organizationId,
    this.creatorRole,
    this.source = 'manual',
  });

  // Check if deadline is approaching (within 7 days)
  bool get hasUpcomingDeadline {
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    return difference <= 7 && difference >= 0;
  }

  // Check if it's expired
  bool get isExpired {
    return deadline.isBefore(DateTime.now());
  }

  // Check the creator type
  String get creatorType {
    if (source == 'grants.gov') return 'External';
    if (organizationId != null) return 'Organization';
    
    // Check if we have the explicit role from backend
    if (creatorRole == 'admin') return 'Admin';
    if (creatorRole == 'user') return 'User';
    
    // Fallback to ID-based logic if role is missing
    if (creatorId == 1) return 'Admin';
    if (creatorId != null && creatorId != 1) return 'User';
    
    // Default fallback for manual grants
    return 'Admin'; 
  }

  // Format deadline for display
  String get formattedDeadline {
    return '${deadline.day}/${deadline.month}/${deadline.year}';
  }

  // Format relative time for created_at
  String get relativeCreatedAt {
    if (createdAt == null) return 'N/A';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}
