import 'package:flutter/material.dart';
import '../models/grant.dart';
import '../services/grant_service.dart';
import '../theme/app_theme.dart';
import '../widgets/grant_card.dart';
import 'grant_editor_screen.dart';
import 'grant_detail_screen.dart';

class MyGrantsScreen extends StatefulWidget {
  const MyGrantsScreen({super.key});

  @override
  State<MyGrantsScreen> createState() => _MyGrantsScreenState();
}

class _MyGrantsScreenState extends State<MyGrantsScreen> {
  final _grantService = GrantService();
  List<Grant> _myGrants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyGrants();
  }

  Future<void> _fetchMyGrants() async {
    setState(() => _isLoading = true);
    try {
      final grants = await _grantService.getMyGrants();
      if (mounted) {
        setState(() {
          _myGrants = grants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load my grants: $e')),
        );
      }
    }
  }

  Future<void> _deleteGrant(String id) async {
    try {
      await _grantService.deleteMyGrant(id);
      _fetchMyGrants(); // Refresh
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grant deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete grant: $e')),
        );
      }
    }
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Grant?'),
        content: const Text('Are you sure you want to delete this submission?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGrant(id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: const Text('My Submissions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: AppTheme.darkGray,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppTheme.darkGray),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GrantEditorScreen(isUserSubmission: true),
            ),
          );
          if (result == true) _fetchMyGrants();
        },
        label: const Text('New Grant'),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myGrants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 64, color: AppTheme.mediumGray.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No submissions yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.mediumGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Submit a grant to help the community!',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.mediumGray.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.paddingLarge),
                  itemCount: _myGrants.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                  itemBuilder: (ctx, index) {
                    final grant = _myGrants[index];
                    return Stack(
                      children: [
                        GrantCard(
                          grant: grant,
                          onTap: () async {
                            if (!grant.isVerified) {
                              // Allow edit if not verified
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GrantEditorScreen(
                                    grant: grant,
                                    isUserSubmission: true,
                                  ),
                                ),
                              );
                              if (result == true) _fetchMyGrants();
                            } else {
                              // View only
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GrantDetailScreen(),
                                  settings: RouteSettings(arguments: grant),
                                ),
                              );
                            }
                          },
                        ),
                        // Delete Button for unverified grants
                        if (!grant.isVerified)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDelete(grant.id),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
    );
  }
}
