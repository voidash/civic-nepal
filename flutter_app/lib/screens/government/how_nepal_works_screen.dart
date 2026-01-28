import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/constitution_provider.dart';
import '../../widgets/home_title.dart';

/// Screen explaining how Nepal's government works
class HowNepalWorksScreen extends ConsumerStatefulWidget {
  const HowNepalWorksScreen({super.key});

  @override
  ConsumerState<HowNepalWorksScreen> createState() => _HowNepalWorksScreenState();
}

enum _GovSection { structure, lawMaking, elections, cabinet, services, documents }

class _HowNepalWorksScreenState extends ConsumerState<HowNepalWorksScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  _GovSection? _selectedSection;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/data/ministers.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading ministers data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _navigateToConstitution(int partIndex) {
    ref.read(selectedArticleProvider.notifier).selectArticle(
      SelectedArticleRef.part(partIndex: partIndex),
    );
    context.push('/constitution');
  }

  void _navigateToPreamble() {
    ref.read(selectedArticleProvider.notifier).selectArticle(
      const SelectedArticleRef.preamble(),
    );
    context.push('/constitution');
  }

  void _selectSection(_GovSection section) {
    setState(() => _selectedSection = section);
  }

  void _goBack() {
    setState(() => _selectedSection = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedSection != null) {
          _goBack();
        } else {
          context.go('/home');
        }
      },
      child: _buildContent(context, l10n, theme),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    // Show selected section content
    if (_selectedSection != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
          title: Text(_getSectionTitle(l10n, _selectedSection!)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _data == null
                ? Center(child: Text(l10n.failedLoadData))
                : _buildSectionContent(_selectedSection!),
      );
    }

    // Show card grid
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: HomeTitle(child: Text(l10n.government)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? Center(child: Text(l10n.failedLoadData))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section: Quick Links
                      _SectionHeader(title: l10n.quickLinks),
                      const SizedBox(height: 8),
                      // Constitution & Leaders (full width cards)
                      _GovCard(
                        icon: Icons.menu_book,
                        title: l10n.constitution,
                        description: l10n.constitutionDesc,
                        color: const Color(0xFF6A1B9A),
                        onTap: _navigateToPreamble,
                        fullWidth: true,
                      ),
                      const SizedBox(height: 12),
                      _GovCard(
                        icon: Icons.people,
                        title: l10n.leaders,
                        description: l10n.leadersDesc,
                        color: const Color(0xFF2E7D32),
                        onTap: () => context.push('/leaders'),
                        fullWidth: true,
                      ),

                      const SizedBox(height: 24),

                      // Section: Government Info
                      _SectionHeader(title: l10n.governmentInfo),
                      const SizedBox(height: 8),
                      // First row: Structure, Law Making
                      Row(
                        children: [
                          Expanded(
                            child: _GovCard(
                              icon: Icons.account_tree,
                              title: l10n.structure,
                              description: l10n.structureDesc,
                              color: theme.colorScheme.primary,
                              onTap: () => _selectSection(_GovSection.structure),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _GovCard(
                              icon: Icons.gavel,
                              title: l10n.lawMaking,
                              description: l10n.lawMakingDesc,
                              color: const Color(0xFF5D4037),
                              onTap: () => _selectSection(_GovSection.lawMaking),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Second row: Elections, Cabinet
                      Row(
                        children: [
                          Expanded(
                            child: _GovCard(
                              icon: Icons.how_to_vote,
                              title: 'Elections',
                              description: 'How voting works',
                              color: const Color(0xFFD32F2F),
                              onTap: () => _selectSection(_GovSection.elections),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _GovCard(
                              icon: Icons.groups,
                              title: l10n.cabinet,
                              description: l10n.cabinetDesc,
                              color: const Color(0xFF00695C),
                              onTap: () => _selectSection(_GovSection.cabinet),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Third row: Services
                      _GovCard(
                        icon: Icons.language,
                        title: l10n.govServices,
                        description: l10n.govServicesDesc,
                        color: const Color(0xFF1565C0),
                        onTap: () => _selectSection(_GovSection.services),
                        fullWidth: true,
                      ),

                      const SizedBox(height: 24),

                      // Section: Documents
                      _SectionHeader(title: l10n.getDocuments),
                      const SizedBox(height: 8),
                      _GovCard(
                        icon: Icons.assignment,
                        title: l10n.getGovDocuments,
                        description: l10n.getGovDocumentsDesc,
                        color: const Color(0xFFE65100),
                        onTap: () => _selectSection(_GovSection.documents),
                        fullWidth: true,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  String _getSectionTitle(AppLocalizations l10n, _GovSection section) {
    switch (section) {
      case _GovSection.structure:
        return l10n.structure;
      case _GovSection.lawMaking:
        return l10n.lawMaking;
      case _GovSection.elections:
        return 'Elections';
      case _GovSection.cabinet:
        return l10n.cabinet;
      case _GovSection.services:
        return l10n.govServices;
      case _GovSection.documents:
        return l10n.govProcedures;
    }
  }

  Widget _buildSectionContent(_GovSection section) {
    switch (section) {
      case _GovSection.structure:
        return _GovernmentStructureTab(
          data: _data!['governmentStructure'] as Map<String, dynamic>,
          onNavigateToConstitution: _navigateToConstitution,
        );
      case _GovSection.lawMaking:
        return _LegislativeProcessTab(
          data: _data!['legislativeProcess'] as Map<String, dynamic>,
        );
      case _GovSection.elections:
        return _ElectionsTab(
          data: _data!['elections'] as Map<String, dynamic>,
          onNavigateToConstitution: _navigateToConstitution,
        );
      case _GovSection.cabinet:
        return _CabinetTab(
          cabinet: _data!['cabinet'] as List<dynamic>,
          lastUpdated: _data!['lastUpdated'] as String,
        );
      case _GovSection.services:
        return const _GovServicesTab();
      case _GovSection.documents:
        return const _GovProceduresTab();
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _GovCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final bool fullWidth;

  const _GovCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          height: fullWidth ? 80 : 120,
          child: fullWidth
              ? Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Tab showing government structure
class _GovernmentStructureTab extends StatelessWidget {
  final Map<String, dynamic> data;
  final void Function(int partIndex) onNavigateToConstitution;

  const _GovernmentStructureTab({
    required this.data,
    required this.onNavigateToConstitution,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildExecutiveSection(context, data['executive']),
        const SizedBox(height: 16),
        _buildLegislativeSection(context, data['legislative']),
        const SizedBox(height: 16),
        _buildJudiciarySection(context, data['judiciary']),
        const SizedBox(height: 16),
        _buildFederalismSection(context, data['federalism']),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildExecutiveSection(
      BuildContext context, Map<String, dynamic> exec) {
    final hierarchy = exec['hierarchy'] as List<dynamic>;
    return _StructureCard(
      icon: Icons.account_balance,
      color: Colors.blue,
      title: exec['title'] as String,
      titleNp: exec['titleNp'] as String,
      description: exec['description'] as String,
      child: Column(
        children: [
          for (var i = 0; i < hierarchy.length; i++) ...[
            _HierarchyItem(
              role: hierarchy[i]['role'] as String,
              roleNp: hierarchy[i]['roleNp'] as String,
              description: hierarchy[i]['description'] as String,
              constitutionRef: hierarchy[i]['constitutionRef'] as Map<String, dynamic>?,
              onTap: onNavigateToConstitution,
            ),
            if (i < hierarchy.length - 1)
              const Icon(Icons.arrow_downward, color: Colors.blue, size: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildLegislativeSection(
      BuildContext context, Map<String, dynamic> leg) {
    final houses = leg['houses'] as List<dynamic>;
    final l10n = AppLocalizations.of(context);
    return _StructureCard(
      icon: Icons.how_to_vote,
      color: Colors.green,
      title: leg['title'] as String,
      titleNp: leg['titleNp'] as String,
      description: leg['description'] as String,
      child: Column(
        children: [
          Text(
            l10n.federalParliament,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Text(
            'संघीय संसद (द्विसदनात्मक)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < houses.length; i++) ...[
                Expanded(
                  child: _HouseCard(
                    name: houses[i]['name'] as String,
                    nameNp: houses[i]['nameNp'] as String,
                    seats: houses[i]['seats'] as int,
                    election: houses[i]['election'] as String,
                    composition: houses[i]['composition'] as String,
                    constitutionRef: houses[i]['constitutionRef'] as Map<String, dynamic>?,
                    onTap: onNavigateToConstitution,
                  ),
                ),
                if (i < houses.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJudiciarySection(
      BuildContext context, Map<String, dynamic> jud) {
    final hierarchy = jud['hierarchy'] as List<dynamic>;
    return _StructureCard(
      icon: Icons.balance,
      color: Colors.purple,
      title: jud['title'] as String,
      titleNp: jud['titleNp'] as String,
      description: jud['description'] as String,
      child: Column(
        children: [
          for (var i = 0; i < hierarchy.length; i++) ...[
            _CourtItem(
              court: hierarchy[i]['court'] as String,
              courtNp: hierarchy[i]['courtNp'] as String,
              description: hierarchy[i]['description'] as String,
              count: hierarchy[i]['count'] as int?,
              constitutionRef: hierarchy[i]['constitutionRef'] as Map<String, dynamic>?,
              onTap: onNavigateToConstitution,
            ),
            if (i < hierarchy.length - 1)
              const Icon(Icons.arrow_downward, color: Colors.purple, size: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildFederalismSection(
      BuildContext context, Map<String, dynamic> fed) {
    final levels = fed['levels'] as List<dynamic>;
    return _StructureCard(
      icon: Icons.map,
      color: Colors.orange,
      title: fed['title'] as String,
      titleNp: fed['titleNp'] as String,
      description: fed['description'] as String,
      child: Column(
        children: [
          for (final level in levels)
            _FederalLevelItem(
              level: level['level'] as String,
              levelNp: level['levelNp'] as String,
              description: level['description'] as String,
              count: level['count'] as int?,
              breakdown: level['breakdown'] as String?,
              constitutionRef: level['constitutionRef'] as Map<String, dynamic>?,
              onTap: onNavigateToConstitution,
            ),
        ],
      ),
    );
  }
}

class _StructureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String titleNp;
  final String description;
  final Widget child;

  const _StructureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.titleNp,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.3 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        titleNp,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class _HierarchyItem extends StatelessWidget {
  final String role;
  final String roleNp;
  final String description;
  final Map<String, dynamic>? constitutionRef;
  final void Function(int partIndex)? onTap;

  const _HierarchyItem({
    required this.role,
    required this.roleNp,
    required this.description,
    this.constitutionRef,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasTap = constitutionRef != null && onTap != null;
    return InkWell(
      onTap: hasTap ? () => onTap!(constitutionRef!['partIndex'] as int) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              role,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            Text(
              roleNp,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (hasTap) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined, size: 12, color: Colors.blue[700]),
                  const SizedBox(width: 4),
                  Text(
                    'See in Constitution',
                    style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HouseCard extends StatelessWidget {
  final String name;
  final String nameNp;
  final int seats;
  final String election;
  final String composition;
  final Map<String, dynamic>? constitutionRef;
  final void Function(int partIndex)? onTap;

  const _HouseCard({
    required this.name,
    required this.nameNp,
    required this.seats,
    required this.election,
    required this.composition,
    this.constitutionRef,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasTap = constitutionRef != null && onTap != null;
    return InkWell(
      onTap: hasTap ? () => onTap!(constitutionRef!['partIndex'] as int) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            Text(
              nameNp,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.seats(seats),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              election,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (hasTap) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined, size: 12, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text(
                    'See in Constitution',
                    style: TextStyle(fontSize: 10, color: Colors.green[700]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CourtItem extends StatelessWidget {
  final String court;
  final String courtNp;
  final String description;
  final int? count;
  final Map<String, dynamic>? constitutionRef;
  final void Function(int partIndex)? onTap;

  const _CourtItem({
    required this.court,
    required this.courtNp,
    required this.description,
    this.count,
    this.constitutionRef,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasTap = constitutionRef != null && onTap != null;
    return InkWell(
      onTap: hasTap ? () => onTap!(constitutionRef!['partIndex'] as int) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  court,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (count != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              courtNp,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (hasTap) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined, size: 12, color: Colors.purple[700]),
                  const SizedBox(width: 4),
                  Text(
                    'See in Constitution',
                    style: TextStyle(fontSize: 10, color: Colors.purple[700]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FederalLevelItem extends StatelessWidget {
  final String level;
  final String levelNp;
  final String description;
  final int? count;
  final String? breakdown;
  final Map<String, dynamic>? constitutionRef;
  final void Function(int partIndex)? onTap;

  const _FederalLevelItem({
    required this.level,
    required this.levelNp,
    required this.description,
    this.count,
    this.breakdown,
    this.constitutionRef,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasTap = constitutionRef != null && onTap != null;
    return InkWell(
      onTap: hasTap ? () => onTap!(constitutionRef!['partIndex'] as int) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            if (count != null)
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flag, color: Colors.white, size: 20),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    levelNp,
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  if (breakdown != null)
                    Text(
                      breakdown!,
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  if (hasTap) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.article_outlined, size: 12, color: Colors.orange[700]),
                        const SizedBox(width: 4),
                        Text(
                          'See in Constitution',
                          style: TextStyle(fontSize: 10, color: Colors.orange[700]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab showing legislative process
class _LegislativeProcessTab extends StatelessWidget {
  final Map<String, dynamic> data;

  const _LegislativeProcessTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final steps = data['steps'] as List<dynamic>;
    final specialBills = data['specialBills'] as List<dynamic>;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          data['title'] as String,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          data['titleNp'] as String,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),

        // Steps
        for (var i = 0; i < steps.length; i++) ...[
          _ProcessStep(
            step: steps[i]['step'] as int,
            title: steps[i]['title'] as String,
            titleNp: steps[i]['titleNp'] as String,
            description: steps[i]['description'] as String,
            isLast: i == steps.length - 1,
          ),
        ],

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        // Special bills
        Text(
          l10n.specialBills,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        for (final bill in specialBills)
          _SpecialBillCard(
            type: bill['type'] as String,
            typeNp: bill['typeNp'] as String,
            note: bill['note'] as String,
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ProcessStep extends StatelessWidget {
  final int step;
  final String title;
  final String titleNp;
  final String description;
  final bool isLast;

  const _ProcessStep({
    required this.step,
    required this.title,
    required this.titleNp,
    required this.description,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number and line
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$step',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    titleNp,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialBillCard extends StatelessWidget {
  final String type;
  final String typeNp;
  final String note;

  const _SpecialBillCard({
    required this.type,
    required this.typeNp,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.description, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$type ($typeNp)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  note,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Elections Tab
// ============================================================================

class _ElectionsTab extends StatelessWidget {
  final Map<String, dynamic> data;
  final void Function(int partIndex) onNavigateToConstitution;

  const _ElectionsTab({
    required this.data,
    required this.onNavigateToConstitution,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Text(
          data['title'] as String,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          data['titleNp'] as String,
          style: TextStyle(fontSize: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          data['description'] as String,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        // Electoral System Section
        _buildElectoralSystemSection(context, data['electoralSystem'] as Map<String, dynamic>),
        const SizedBox(height: 24),

        // Election Levels Section
        _buildElectionLevelsSection(context, data['electionLevels'] as Map<String, dynamic>),
        const SizedBox(height: 24),

        // Election Commission Section
        _buildElectionCommissionSection(context, data['electionCommission'] as Map<String, dynamic>),
        const SizedBox(height: 24),

        // Voter Eligibility Section
        _buildVoterEligibilitySection(context, data['voterEligibility'] as Map<String, dynamic>),
        const SizedBox(height: 24),

        // Government Formation Section
        _buildGovernmentFormationSection(context, data['governmentFormation'] as Map<String, dynamic>),
        const SizedBox(height: 24),

        // Key Terms Section
        _buildKeyTermsSection(context, data['keyTerms'] as List<dynamic>),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildElectoralSystemSection(BuildContext context, Map<String, dynamic> electoralSystem) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final systems = electoralSystem['systems'] as List<dynamic>;
    final whyBoth = electoralSystem['whyBothSystems'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: isDark ? 0.3 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.how_to_vote, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        electoralSystem['title'] as String,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        electoralSystem['titleNp'] as String,
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      electoralSystem['explanation'] as String,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // FPTP and PR cards
            for (final system in systems) ...[
              _ElectoralSystemCard(system: system as Map<String, dynamic>),
              const SizedBox(height: 12),
            ],
            // Why both systems
            const Divider(),
            const SizedBox(height: 8),
            Text(
              whyBoth['question'] as String,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              whyBoth['questionNp'] as String,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              whyBoth['answer'] as String,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElectionLevelsSection(BuildContext context, Map<String, dynamic> electionLevels) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final levels = electionLevels['levels'] as List<dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: isDark ? 0.3 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.layers, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        electionLevels['title'] as String,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        electionLevels['titleNp'] as String,
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final level in levels)
              _ElectionLevelCard(
                level: level as Map<String, dynamic>,
                onTap: onNavigateToConstitution,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildElectionCommissionSection(BuildContext context, Map<String, dynamic> ec) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final constitutionRef = ec['constitutionRef'] as Map<String, dynamic>?;

    return Card(
      child: InkWell(
        onTap: constitutionRef != null
            ? () => onNavigateToConstitution(constitutionRef['partIndex'] as int)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: isDark ? 0.3 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance, color: Colors.purple, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ec['title'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          ec['titleNp'] as String,
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (constitutionRef != null)
                    Icon(Icons.article_outlined, size: 20, color: Colors.purple[700]),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(label: 'Role', value: ec['role'] as String),
              _InfoRow(label: 'Composition', value: ec['composition'] as String),
              _InfoRow(label: 'Appointment', value: ec['appointment'] as String),
              _InfoRow(label: 'Term', value: ec['term'] as String),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ec['independence'] as String,
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoterEligibilitySection(BuildContext context, Map<String, dynamic> voter) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final requirements = voter['requirements'] as List<dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: isDark ? 0.3 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_pin, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voter['title'] as String,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        voter['titleNp'] as String,
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final req in requirements)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        req['requirement'] as String,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.ballot_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      voter['votingMethod'] as String,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGovernmentFormationSection(BuildContext context, Map<String, dynamic> govFormation) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final process = govFormation['process'] as List<dynamic>;
    final instability = govFormation['instability'] as Map<String, dynamic>;
    final reasons = instability['reasons'] as List<dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: isDark ? 0.3 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.domain, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        govFormation['title'] as String,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        govFormation['titleNp'] as String,
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      govFormation['subtitle'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              govFormation['explanation'] as String,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            // Process steps
            for (var i = 0; i < process.length; i++) ...[
              _ProcessStep(
                step: process[i]['step'] as int,
                title: process[i]['title'] as String,
                titleNp: process[i]['titleNp'] as String,
                description: process[i]['description'] as String,
                isLast: i == process.length - 1,
              ),
            ],
            const Divider(height: 32),
            // Instability section
            Text(
              instability['title'] as String,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            Text(
              instability['titleNp'] as String,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            for (final reason in reasons)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${reason['reason']} (${reason['reasonNp']})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reason['explanation'] as String,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.help_outline, color: Colors.deepPurple, size: 20),
                  const SizedBox(height: 8),
                  Text(
                    instability['criticalQuestion'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      color: Colors.deepPurple[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyTermsSection(BuildContext context, List<dynamic> keyTerms) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: isDark ? 0.3 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.translate, color: Colors.teal, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Key Terms / मुख्य शब्दहरू',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: keyTerms.map((term) {
                final t = term as Map<String, dynamic>;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        t['term'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        t['meaning'] as String,
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ElectoralSystemCard extends StatelessWidget {
  final Map<String, dynamic> system;

  const _ElectoralSystemCard({required this.system});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFPTP = (system['name'] as String).contains('FPTP');
    final color = isFPTP ? Colors.blue : Colors.green;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${system['seats']} seats',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      system['name'] as String,
                      style: TextStyle(fontWeight: FontWeight.bold, color: color),
                    ),
                    Text(
                      system['nameNp'] as String,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SystemDetailRow(icon: Icons.touch_app, label: 'How', text: system['howItWorks'] as String),
          _SystemDetailRow(icon: Icons.flag, label: 'Purpose', text: system['purpose'] as String),
          _SystemDetailRow(icon: Icons.warning_amber, label: 'Criticism', text: system['criticism'] as String),
          if (system['inclusionRequirement'] != null)
            _SystemDetailRow(
              icon: Icons.people_alt,
              label: 'Inclusion',
              text: system['inclusionRequirement'] as String,
            ),
        ],
      ),
    );
  }
}

class _SystemDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;

  const _SystemDetailRow({required this.icon, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 12),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ElectionLevelCard extends StatelessWidget {
  final Map<String, dynamic> level;
  final void Function(int partIndex) onTap;

  const _ElectionLevelCard({required this.level, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final constitutionRef = level['constitutionRef'] as Map<String, dynamic>?;
    final elects = level['elects'] as List<dynamic>;

    return InkWell(
      onTap: constitutionRef != null ? () => onTap(constitutionRef['partIndex'] as int) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level['level'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        level['levelNp'] as String,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (level['seats'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      level['seats'] as String,
                      style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                if (level['units'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${level['units']} units',
                      style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Elects:', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            for (final e in elects)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text('• $e', style: const TextStyle(fontSize: 12)),
              ),
            if (level['note'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, size: 14, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        level['note'] as String,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (constitutionRef != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.article_outlined, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'See in Constitution',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

/// Tab showing current cabinet
class _CabinetTab extends StatelessWidget {
  final List<dynamic> cabinet;
  final String lastUpdated;

  const _CabinetTab({
    required this.cabinet,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        // Last updated banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isDark ? Colors.grey[800] : Colors.grey[100],
          child: Row(
            children: [
              const Icon(Icons.update, size: 16),
              const SizedBox(width: 8),
              Text(
                l10n.lastUpdatedDate(lastUpdated),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              Text(
                l10n.sourceOpmcm,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        // Ministers list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: cabinet.length,
            itemBuilder: (context, index) {
              final minister = cabinet[index] as Map<String, dynamic>;
              final isPM = minister['position'] == 'Prime Minister';
              return _MinisterCard(
                name: minister['name'] as String,
                nameNp: minister['nameNp'] as String,
                position: minister['position'] as String,
                positionNp: minister['positionNp'] as String,
                ministries: (minister['ministries'] as List<dynamic>)
                    .cast<String>(),
                ministriesNp: (minister['ministriesNp'] as List<dynamic>)
                    .cast<String>(),
                isPM: isPM,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MinisterCard extends StatelessWidget {
  final String name;
  final String nameNp;
  final String position;
  final String positionNp;
  final List<String> ministries;
  final List<String> ministriesNp;
  final bool isPM;

  const _MinisterCard({
    required this.name,
    required this.nameNp,
    required this.position,
    required this.positionNp,
    required this.ministries,
    required this.ministriesNp,
    required this.isPM,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isPM
          ? (isDark
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5))
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: isPM
                  ? Theme.of(context).colorScheme.primary
                  : (isDark ? Colors.grey[700] : Colors.grey[300]),
              child: Text(
                name.substring(0, 1),
                style: TextStyle(
                  color: isPM ? Colors.white : (isDark ? Colors.white : Colors.grey[700]),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isPM ? 16 : 14,
                          ),
                        ),
                      ),
                      if (isPM)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    nameNp,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (var i = 0; i < ministries.length; i++)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ministries[i],
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ============================================================================
// Government Services Tab
// ============================================================================

class _GovServicesTab extends StatefulWidget {
  const _GovServicesTab();

  @override
  State<_GovServicesTab> createState() => _GovServicesTabState();
}

class _GovServicesTabState extends State<_GovServicesTab> with AutomaticKeepAliveClientMixin {
  List<GovServiceCategory> _categories = [];
  List<GovServiceCategory> _filteredCategories = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/gov_services.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final categoriesList = jsonData['categories'] as List<dynamic>;
      final categories = categoriesList
          .map((c) => GovServiceCategory.fromJson(c as Map<String, dynamic>))
          .toList();

      setState(() {
        _categories = categories;
        _filteredCategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading gov services: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterServices(String query) {
    if (query.isEmpty) {
      setState(() => _filteredCategories = _categories);
      return;
    }

    final lowerQuery = query.toLowerCase();
    final filtered = <GovServiceCategory>[];

    for (final category in _categories) {
      final matchingServices = category.services
          .where((s) =>
              s.name.toLowerCase().contains(lowerQuery) ||
              s.nameNp.toLowerCase().contains(lowerQuery) ||
              s.description.toLowerCase().contains(lowerQuery))
          .toList();

      if (matchingServices.isNotEmpty) {
        filtered.add(GovServiceCategory(
          name: category.name,
          nameNp: category.nameNp,
          icon: category.icon,
          services: matchingServices,
        ));
      }
    }

    setState(() => _filteredCategories = filtered);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotOpen(url))),
        );
      }
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'badge':
        return Icons.badge;
      case 'attach_money':
        return Icons.attach_money;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'electric_bolt':
        return Icons.electric_bolt;
      case 'gavel':
        return Icons.gavel;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Search box
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchServices,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterServices('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onChanged: _filterServices,
          ),
        ),

        // Services list
        Expanded(
          child: _filteredCategories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(l10n.noServices),
                      const SizedBox(height: 8),
                      Text(
                        l10n.tryDifferent,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredCategories.length,
                  itemBuilder: (context, index) {
                    final category = _filteredCategories[index];
                    return _ServiceCategoryCard(
                      category: category,
                      icon: _getIconData(category.icon),
                      onServiceTap: _openUrl,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ServiceCategoryCard extends StatelessWidget {
  final GovServiceCategory category;
  final IconData icon;
  final void Function(String url) onServiceTap;

  const _ServiceCategoryCard({
    required this.category,
    required this.icon,
    required this.onServiceTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(category.name),
        subtitle: Text(
          category.nameNp,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        children: category.services.map((service) {
          return ListTile(
            title: Text(service.name),
            subtitle: Text(
              service.description,
              style: theme.textTheme.bodySmall,
            ),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => onServiceTap(service.url),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
// Government Procedures (Document Guide) Tab
// ============================================================================

class _GovProceduresTab extends StatefulWidget {
  const _GovProceduresTab();

  @override
  State<_GovProceduresTab> createState() => _GovProceduresTabState();
}

class _GovProceduresTabState extends State<_GovProceduresTab> with AutomaticKeepAliveClientMixin {
  List<GovProcedure> _procedures = [];
  bool _isLoading = true;
  String? _expandedProcedure;
  String _disclaimer = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadProcedures();
  }

  Future<void> _loadProcedures() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/gov_procedures.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      final proceduresList = jsonData['procedures'] as List<dynamic>;
      final procedures = proceduresList
          .map((p) => GovProcedure.fromJson(p as Map<String, dynamic>))
          .toList();

      final disclaimer = jsonData['disclaimer'] as Map<String, dynamic>;

      setState(() {
        _procedures = procedures;
        _disclaimer = disclaimer['en'] as String;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading gov procedures: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
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
      case 'directions_car':
        return Icons.directions_car;
      case 'badge':
        return Icons.badge;
      case 'account_box':
        return Icons.account_box;
      case 'credit_card':
        return Icons.credit_card;
      case 'flight':
        return Icons.flight;
      case 'child_care':
        return Icons.child_care;
      case 'favorite':
        return Icons.favorite;
      case 'report':
        return Icons.report;
      case 'transfer_within_a_station':
        return Icons.transfer_within_a_station;
      case 'store':
        return Icons.store;
      case 'elderly':
        return Icons.elderly;
      default:
        return Icons.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_procedures.isEmpty) {
      return Center(child: Text(l10n.noData));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Disclaimer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.secondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _disclaimer,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Procedure cards
        ..._procedures.map((procedure) => _ProcedureCard(
              procedure: procedure,
              icon: _getIconData(procedure.icon),
              isExpanded: _expandedProcedure == procedure.id,
              onTap: () {
                setState(() {
                  _expandedProcedure = _expandedProcedure == procedure.id
                      ? null
                      : procedure.id;
                });
              },
              onOpenUrl: _openUrl,
            )),
      ],
    );
  }
}

class _ProcedureCard extends StatelessWidget {
  final GovProcedure procedure;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onTap;
  final void Function(String url) onOpenUrl;

  const _ProcedureCard({
    required this.procedure,
    required this.icon,
    required this.isExpanded,
    required this.onTap,
    required this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: primaryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          procedure.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          procedure.titleNp,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          procedure.summary,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  // Processing time and official link
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            procedure.processingTime,
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => onOpenUrl(procedure.officialUrl),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Official Site'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Eligibility
                  _ProcedureSectionHeader(title: 'Eligibility', icon: Icons.check_circle_outline),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: procedure.eligibility
                          .map((e) => _BulletPoint(text: e))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Documents Required
                  _ProcedureSectionHeader(title: 'Documents Required', icon: Icons.folder_outlined),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: procedure.documents
                          .map((doc) => _DocumentItem(document: doc))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Steps
                  _ProcedureSectionHeader(title: 'Process Steps', icon: Icons.list_alt),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: procedure.steps
                          .map((step) => _StepItem(step: step))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Fees
                  _ProcedureSectionHeader(title: 'Fees', icon: Icons.payments_outlined),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: procedure.fees.asMap().entries.map((entry) {
                          final isLast = entry.key == procedure.fees.length - 1;
                          return Column(
                            children: [
                              ListTile(
                                dense: true,
                                title: Text(entry.value.item),
                                trailing: Text(
                                  entry.value.amount,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: entry.value.amount == 'FREE'
                                        ? Colors.green
                                        : primaryColor,
                                  ),
                                ),
                              ),
                              if (!isLast) const Divider(height: 1),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tips
                  _ProcedureSectionHeader(title: 'Tips & Gotchas', icon: Icons.lightbulb_outline),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: theme.colorScheme.tertiaryContainer.withOpacity(0.5),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: procedure.tips
                              .map((tip) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.tips_and_updates,
                                            size: 16, color: theme.colorScheme.tertiary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            tip,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: theme.colorScheme.onTertiaryContainer,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ProcedureSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ProcedureSectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _DocumentItem extends StatelessWidget {
  final ProcedureDocument document;

  const _DocumentItem({required this.document});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            document.required ? Icons.check_box : Icons.check_box_outline_blank,
            size: 18,
            color: document.required ? Colors.green : colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: document.required ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                Text(
                  document.description,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (!document.required)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Optional',
                style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final ProcedureStep step;

  const _StepItem({required this.step});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${step.step}',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.description,
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Data Models
// ============================================================================

class GovServiceCategory {
  final String name;
  final String nameNp;
  final String icon;
  final List<GovService> services;

  GovServiceCategory({
    required this.name,
    required this.nameNp,
    required this.icon,
    required this.services,
  });

  factory GovServiceCategory.fromJson(Map<String, dynamic> json) {
    return GovServiceCategory(
      name: json['name'] as String,
      nameNp: json['nameNp'] as String,
      icon: json['icon'] as String,
      services: (json['services'] as List)
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

class GovProcedure {
  final String id;
  final String icon;
  final String title;
  final String titleNp;
  final String summary;
  final List<String> eligibility;
  final List<ProcedureDocument> documents;
  final List<ProcedureStep> steps;
  final List<ProcedureFee> fees;
  final List<String> tips;
  final String officialUrl;
  final String processingTime;

  GovProcedure({
    required this.id,
    required this.icon,
    required this.title,
    required this.titleNp,
    required this.summary,
    required this.eligibility,
    required this.documents,
    required this.steps,
    required this.fees,
    required this.tips,
    required this.officialUrl,
    required this.processingTime,
  });

  factory GovProcedure.fromJson(Map<String, dynamic> json) {
    return GovProcedure(
      id: json['id'] as String,
      icon: json['icon'] as String,
      title: (json['title'] as Map<String, dynamic>)['en'] as String,
      titleNp: (json['title'] as Map<String, dynamic>)['np'] as String,
      summary: (json['summary'] as Map<String, dynamic>)['en'] as String,
      eligibility: ((json['eligibility'] as Map<String, dynamic>)['en'] as List)
          .cast<String>(),
      documents: (json['documents'] as List)
          .map((d) => ProcedureDocument.fromJson(d as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List)
          .map((s) => ProcedureStep.fromJson(s as Map<String, dynamic>))
          .toList(),
      fees: (json['fees'] as List)
          .map((f) => ProcedureFee.fromJson(f as Map<String, dynamic>))
          .toList(),
      tips: (json['tips'] as List)
          .map((t) => (t as Map<String, dynamic>)['en'] as String)
          .toList(),
      officialUrl: json['officialUrl'] as String,
      processingTime:
          (json['processingTime'] as Map<String, dynamic>)['en'] as String,
    );
  }
}

class ProcedureDocument {
  final String name;
  final String description;
  final bool required;

  ProcedureDocument({
    required this.name,
    required this.description,
    required this.required,
  });

  factory ProcedureDocument.fromJson(Map<String, dynamic> json) {
    return ProcedureDocument(
      name: (json['name'] as Map<String, dynamic>)['en'] as String,
      description: (json['description'] as Map<String, dynamic>)['en'] as String,
      required: json['required'] as bool,
    );
  }
}

class ProcedureStep {
  final int step;
  final String title;
  final String description;

  ProcedureStep({
    required this.step,
    required this.title,
    required this.description,
  });

  factory ProcedureStep.fromJson(Map<String, dynamic> json) {
    return ProcedureStep(
      step: json['step'] as int,
      title: (json['title'] as Map<String, dynamic>)['en'] as String,
      description: (json['description'] as Map<String, dynamic>)['en'] as String,
    );
  }
}

class ProcedureFee {
  final String item;
  final String amount;

  ProcedureFee({required this.item, required this.amount});

  factory ProcedureFee.fromJson(Map<String, dynamic> json) {
    return ProcedureFee(
      item: (json['item'] as Map<String, dynamic>)['en'] as String,
      amount: json['amount'] as String,
    );
  }
}
