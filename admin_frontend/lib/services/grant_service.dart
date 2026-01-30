import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:admin_frontend/models/grant.dart';
import 'package:admin_frontend/services/auth_services.dart';

class GrantService {
  final AuthService _authService = AuthService();
  // Use the same base URL as AuthService
  static const String baseUrl = AuthService.baseUrl; 

  // Fetch all grants (public)
  Future<List<Grant>> getGrants() async {
    // Public endpoint for verified grants only
    final endpoint = '/grants/public';
    
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _fromJson(json)).toList();
    } else {
      throw Exception('Failed to load grants: ${response.statusCode}');
    }
  }

  // Fetch all grants (admin only - includes unverified)
  Future<List<Grant>> getAllGrantsAdmin() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Authentication required');

    final response = await http.get(
      Uri.parse('$baseUrl/grants/admin/all'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _fromJson(json)).toList();
    } else {
      throw Exception('Failed to load admin grants: ${response.statusCode}');
    }
  }

  // Create a grant
  Future<Grant> createGrant(Grant grant) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Authentication required');

    final response = await http.post(
      Uri.parse('$baseUrl/grants/admin'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(_toJson(grant)),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create grant: ${response.body}');
    }
  }

  // Update a grant
  Future<Grant> updateGrant(Grant grant) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Authentication required');

    final response = await http.put(
      Uri.parse('$baseUrl/grants/admin/${grant.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(_toJson(grant)),
    );

    if (response.statusCode == 200) {
      return _fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update grant: ${response.body}');
    }
  }

  // Delete a grant
  Future<void> deleteGrant(String id) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Authentication required');

    final response = await http.delete(
      Uri.parse('$baseUrl/grants/admin/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete grant: ${response.body}');
    }
  }

  // Import grants from Grants.gov
  Future<Map<String, dynamic>> importFromGrantsGov() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Authentication required');

    final response = await http.post(
      Uri.parse('$baseUrl/grants/admin/import'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(minutes: 5)); // Long timeout for import

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to import grants: ${response.body}');
    }
  }

  // Helper methods to convert between Grant model and Backend JSON
  // Note: Backend JSON keys might differ slightly, adjusting here.
  Grant _fromJson(Map<String, dynamic> json) {
    return Grant(
      id: json['id'].toString(),
      title: json['title'],
      organizer: json['organizer'] ?? json['provider'] ?? 'Unknown',
      country: json['refugee_country'] ?? json['location'] ?? 'Unknown',
      category: _detectCategory(json['title'], json['description'], json['organizer']),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : DateTime.now().add(const Duration(days: 30)),
      amount: json['amount'] ?? '',
      description: json['description'] ?? '',
      eligibilityCriteria: json['eligibility_criteria'] != null 
          ? List<String>.from(json['eligibility_criteria']) 
          : (json['eligibility'] != null ? [json['eligibility']] : []),
      requiredDocuments: json['required_documents'] != null 
          ? List<String>.from(json['required_documents']) 
          : [],
      isVerified: json['is_verified'] ?? true, 
      isUrgent: false,
      applyUrl: json['apply_url'] ?? '',
    );
  }

  // Helper method to detect category from grant data
  String _detectCategory(String? title, String? description, String? organizer) {
    final text = '${title ?? ''} ${description ?? ''} ${organizer ?? ''}'.toLowerCase();
    
    if (text.contains('housing') || text.contains('shelter') || text.contains('accommodation')) {
      return 'Housing';
    } else if (text.contains('education') || text.contains('training') || text.contains('school') || text.contains('university')) {
      return 'Education';
    } else if (text.contains('health') || text.contains('medical') || text.contains('healthcare')) {
      return 'Healthcare';
    } else if (text.contains('employment') || text.contains('job') || text.contains('business') || text.contains('entrepreneur')) {
      return 'Employment';
    } else if (text.contains('legal') || text.contains('reunification') || text.contains('asylum')) {
      return 'Legal';
    } else if (text.contains('emergency') || text.contains('urgent') || text.contains('crisis')) {
      return 'Emergency';
    }
    
    return 'General';
  }

  Map<String, dynamic> _toJson(Grant grant) {
    return {
      'title': grant.title,
      'organizer': grant.organizer,
      'description': grant.description,
      'eligibility': grant.eligibilityCriteria.isNotEmpty 
          ? grant.eligibilityCriteria.join('; ') 
          : null,  // Convert list to text
      'amount': grant.amount,
      'deadline': grant.deadline.toIso8601String(),
      'refugee_country': grant.country,
      'apply_url': grant.applyUrl.isNotEmpty ? grant.applyUrl : 'https://example.com/apply',
      'eligibility_criteria': grant.eligibilityCriteria,
      'required_documents': grant.requiredDocuments,
      'is_verified': grant.isVerified,
      'is_active': true,
      'source': 'manual',
    };
  }
}
