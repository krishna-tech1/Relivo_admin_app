class Organization {
  final int id;
  final int? userId;
  final String name;
  final String? description;
  final String status;
  final String? website;
  final String? contactEmail;
  final String? country;
  final String? type;
  final DateTime createdAt;

  Organization({
    required this.id,
    this.userId,
    required this.name,
    this.description,
    required this.status,
    this.website,
    this.contactEmail,
    this.country,
    this.type,
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
      country: json['country'],
      type: json['type'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}
