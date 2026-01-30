import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_frontend/models/grant.dart';
import 'package:admin_frontend/theme/app_theme.dart';
import 'package:admin_frontend/screens/grant_detail_screen.dart';

class FilteredGrantListScreen extends StatelessWidget {
  final String title;
  final List<Grant> grants;

  const FilteredGrantListScreen({
    super.key,
    required this.title,
    required this.grants,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.secondaryColor,
        centerTitle: true,
      ),
      body: grants.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 64, color: AppTheme.mediumGray.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('No grants found for "$title"', style: const TextStyle(color: AppTheme.mediumGray)),
                ],
              ),
            )
          : ListView.builder(
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
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.description_rounded, color: AppTheme.primaryColor),
                        ),
                        title: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(grant.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text("${grant.organizer}\nDeadline: ${grant.formattedDeadline}",
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.mediumGray),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GrantDetailScreen(showApplyButton: false),
                              settings: RouteSettings(arguments: grant),
                            ),
                          );
                          if (result == true && context.mounted) {
                            Navigator.pop(context, true); // Pop back to dashboard to refresh
                          }
                        },
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 40,
                      child: AppTheme.buildCreatorBadge(grant.creatorType),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
