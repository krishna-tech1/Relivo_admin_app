import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:admin_frontend/screens/grant_editor_screen.dart';
import 'package:admin_frontend/services/grant_service.dart';
import '../theme/app_theme.dart';
import '../models/grant.dart';

class GrantDetailScreen extends StatelessWidget {
  final bool showApplyButton;
  const GrantDetailScreen({super.key, this.showApplyButton = true});

  @override
  Widget build(BuildContext context) {
    final grantBody = ModalRoute.of(context)!.settings.arguments;
    if (grantBody == null || grantBody is! Grant) {
      return const Scaffold(body: Center(child: Text("Invalid grant data")));
    }
    final Grant grant = grantBody;

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppTheme.white,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Grant Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppTheme.white),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GrantEditorScreen(grant: grant),
                          ),
                        );
                        if (result == true) {
                          if (context.mounted) Navigator.pop(context, true);
                        }
                      } else if (value == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Grant?'),
                            content: const Text('Are you sure you want to delete this grant? This action cannot be undone.'),
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

                        if (confirmed == true && context.mounted) {
                          try {
                            await GrantService().deleteGrant(grant.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Grant deleted successfully'), backgroundColor: AppTheme.success),
                              );
                              Navigator.pop(context, true);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
                              );
                            }
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 12), Text('Edit')]),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 12), Text('Delete', style: TextStyle(color: Colors.red))]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Info Card
                    Container(
                      decoration: AppTheme.cardDecoration,
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badges Row
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _Badge(
                                label: grant.category,
                                gradient: AppTheme.primaryGradient,
                              ),
                              if (grant.isVerified)
                                _Badge(
                                  label: 'VERIFIED',
                                  icon: Icons.verified,
                                  color: AppTheme.verified,
                                  outlined: true,
                                ),
                              if (grant.hasUpcomingDeadline)
                                _Badge(
                                  label: 'URGENT',
                                  icon: Icons.access_time,
                                  color: AppTheme.warning,
                                  outlined: true,
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Title
                          Text(
                            grant.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGray,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Amount
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                              border: Border.all(color: AppTheme.success),
                            ),
                            child: Text(
                              grant.amount,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.success,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Metadata
                          _InfoRow(
                            icon: Icons.business,
                            label: 'Organizer',
                            value: grant.organizer,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.location_on,
                            label: 'Country',
                            value: grant.country,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.calendar_today,
                            label: 'Deadline',
                            value: grant.formattedDeadline,
                            valueColor: grant.hasUpcomingDeadline 
                                ? AppTheme.warning 
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    
                    // Description Card
                    _SectionCard(
                      title: 'Description',
                      icon: Icons.description,
                      child: Text(
                        grant.description,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: AppTheme.darkGray,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    
                    // Eligibility Criteria Card
                    _SectionCard(
                      title: 'Eligibility Criteria',
                      icon: Icons.check_circle_outline,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: grant.eligibilityCriteria.map((criteria) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.success,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    criteria,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: AppTheme.darkGray,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    
                    // Required Documents Card
                    _SectionCard(
                      title: 'Required Documents',
                      icon: Icons.folder_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: grant.requiredDocuments.map((document) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.insert_drive_file,
                                  color: AppTheme.primaryBlue,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    document,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: AppTheme.darkGray,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: showApplyButton ? 80 : 20), // Space for floating button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Floating Apply Button
      floatingActionButton: showApplyButton ? Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
        height: AppConstants.buttonHeight,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            if (grant.applyUrl.isEmpty || grant.applyUrl == 'https://example.com/apply') {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No application link available for this grant'),
                  backgroundColor: AppTheme.warning,
                ),
              );
              return;
            }
            
            try {
              // Fix URL if it doesn't have http:// or https://
              String fixedUrl = grant.applyUrl;
              if (!fixedUrl.startsWith('http://') && !fixedUrl.startsWith('https://')) {
                fixedUrl = 'https://$fixedUrl';
              }
              
              final Uri url = Uri.parse(fixedUrl);
              
              // Check if URL can be launched
              final canLaunch = await canLaunchUrl(url);
              
              if (!canLaunch) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cannot open this URL: $fixedUrl'),
                      backgroundColor: AppTheme.error,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
                return;
              }
              
              // Try to launch in external browser first
              bool launched = await launchUrl(
                url, 
                mode: LaunchMode.externalApplication,
              );
              
              // If external launch fails, try in-app browser
              if (!launched) {
                launched = await launchUrl(
                  url,
                  mode: LaunchMode.platformDefault,
                );
              }
              
              // If both fail, show error
              if (!launched && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not open application link'),
                    backgroundColor: AppTheme.error,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            } catch (e) {
               if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.error,
                      duration: const Duration(seconds: 5),
                    ),
                  );
               }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            ),
          ),
          child: const Text(
            'Apply Now',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
          ),
        ),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final Gradient? gradient;
  final bool outlined;

  const _Badge({
    required this.label,
    this.icon,
    this.color,
    this.gradient,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: outlined ? null : gradient,
        color: outlined 
            ? color?.withValues(alpha: 0.1) 
            : (gradient == null ? color : null),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        border: outlined ? Border.all(color: color!) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: outlined ? color : AppTheme.white,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: outlined ? color : AppTheme.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryBlue,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.mediumGray,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppTheme.darkGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
