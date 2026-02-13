import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_frontend/screens/grant_detail_screen.dart';
import 'package:admin_frontend/screens/admin_insights_screen.dart';
import 'package:admin_frontend/screens/organization_detail_screen.dart';
import '../theme/app_theme.dart';
import '../models/grant.dart';
import '../models/organization.dart';
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
  List<Grant> _allGrants = []; 
  List<Grant> _verifiedGrants = [];
  List<Grant> _unverifiedGrants = [];
  List<Organization> _organizations = [];
  
  // Search state
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Grant> _filteredVerifiedGrants = [];
  List<Grant> _filteredUnverifiedGrants = [];
  List<Organization> _filteredOrganizations = [];

  bool _isLoading = true;
  final GrantService _grantService = GrantService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      if (_selectedTab == 0 || _selectedTab == 1) {
        await _fetchGrants();
      }
      
      if (_selectedTab == 2) {
        await _fetchOrganizations();
      }
      
      _applySearch(); 
    } catch (e) {
      _showError('Error refreshing data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchGrants() async {
    try {
      final grants = await _grantService.getAllGrantsAdmin();
      if (mounted) {
        setState(() {
          _allGrants = grants;
          _verifiedGrants = grants.where((g) => g.isVerified).toList();
          _unverifiedGrants = grants.where((g) => !g.isVerified).toList();
        });
      }
    } catch (e) {
      _showError('Error loading grants: $e');
    }
  }

  Future<void> _fetchOrganizations() async {
    try {
      final orgData = await _authService.getOrganizations();
      if (mounted) {
        setState(() {
          _organizations = orgData.map((e) => Organization.fromJson(e)).toList();
        });
      }
    } catch (e) {
      _showError('Error loading organizations: $e');
    }
  }

  void _applySearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredVerifiedGrants = _verifiedGrants;
        _filteredUnverifiedGrants = _unverifiedGrants;
        _filteredOrganizations = _organizations;
      } else {
        _filteredVerifiedGrants = _verifiedGrants
            .where((g) => g.title.toLowerCase().contains(query) || g.organizer.toLowerCase().contains(query))
            .toList();
        _filteredUnverifiedGrants = _unverifiedGrants
            .where((g) => g.title.toLowerCase().contains(query) || g.organizer.toLowerCase().contains(query))
            .toList();
        _filteredOrganizations = _organizations
            .where((o) => o.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppTheme.error),
      );
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
              Navigator.pop(context);
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
    if (result == true) {
      _refreshData();
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
        _refreshData();
      } catch (e) {
        _showError('Error deleting grant: $e');
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
        isVerified: true,
        isUrgent: grant.isUrgent,
        imageUrl: grant.imageUrl,
        applyUrl: grant.applyUrl,
        createdAt: grant.createdAt,
        creatorId: grant.creatorId,
        organizationId: grant.organizationId,
        source: grant.source,
      );

      await _grantService.updateGrant(updatedGrant);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grant verified successfully!'), backgroundColor: AppTheme.success),
        );
        _refreshData();
      }
    } catch (e) {
      _showError('Error verifying grant: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrgStatus(Organization org, String status) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == 'approved' ? 'Approve Organization?' : 'Reject Organization?'),
        content: Text(
          status == 'approved'
              ? 'This will send an approval email with login credentials to ${org.contactEmail}. Continue?'
              : 'This will send a rejection notification email to ${org.contactEmail}. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: status == 'approved' ? AppTheme.success : AppTheme.error,
            ),
            child: Text(status == 'approved' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      if (status == 'approved') {
        await _authService.approveOrganization(org.id);
      } else if (status == 'rejected') {
        await _authService.rejectOrganization(org.id);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved' 
                  ? 'Organization approved! Email sent to ${org.contactEmail}'
                  : 'Organization rejected. Notification sent to ${org.contactEmail}'
            ),
            backgroundColor: status == 'approved' ? AppTheme.success : AppTheme.error,
          ),
        );
        _refreshData();
      }
    } catch (e) {
      _showError('Error updating organization: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppTheme.secondaryColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.offWhite,
        body: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.adminGradient,
                boxShadow: [
                  BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 4)),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                AppConstants.paddingLarge, 
                MediaQuery.of(context).padding.top + 20, 
                AppConstants.paddingLarge, 
                AppConstants.paddingLarge
              ),
              child: Column(
                children: [
                  if (!_isSearching)
                    Row(
                      children: [
                        const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.white, size: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'RELIVO ADMIN',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.white,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await _fetchGrants();
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AdminInsightsScreen(
                                  grants: _allGrants,
                                  onRefresh: _refreshData,
                                )),
                              );
                            }
                          },
                          icon: const Icon(Icons.analytics_rounded, color: AppTheme.white, size: 22),
                          tooltip: 'Insights',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => _isSearching = true);
                          },
                          icon: const Icon(Icons.search_rounded, color: AppTheme.white, size: 22),
                          tooltip: 'Search',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                        PopupMenuButton<String>(
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.more_vert_rounded, color: AppTheme.white, size: 22),
                          onSelected: (value) {
                            if (value == 'logout') {
                              _logout();
                            } else if (value == 'settings') {
                              // Add settings logic
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'settings',
                              child: Row(
                                children: [
                                  Icon(Icons.settings_rounded, size: 20),
                                  SizedBox(width: 12),
                                  Text('Settings'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout_rounded, size: 20, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text('Logout', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isSearching = false;
                              _searchController.clear();
                              _applySearch();
                            });
                          },
                          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.white),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            cursorColor: AppTheme.white,
                            style: GoogleFonts.inter(color: AppTheme.white, fontSize: 18),
                            decoration: const InputDecoration(
                              hintText: 'Search...',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                              filled: false,
                            ),
                            onChanged: (_) => _applySearch(),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _applySearch();
                          },
                          icon: const Icon(Icons.close_rounded, color: AppTheme.white),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                
                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.verified_rounded,
                          label: 'VERIFIED',
                          value: '${_verifiedGrants.length}',
                          color: AppTheme.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.pending_actions_rounded,
                          label: 'PENDING',
                          value: '${_unverifiedGrants.length}',
                          color: AppTheme.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.business_center_rounded,
                          label: 'ORGS',
                          value: '${_organizations.length}',
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: AppTheme.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  _buildTab(0, 'Verified', Icons.verified_user_rounded),
                  _buildTab(1, 'Unverified', Icons.pending_rounded),
                  _buildTab(2, 'Organizations', Icons.business_rounded),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : IndexedStack(
                    index: _selectedTab,
                    children: [
                      _GrantsTab(
                        grants: _filteredVerifiedGrants, 
                        onEdit: _showGrantEditor,
                        onDelete: _deleteGrant,
                        onRefresh: _refreshData,
                        onGrantTap: (grant) async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GrantDetailScreen(showApplyButton: false),
                              settings: RouteSettings(arguments: grant),
                            ),
                          );
                          if (result == true) _refreshData();
                        },
                      ),
                      _GrantsTab(
                        grants: _filteredUnverifiedGrants, 
                        onEdit: _showGrantEditor,
                        onDelete: _deleteGrant,
                        onVerify: _verifyGrant,
                        onRefresh: _refreshData,
                        onGrantTap: (grant) async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GrantDetailScreen(showApplyButton: false),
                              settings: RouteSettings(arguments: grant),
                            ),
                          );
                          if (result == true) _refreshData();
                        },
                      ),
                      _OrganizationsTab(
                        organizations: _filteredOrganizations,
                        onStatusUpdate: _updateOrgStatus,
                        onRefresh: _refreshData,
                      ),
                    ],
                  ),
            ),
          ],
        ),
        floatingActionButton: (_selectedTab == 0 || _selectedTab == 1) ? FloatingActionButton(
          onPressed: () => _showGrantEditor(null),
          backgroundColor: AppTheme.secondaryColor,
          elevation: 4,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ) : null,
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = index;
            _applySearch(); 
          });
          _refreshData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon, 
                  color: isSelected ? AppTheme.primaryColor : AppTheme.mediumGray.withOpacity(0.4), 
                  size: 26
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.mediumGray.withOpacity(0.5),
                  letterSpacing: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon, 
    required this.label, 
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value, 
            style: GoogleFonts.inter(
              fontSize: 22, 
              fontWeight: FontWeight.w900, 
              color: Colors.white,
            ), 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis
          ),
          Text(
            label, 
            style: GoogleFonts.inter(
              fontSize: 9, 
              fontWeight: FontWeight.w700,
              color: Colors.white70,
              letterSpacing: 1.2,
            ), 
            overflow: TextOverflow.ellipsis, 
            maxLines: 1
          ),
        ],
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
  final Function(Grant) onGrantTap;

  const _GrantsTab({
    required this.grants, 
    required this.onEdit, 
    required this.onDelete,
    this.onVerify,
    required this.onRefresh,
    required this.onGrantTap,
  });

  @override
  Widget build(BuildContext context) {
    if (grants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: AppTheme.mediumGray.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('No grants found', style: TextStyle(fontSize: 16, color: AppTheme.mediumGray)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRefresh, 
              child: const Text("REFRESH NOW", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: grants.length,
        itemBuilder: (context, index) {
          final grant = grants[index];
          return Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: ListTile(
                  onTap: () => onGrantTap(grant),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.description_rounded, color: AppTheme.primaryColor),
                  ),
                  title: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(grant.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${grant.organizer}", style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 12, color: AppTheme.mediumGray),
                            const SizedBox(width: 4),
                            Text("Deadline: ${grant.formattedDeadline}", style: const TextStyle(fontSize: 11, color: AppTheme.mediumGray)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  isThreeLine: true,
                  trailing: SizedBox(
                    width: onVerify != null ? 70 : 35,
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        Positioned(
                          right: 0,
                          child: PopupMenuButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.more_vert_rounded, size: 22, color: AppTheme.mediumGray),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            itemBuilder: (context) => [
                              if (grant.creatorType != 'Organization')
                                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('Edit')])),
                              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                            ],
                            onSelected: (val) {
                              if (val == 'edit') onEdit(grant);
                              if (val == 'delete') onDelete(grant.id);
                            },
                          ),
                        ),
                        if (onVerify != null)
                          Positioned(
                            right: 30,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 24),
                              onPressed: () => onVerify!(grant),
                              tooltip: 'Verify Grant',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 45, // Adjusted to not overlap with menu
                child: AppTheme.buildCreatorBadge(grant.creatorType),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrganizationsTab extends StatelessWidget {
  final List<Organization> organizations;
  final Function(Organization, String) onStatusUpdate;
  final VoidCallback onRefresh;

  const _OrganizationsTab({
    required this.organizations,
    required this.onStatusUpdate,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (organizations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: AppTheme.mediumGray.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('No organizations found', style: TextStyle(fontSize: 16, color: AppTheme.mediumGray)),
            TextButton(onPressed: onRefresh, child: const Text("REFRESH NOW")),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: organizations.length,
        itemBuilder: (context, index) {
          final org = organizations[index];
          final statusColor = _getStatusColor(org.status);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrganizationDetailScreen(organization: org),
                  ),
                );
                if (result == true) {
                  onRefresh();
                }
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: statusColor.withOpacity(0.1),
                child: Icon(Icons.business_rounded, color: statusColor, size: 24),
              ),
              title: Text(
                org.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        org.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        org.contactEmail ?? 'No email',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppTheme.mediumGray),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return AppTheme.success;
      case 'rejected': return AppTheme.error;
      case 'pending': return AppTheme.warning;
      default: return Colors.grey;
    }
  }
}
