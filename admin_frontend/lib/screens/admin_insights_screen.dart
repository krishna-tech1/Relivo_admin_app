import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_frontend/models/grant.dart';
import 'package:admin_frontend/theme/app_theme.dart';
import 'package:admin_frontend/screens/filtered_grant_list_screen.dart';
import 'package:admin_frontend/screens/grant_detail_screen.dart';

class AdminInsightsScreen extends StatelessWidget {
  final List<Grant> grants;
  final VoidCallback onRefresh;

  const AdminInsightsScreen({
    super.key,
    required this.grants,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate stats
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    
    final createdThisMonth = grants.where((g) => g.createdAt != null && g.createdAt!.isAfter(thisMonthStart)).toList();
    final expirySoon = grants.where((g) => !g.isExpired && g.hasUpcomingDeadline).toList();
    
    final adminGrants = grants.where((g) => g.creatorType == 'Admin').toList();
    final userGrants = grants.where((g) => g.creatorType == 'User').toList();
    final orgGrants = grants.where((g) => g.creatorType == 'Organization').toList();
    final externalGrants = grants.where((g) => g.creatorType == 'External').toList();

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: Text('Data Insights & Analysis', 
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.secondaryColor,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Summary Header
            Text("Grant Analysis Overview", 
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor)),
            const SizedBox(height: 20),
            
            // Monthly Growth Bar
            GestureDetector(
              onTap: () => _navigateToFiltered(context, "Created This Month", createdThisMonth),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text("Created This Month", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.primaryColor), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Text("${createdThisMonth.length} grants", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: grants.isEmpty ? 0 : createdThisMonth.length / grants.length,
                        backgroundColor: Colors.white,
                        color: AppTheme.primaryColor,
                        minHeight: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("Click to view monthly additions →", style: TextStyle(fontSize: 10, color: AppTheme.primaryColor.withOpacity(0.7))),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Grid of Detail Stats
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _AnalysisCard(
                  title: "Expiring Soon",
                  value: "${expirySoon.length}",
                  icon: Icons.auto_delete_rounded,
                  color: Colors.orange,
                  onTap: () => _navigateToFiltered(context, "Expiring Grants", expirySoon),
                ),
                _AnalysisCard(
                  title: "Admin Created",
                  value: "${adminGrants.length}",
                  icon: Icons.verified_user_rounded,
                  color: Colors.blue,
                  onTap: () => _navigateToFiltered(context, "Admin Created Grants", adminGrants),
                ),
                _AnalysisCard(
                  title: "Organization",
                  value: "${orgGrants.length}",
                  icon: Icons.business_center_rounded,
                  color: Colors.teal,
                  onTap: () => _navigateToFiltered(context, "Organization Grants", orgGrants),
                ),
                _AnalysisCard(
                  title: "User Submit",
                  value: "${userGrants.length}",
                  icon: Icons.person_add_alt_rounded,
                  color: Colors.purple,
                  onTap: () => _navigateToFiltered(context, "User Submitted Grants", userGrants),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // List Section for "Critical Deadlines"
            Text("Critical Deadlines (Next 7 Days)", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (expirySoon.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No urgent deadlines found")))
            else
              ...expirySoon.take(5).map((g) => _SmallGrantCard(
                grant: g,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GrantDetailScreen(showApplyButton: false),
                      settings: RouteSettings(arguments: g),
                    ),
                  );
                  if (result == true) onRefresh();
                },
              )).toList(),
              
            const SizedBox(height: 24),
            
            // External Data Sync info
            if (externalGrants.isNotEmpty) ...[
              Text("External Sources", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _navigateToFiltered(context, "External Source Grants", externalGrants),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_sync_rounded, color: Colors.blueGrey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text("${externalGrants.length} grants synced from Grants.gov", 
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.mediumGray),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToFiltered(BuildContext context, String title, List<Grant> filteredGrants) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilteredGrantListScreen(
          title: title,
          grants: filteredGrants,
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AnalysisCard({
    required this.title, 
    required this.value, 
    required this.icon, 
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Icon(Icons.arrow_outward_rounded, color: AppTheme.mediumGray.withOpacity(0.5), size: 16),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(title, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mediumGray, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallGrantCard extends StatelessWidget {
  final Grant grant;
  final VoidCallback onTap;
  const _SmallGrantCard({required this.grant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(grant.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text("Due: ${grant.formattedDeadline}", style: const TextStyle(fontSize: 11, color: AppTheme.mediumGray)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.mediumGray),
          ],
        ),
      ),
    );
  }
}
