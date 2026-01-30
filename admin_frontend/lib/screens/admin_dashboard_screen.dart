import 'package:flutter/material.dart';
import 'package:admin_frontend/screens/grant_detail_screen.dart';
import '../theme/app_theme.dart';
import '../models/grant.dart';
import 'package:admin_frontend/screens/admin_login_screen.dart';
import 'package:admin_frontend/services/auth_services.dart';
import 'package:admin_frontend/services/grant_service.dart';
import 'package:intl/intl.dart';
import 'package:admin_frontend/screens/grant_editor_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0;
  List<Grant> _grants = [];
  List<Grant> _verifiedGrants = [];
  List<Grant> _unverifiedGrants = [];
  bool _isLoading = true;
  final GrantService _grantService = GrantService();

  @override
  void initState() {
    super.initState();
    _fetchGrants();
  }

  Future<void> _fetchGrants() async {
    setState(() => _isLoading = true);
    try {
      // Use admin method to get all grants including unverified ones
      final grants = await _grantService.getAllGrantsAdmin();
      print("DEBUG: Fetched ${grants.length} grants total");
      print("DEBUG: Verified: ${grants.where((g) => g.isVerified).length}");
      print("DEBUG: Unverified: ${grants.where((g) => !g.isVerified).length}");
      
      setState(() {
        _grants = grants;
        _verifiedGrants = grants.where((g) => g.isVerified).toList();
        _unverifiedGrants = grants.where((g) => !g.isVerified).toList();
        _isLoading = false;
      });
    } catch (e) {
      print("DEBUG: Error fetching grants: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading grants: $e')),
        );
      }
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await AuthService().logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _showGrantEditor([Grant? grant]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GrantEditorScreen(grant: grant)),
    );
    
    // Refresh if grant was saved (result == true)
    if (result == true) {
      _fetchGrants();
    }
  }

  Future<void> _importFromGrantsGov() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import from Grants.gov'),
        content: const Text('This will download and import grants from Grants.gov. This may take a few minutes. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Importing grants from Grants.gov...'),
            SizedBox(height: 8),
            Text('This may take a few minutes', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );

    try {
      await _grantService.importFromGrantsGov();
      
      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grants imported successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        _fetchGrants(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteGrant(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Grant?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _grantService.deleteGrant(id);
        _fetchGrants();
      } catch (e) {
         if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting grant: $e')),
            );
         }
      }
    }
  }

  Future<void> _verifyGrant(Grant grant) async {
    setState(() => _isLoading = true);
    try {
      final updatedGrant = Grant(
        id: grant.id,
        title: grant.title,
        organizer: grant.organizer,
        country: grant.country,
        category: grant.category,
        deadline: grant.deadline,
        amount: grant.amount,
        description: grant.description,
        eligibilityCriteria: grant.eligibilityCriteria,
        requiredDocuments: grant.requiredDocuments,
        isVerified: true, // Set to true
        isUrgent: grant.isUrgent,
        imageUrl: grant.imageUrl,
        applyUrl: grant.applyUrl,
      );

      await _grantService.updateGrant(updatedGrant);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grant verified successfully!'), backgroundColor: AppTheme.success),
        );
        _fetchGrants(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error verifying grant: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Header with slate gradient
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.adminGradient,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                children: [
                   Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.admin_panel_settings, color: AppTheme.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Dashboard',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.white,
                              ),
                            ),
                            Text(
                              'Manage grants',
                              style: TextStyle(fontSize: 12, color: AppTheme.white),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _importFromGrantsGov,
                        icon: const Icon(Icons.cloud_download, color: AppTheme.white),
                        tooltip: 'Import from Grants.gov',
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: AppTheme.white),
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.verified,
                          label: 'Verified',
                          value: '${_verifiedGrants.length}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.pending,
                          label: 'Unverified',
                          value: '${_unverifiedGrants.length}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Tab Bar
            Container(
              color: AppTheme.white,
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: 'Verified Grants',
                      icon: Icons.verified,
                      isSelected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      label: 'Unverified Grants',
                      icon: Icons.pending,
                      isSelected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 0 
                    ? _GrantsTab(
                        grants: _verifiedGrants, 
                        onEdit: _showGrantEditor,
                        onDelete: _deleteGrant,
                        onRefresh: _fetchGrants
                      ) 
                    : _GrantsTab(
                        grants: _unverifiedGrants, 
                        onEdit: _showGrantEditor,
                        onDelete: _deleteGrant,
                        onVerify: _verifyGrant, // Pass verify callback
                        onRefresh: _fetchGrants
                      ),
            ),
          ],
        ),
      ),
      
      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGrantEditor(null),
        backgroundColor: AppTheme.slateGray,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Grant', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppTheme.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.white, size: 24),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.white)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.white)),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.slateGray : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppTheme.slateGray : AppTheme.mediumGray),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.slateGray : AppTheme.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrantsTab extends StatelessWidget {
  final List<Grant> grants;
  final Function(Grant) onEdit;
  final Function(String) onDelete;
  final Function(Grant)? onVerify;
  final VoidCallback onRefresh;

  const _GrantsTab({
    required this.grants, 
    required this.onEdit, 
    required this.onDelete,
    this.onVerify,
    required this.onRefresh
  });

  @override
  Widget build(BuildContext context) {
    if (grants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No grants found'),
             TextButton(onPressed: onRefresh, child: const Text("Refresh"))
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount: grants.length,
        itemBuilder: (context, index) {
          final grant = grants[index];
          return Container(
            margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
            decoration: AppTheme.cardDecoration,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GrantDetailScreen(),
                    settings: RouteSettings(arguments: grant),
                  ),
                );
              },
              child: ListTile(
                contentPadding: const EdgeInsets.all(AppConstants.paddingMedium),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.adminGradient,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
                child: const Icon(Icons.description, color: AppTheme.white),
              ),
              title: Text(
                grant.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text("Provider: ${grant.organizer}"),
                  Text("Deadline: ${grant.formattedDeadline}"),
                   Text("Amount: ${grant.amount}", style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!grant.isVerified && onVerify != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: () => onVerify!(grant),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Verify'),
                      ),
                    ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: AppTheme.error),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppTheme.error)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') onEdit(grant);
                      if (value == 'delete') onDelete(grant.id);
                    },
                  ),
                ],
              ),
            ),
          ),
          );
        },
      ),
    );
  }
}
