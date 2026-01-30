class Organization {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final String status;
  final String? website;
  final String? contactEmail;
  final DateTime createdAt;

  Organization({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.status,
    this.website,
    this.contactEmail,
    required this.createdAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      status: json['status'],
      website: json['website'],
      contactEmail: json['contact_email'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
