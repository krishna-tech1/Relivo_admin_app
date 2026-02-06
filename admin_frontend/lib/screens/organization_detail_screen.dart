import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/organization.dart';
import '../services/auth_services.dart';

class OrganizationDetailScreen extends StatefulWidget {
  final Organization organization;

  const OrganizationDetailScreen({
    super.key,
    required this.organization,
  });

  @override
  State<OrganizationDetailScreen> createState() => _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState extends State<OrganizationDetailScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.error;
      case 'pending':
        return AppTheme.warning;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'pending':
        return Icons.pending_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Future<void> _handleApproval() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.organization.status.toLowerCase() == 'rejected' 
                  ? 'Re-approve Organization?' 
                  : 'Approve Organization?',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will send an approval email with login credentials to:',
                style: GoogleFonts.inter(color: AppTheme.mediumGray, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.success.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 20, color: AppTheme.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.organization.contactEmail ?? 'N/A',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The organization will gain full access to the platform upon approval.',
                style: GoogleFonts.inter(
                  color: AppTheme.mediumGray,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.mediumGray, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Approve Now'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _authService.approveOrganization(widget.organization.id);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Organization approved! Email sent to ${widget.organization.contactEmail}',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving organization: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleRejection({bool isSuspend = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.cancel_rounded, color: AppTheme.error, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isSuspend ? 'Suspend Organization?' : 'Reject Organization?',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSuspend 
                  ? 'This will deactivate the organization account and notify:'
                  : 'This will send a rejection notification email to:',
                style: GoogleFonts.inter(color: AppTheme.mediumGray, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.error.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 20, color: AppTheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.organization.contactEmail ?? 'N/A',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isSuspend 
                  ? 'The organization can be re-approved later from this screen.'
                  : 'Note: This action is permanent and the organization will be notified.',
                style: GoogleFonts.inter(
                  color: AppTheme.mediumGray,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.mediumGray, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isSuspend ? 'Suspend Now' : 'Reject Now'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _authService.rejectOrganization(widget.organization.id);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isSuspend 
                      ? 'Organization account suspended.'
                      : 'Organization rejected. Notification sent to ${widget.organization.contactEmail}',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing request: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.organization.status);
    final statusIcon = _getStatusIcon(widget.organization.status);
    final status = widget.organization.status.toLowerCase();
    
    final isPending = status == 'pending';
    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                elevation: 0,
                backgroundColor: AppTheme.primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  expandedTitleScale: 1.2,
                  title: Text(
                    widget.organization.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.adminGradient,
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Icon(
                            Icons.business_rounded,
                            size: 200,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        Center(
                          child: Hero(
                            tag: 'org_logo_${widget.organization.id}',
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: const Icon(
                                Icons.apartment_rounded,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Section
                      _buildSectionHeader('APPLICATION STATUS'),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(statusIcon, size: 48, color: statusColor),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.organization.status.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.offWhite,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                'Applied on ${DateFormat('MMMM dd, yyyy').format(widget.organization.createdAt)}',
                                style: GoogleFonts.inter(
                                  color: AppTheme.mediumGray,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Org Info Section
                      _buildSectionHeader('ORGANIZATION DETAILS'),
                      const SizedBox(height: 12),
                      
                      if (widget.organization.description != null && widget.organization.description!.isNotEmpty) ...[
                        _buildInfoCard(
                          icon: Icons.notes_rounded,
                          title: 'About',
                          content: widget.organization.description!,
                          color: Colors.indigo,
                        ),
                        const SizedBox(height: 16),
                      ],

                      _buildInfoCard(
                        icon: Icons.email_outlined,
                        title: 'Official Email',
                        content: widget.organization.contactEmail ?? 'N/A',
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),

                      _buildInfoCard(
                        icon: Icons.language_rounded,
                        title: 'Website',
                        content: widget.organization.website ?? 'N/A',
                        color: Colors.purple,
                        isLink: widget.organization.website != null,
                      ),
                      const SizedBox(height: 16),

                      _buildInfoCard(
                        icon: Icons.public_rounded,
                        title: 'Country',
                        content: widget.organization.country ?? 'N/A',
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),

                      _buildInfoCard(
                        icon: Icons.category_outlined,
                        title: 'Org Type',
                        content: widget.organization.type ?? 'N/A',
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),

                      _buildInfoCard(
                        icon: Icons.person_pin_rounded,
                        title: 'Owner Account ID',
                        content: widget.organization.userId?.toString() ?? 'Internal Only',
                        subtitle: 'Reference ID of the linked user account',
                        color: Colors.teal,
                      ),

                      const SizedBox(height: 120), // Padding for buttons
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Action Buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (isPending) ...[
                    Expanded(
                      flex: 1,
                      child: _buildActionButton(
                        onPressed: _isLoading ? null : () => _handleRejection(isSuspend: false),
                        icon: Icons.close_rounded,
                        label: 'Reject',
                        color: AppTheme.error,
                        isOutlined: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildActionButton(
                        onPressed: _isLoading ? null : _handleApproval,
                        icon: Icons.check_rounded,
                        label: 'Approve Organization',
                        color: AppTheme.success,
                        isOutlined: false,
                      ),
                    ),
                  ],
                  if (isApproved)
                    Expanded(
                      child: _buildActionButton(
                        onPressed: _isLoading ? null : () => _handleRejection(isSuspend: true),
                        icon: Icons.block_rounded,
                        label: 'SUSPEND ORGANIZATION',
                        color: AppTheme.error,
                        isOutlined: false,
                      ),
                    ),
                  if (isRejected)
                    Expanded(
                      child: _buildActionButton(
                        onPressed: _isLoading ? null : _handleApproval,
                        icon: Icons.check_rounded,
                        label: 'RE-APPROVE ORGANIZATION',
                        color: AppTheme.success,
                        isOutlined: false,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppTheme.mediumGray,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    String? subtitle,
    required Color color,
    bool isLink = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.mediumGray,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    content,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isLink ? AppTheme.primaryColor : AppTheme.darkGray,
                      height: 1.4,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppTheme.mediumGray,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isOutlined,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}
