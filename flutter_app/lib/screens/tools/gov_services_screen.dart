import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/home_title.dart';

/// Screen displaying categorized list of Nepal government services
class GovServicesScreen extends StatefulWidget {
  final String? initialCategory;

  const GovServicesScreen({super.key, this.initialCategory});

  @override
  State<GovServicesScreen> createState() => _GovServicesScreenState();
}

class _GovServicesScreenState extends State<GovServicesScreen> {
  List<ServiceCategory> _categories = [];
  List<ServiceCategory> _filteredCategories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/gov_services.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final categoriesList = jsonData['categories'] as List<dynamic>;

      final categories = categoriesList
          .map((c) => ServiceCategory.fromJson(c as Map<String, dynamic>))
          .toList();

      // Create keys for each category
      for (final cat in categories) {
        _categoryKeys[cat.id] = GlobalKey();
      }

      setState(() {
        _categories = categories;
        _filteredCategories = categories;
        _isLoading = false;
      });

      // Scroll to initial category if provided
      if (widget.initialCategory != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCategory(widget.initialCategory!);
        });
      }
    } catch (e) {
      debugPrint('Error loading gov services: $e');
      setState(() => _isLoading = false);
    }
  }

  void _scrollToCategory(String categoryId) {
    final key = _categoryKeys[categoryId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _filterServices(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories = _categories
            .map((category) {
              final matchingServices = category.services.where((service) {
                return service.name.toLowerCase().contains(_searchQuery) ||
                    service.nameNp.contains(_searchQuery) ||
                    service.description.toLowerCase().contains(_searchQuery);
              }).toList();

              if (matchingServices.isEmpty) return null;

              return ServiceCategory(
                id: category.id,
                name: category.name,
                nameNp: category.nameNp,
                icon: category.icon,
                services: matchingServices,
              );
            })
            .whereType<ServiceCategory>()
            .toList();
      }
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open: $url')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening URL: $e')),
        );
      }
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'description':
        return Icons.description;
      case 'account_balance':
        return Icons.account_balance;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'electrical_services':
        return Icons.electrical_services;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'business':
        return Icons.business;
      case 'flight':
        return Icons.flight;
      case 'gavel':
        return Icons.gavel;
      default:
        return Icons.public;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: HomeTitle(child: Text(l10n.govServices)),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchServices,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterServices('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              onChanged: _filterServices,
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCategories.isEmpty
                    ? _buildEmptyState()
                    : _buildServicesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noServices,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          Text(
            l10n.tryDifferent,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _filteredCategories.length,
      itemBuilder: (context, index) {
        final category = _filteredCategories[index];
        return _CategorySection(
          key: _categoryKeys[category.id],
          category: category,
          icon: _getIconData(category.icon),
          onServiceTap: _openUrl,
          isHighlighted: widget.initialCategory == category.id,
        );
      },
    );
  }
}

class _CategorySection extends StatelessWidget {
  final ServiceCategory category;
  final IconData icon;
  final void Function(String url) onServiceTap;
  final bool isHighlighted;

  const _CategorySection({
    super.key,
    required this.category,
    required this.icon,
    required this.onServiceTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isHighlighted
          ? BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 4,
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        category.nameNp,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Services list
          ...category.services.map((service) => _ServiceTile(
                service: service,
                onTap: () => onServiceTap(service.url),
              )),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final GovService service;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(service.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            service.nameNp,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          Text(
            service.description,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: const Icon(Icons.open_in_new, size: 18),
      isThreeLine: true,
    );
  }
}

// Data models
class ServiceCategory {
  final String id;
  final String name;
  final String nameNp;
  final String icon;
  final List<GovService> services;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.nameNp,
    required this.icon,
    required this.services,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    final servicesList = json['services'] as List<dynamic>;
    return ServiceCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      nameNp: json['nameNp'] as String,
      icon: json['icon'] as String,
      services: servicesList
          .map((s) => GovService.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GovService {
  final String name;
  final String nameNp;
  final String description;
  final String url;

  GovService({
    required this.name,
    required this.nameNp,
    required this.description,
    required this.url,
  });

  factory GovService.fromJson(Map<String, dynamic> json) {
    return GovService(
      name: json['name'] as String,
      nameNp: json['nameNp'] as String,
      description: json['description'] as String,
      url: json['url'] as String,
    );
  }
}
