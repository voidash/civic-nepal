import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/constitution_provider.dart';
import '../../widgets/home_title.dart';

/// Screen explaining how Nepal's government works
class HowNepalWorksScreen extends ConsumerStatefulWidget {
  const HowNepalWorksScreen({super.key});

  @override
  ConsumerState<HowNepalWorksScreen> createState() => _HowNepalWorksScreenState();
}

class _HowNepalWorksScreenState extends ConsumerState<HowNepalWorksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    // Select the part in the constitution provider
    ref.read(selectedArticleProvider.notifier).selectArticle(
      SelectedArticleRef.part(partIndex: partIndex),
    );
    // Navigate to constitution screen
    context.push('/constitution');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: HomeTitle(child: Text(l10n.howNepalWorks)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          tabs: [
            Tab(text: l10n.structure, icon: const Icon(Icons.account_tree, size: 20)),
            Tab(text: l10n.lawMaking, icon: const Icon(Icons.gavel, size: 20)),
            Tab(text: l10n.cabinet, icon: const Icon(Icons.groups, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? Center(child: Text(l10n.failedLoadData))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _GovernmentStructureTab(
                        data: _data!['governmentStructure']
                            as Map<String, dynamic>,
                        onNavigateToConstitution: _navigateToConstitution),
                    _LegislativeProcessTab(
                        data: _data!['legislativeProcess']
                            as Map<String, dynamic>),
                    _CabinetTab(
                      cabinet: _data!['cabinet'] as List<dynamic>,
                      lastUpdated: _data!['lastUpdated'] as String,
                    ),
                  ],
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
