import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/grant.dart';
import '../services/grant_service.dart';
import '../services/auth_services.dart';
import 'grant_detail_screen.dart';
import 'filter_screen.dart';
import 'login_screen.dart';
import 'my_grants_screen.dart';
import '../widgets/grant_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State for filtering
  List<Grant> _allGrants = [];
  List<Grant> _filteredGrants = [];
  String _selectedCategory = 'All Categories';
  String _selectedCountry = 'All Countries';
  final TextEditingController _searchController = TextEditingController();
  DateTime? _lastBackPressTime;
  bool _isLoading = true;
  final _grantService = GrantService();

  @override
  void initState() {
    super.initState();
    _fetchGrants();
  }

  Future<void> _fetchGrants() async {
    setState(() => _isLoading = true);
    try {
      final grants = await _grantService.getGrants();
      if (mounted) {
        setState(() {
          _allGrants = grants;
          _isLoading = false;
        });
        _filterGrants(); // Initial filter
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load grants: $e')),
        );
      }
    }
  }

  void _handleSearch(String query) {
    _filterGrants(query: query);
  }

  void _filterGrants({String? query}) {
    final searchQuery = query ?? _searchController.text;
    
    setState(() {
      _filteredGrants = _allGrants.where((grant) {
        final matchesCategory = _selectedCategory == 'All Categories' || 
                              grant.category == _selectedCategory;
        final matchesCountry = _selectedCountry == 'All Countries' || 
                             grant.country == _selectedCountry;
        final matchesSearch = grant.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                            grant.description.toLowerCase().contains(searchQuery.toLowerCase());
        
        return matchesCategory && matchesCountry && matchesSearch;
      }).toList();
    });
  }

  Future<void> _navigateToFilter() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FilterScreen(),
        settings: RouteSettings(
          arguments: {
            'category': _selectedCategory,
            'country': _selectedCountry,
          },
        ),
      ),
    );

    if (result != null && result is Map) {
      setState(() {
        _selectedCategory = result['category'] ?? 'All Categories';
        _selectedCountry = result['country'] ?? 'All Countries';
      });
      _filterGrants();
    }
  }

  void _handleLogout() {
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
              // Clear session first
              await AuthService().logout();
              
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        if (_lastBackPressTime == null || 
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.offWhite,
        body: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                     Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Find Support',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.mediumGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Available Grants',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: AppTheme.darkGray,
                                fontWeight: FontWeight.w800,
                                fontSize: 26,
                              ),
                            ),
                          ],
                        ),
                        // Profile Menu
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'logout') {
                              _handleLogout();
                            } else if (value == 'my_submissions') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const MyGrantsScreen()),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'my_submissions',
                              child: Row(
                                children: [
                                  Icon(Icons.assignment_ind, color: AppTheme.primaryColor),
                                  SizedBox(width: 8),
                                  Text('My Submissions'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem<String>(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Logout', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Search and Filter Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.offWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.lightGray),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _handleSearch,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              decoration: const InputDecoration(
                                hintText: 'Search grants...',
                                prefixIcon: Icon(Icons.search_rounded, color: AppTheme.mediumGray),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, 
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _navigateToFilter,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: AppTheme.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filters Status (if active)
              if (_selectedCategory != 'All Categories' || _selectedCountry != 'All Countries')
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, size: 16, color: AppTheme.primaryBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Active Filters:',
                        style: TextStyle(
                          color: AppTheme.mediumGray,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (_selectedCategory != 'All Categories')
                                _FilterBadge(label: _selectedCategory),
                              if (_selectedCountry != 'All Countries') ...[
                                const SizedBox(width: 8),
                                _FilterBadge(label: _selectedCountry),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Grants List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchGrants,
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredGrants.isEmpty
                    ? LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: constraints.maxHeight,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppTheme.offWhite,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.search_off_rounded,
                                      size: 64,
                                      color: AppTheme.mediumGray.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No grants found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: AppTheme.mediumGray,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Try adjusting your filters',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.mediumGray.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _filteredGrants.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          return GrantCard(
                            grant: _filteredGrants[index],
                            // Custom onTap for HomeScreen (view details only)
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GrantDetailScreen(),
                                  settings: RouteSettings(arguments: _filteredGrants[index]),
                                ),
                              );
                            },
                          );
                        },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Internal widget classes removed. Using imported GrantCard. 

class _FilterBadge extends StatelessWidget {
  final String label;

  const _FilterBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
 
