import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/ipo.dart';
import '../../services/ipo_service.dart';
import '../../services/background_service.dart';
import '../../widgets/home_title.dart';

/// IPO and Shares screen with two tabs
class IpoSharesScreen extends StatefulWidget {
  const IpoSharesScreen({super.key});

  @override
  State<IpoSharesScreen> createState() => _IpoSharesScreenState();
}

class _IpoSharesScreenState extends State<IpoSharesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: HomeTitle(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.ipoShares),
              const Text(
                'आईपीओ र सेयर',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          tabs: [
            Tab(text: l10n.ipoList, icon: const Icon(Icons.list_alt, size: 20)),
            Tab(text: l10n.todaysPrice, icon: const Icon(Icons.trending_up, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _IpoListTab(),
          _StockPricesTab(),
        ],
      ),
    );
  }
}

/// IPO List Tab
class _IpoListTab extends StatefulWidget {
  const _IpoListTab();

  @override
  State<_IpoListTab> createState() => _IpoListTabState();
}

class _IpoListTabState extends State<_IpoListTab> {
  List<Ipo>? _ipos;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  Duration? _lastFetch;

  @override
  void initState() {
    super.initState();
    _loadCachedThenFresh();
  }

  /// Load cached data first, then fetch fresh data in background
  Future<void> _loadCachedThenFresh() async {
    // First, try to load cached data immediately
    final cached = await IpoService.getCachedIpos();
    final lastFetch = await IpoService.getTimeSinceLastFetch();

    if (!mounted) return;

    if (cached.isNotEmpty) {
      setState(() {
        _ipos = cached;
        _lastFetch = lastFetch;
        _isLoading = false;
        _isRefreshing = true;
      });
    }

    // Fetch fresh data in background (don't await)
    _fetchFreshData();
  }

  /// Fetch fresh data from network
  Future<void> _fetchFreshData() async {
    if (!mounted) return;

    if (_ipos == null || _ipos!.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() => _isRefreshing = true);
    }

    try {
      final ipos = await IpoService.fetchIpoList();
      if (!mounted) return;

      final lastFetch = await IpoService.getTimeSinceLastFetch();
      if (!mounted) return;

      // Run background check without blocking UI (not available on web)
      if (!kIsWeb) {
        BackgroundService.runIpoCheckNow();
      }

      setState(() {
        _ipos = ipos;
        _lastFetch = lastFetch;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_ipos == null || _ipos!.isEmpty) {
          _error = 'Failed to load IPO data: $e';
        }
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  /// Pull to refresh handler
  Future<void> _loadData() async {
    await _fetchFreshData();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_ipos == null || _ipos!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              l10n.noActiveIpos,
              style: TextStyle(fontSize: 18, color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.checkLater,
              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.refresh),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Source info and refresh indicator
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text(
                l10n.sourceCdsc,
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              const Spacer(),
              if (_isRefreshing) ...[
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 6),
                Text(
                  'Updating...',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ] else if (_lastFetch != null)
                Text(
                  l10n.updatedAgo(_formatDuration(_lastFetch!)),
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // IPO cards
          ..._ipos!.map((ipo) => _IpoCard(ipo: ipo)),

          // Open CDSC button
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _openUrl('https://cdsc.com.np/ipolist'),
            icon: const Icon(Icons.open_in_new),
            label: Text(l10n.openCdsc),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 1) return 'just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m';
    if (duration.inHours < 24) return '${duration.inHours}h';
    return '${duration.inDays}d';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// IPO Card Widget
class _IpoCard extends StatelessWidget {
  final Ipo ipo;

  const _IpoCard({required this.ipo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();
    final isOpen = IpoService.isCurrentlyOpen(ipo);
    final isUpcoming = ipo.openDate.isAfter(now);
    final daysUntilOpen = ipo.openDate.difference(now).inDays;
    final daysUntilClose = ipo.closeDate.difference(now).inDays;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isOpen) {
      if (daysUntilClose <= 1) {
        statusColor = Colors.orange;
        statusText = daysUntilClose <= 0 ? 'Closes Today!' : 'Closes Tomorrow';
        statusIcon = Icons.warning_amber;
      } else {
        statusColor = isDark ? Colors.green[400]! : Colors.green[600]!;
        statusText = 'Open for Application';
        statusIcon = Icons.check_circle;
      }
    } else if (isUpcoming) {
      statusColor = isDark ? Colors.blue[400]! : Colors.blue[600]!;
      statusText = daysUntilOpen <= 1 ? 'Opens Tomorrow' : 'Opens in $daysUntilOpen days';
      statusIcon = Icons.schedule;
    } else {
      statusColor = colorScheme.onSurface.withValues(alpha: 0.5);
      statusText = 'Closed';
      statusIcon = Icons.block;
    }

    final subtitleColor = colorScheme.onSurface.withValues(alpha: 0.6);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ipo.symbol.isNotEmpty ? ipo.symbol : 'N/A',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Company info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ipo.companyName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ipo.issueType,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Issue Manager: ${ipo.issueManager}',
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Stats grid
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Issued Units',
                        value: _formatNumber(ipo.issuedUnits),
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Applications',
                        value: _formatNumber(ipo.numberOfApplications),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Applied Units',
                        value: _formatNumber(ipo.appliedUnits),
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Total Amount',
                        value: 'Rs ${_formatNumber(ipo.amount)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Opens',
                              style: TextStyle(
                                fontSize: 11,
                                color: subtitleColor,
                              ),
                            ),
                            Text(
                              _formatDate(ipo.openDate),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward, color: subtitleColor, size: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Closes',
                              style: TextStyle(
                                fontSize: 11,
                                color: subtitleColor,
                              ),
                            ),
                            Text(
                              _formatDate(ipo.closeDate),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Last update
                const SizedBox(height: 8),
                Text(
                  'Last updated: ${_formatDateTime(ipo.lastUpdate)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 10000000) {
      return '${(number / 10000000).toStringAsFixed(2)} Cr';
    } else if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(2)} L';
    } else if (number >= 1000) {
      return number.toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return number.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dt) {
    return '${_formatDate(dt)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Stock Prices Tab
class _StockPricesTab extends StatefulWidget {
  const _StockPricesTab();

  @override
  State<_StockPricesTab> createState() => _StockPricesTabState();
}

class _StockPricesTabState extends State<_StockPricesTab> {
  List<StockPrice>? _stocks;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  String _searchQuery = '';
  String _sortBy = 'volume'; // volume, gainers, losers

  @override
  void initState() {
    super.initState();
    _loadCachedThenFresh();
  }

  /// Load cached data first, then fetch fresh data
  Future<void> _loadCachedThenFresh() async {
    final cached = await IpoService.getCachedStocks();

    if (!mounted) return;

    if (cached.isNotEmpty) {
      setState(() {
        _stocks = cached;
        _isLoading = false;
        _isRefreshing = true;
      });
    }

    // Fetch fresh data in background
    _fetchFreshData();
  }

  /// Fetch fresh data from network
  Future<void> _fetchFreshData() async {
    if (!mounted) return;

    if (_stocks == null || _stocks!.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() => _isRefreshing = true);
    }

    try {
      final stocks = await IpoService.fetchStockPrices();
      if (!mounted) return;

      setState(() {
        _stocks = stocks;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_stocks == null || _stocks!.isEmpty) {
          _error = 'Failed to load stock data: $e';
        }
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  /// Pull to refresh handler
  Future<void> _loadData() async {
    await _fetchFreshData();
  }

  List<StockPrice> get _filteredStocks {
    if (_stocks == null) return [];

    var filtered = _stocks!.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.symbol.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.companyName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    switch (_sortBy) {
      case 'gainers':
        filtered.sort((a, b) => b.changePercent.compareTo(a.changePercent));
        break;
      case 'losers':
        filtered.sort((a, b) => a.changePercent.compareTo(b.changePercent));
        break;
      case 'volume':
      default:
        filtered.sort((a, b) => b.volume.compareTo(a.volume));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_stocks == null || _stocks!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_flat, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              l10n.marketUnavailable,
              style: TextStyle(fontSize: 18, color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.marketClosed,
              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.refresh),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search and filter bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search
              TextField(
                decoration: InputDecoration(
                  hintText: l10n.searchSymbol,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 12),

              // Filter chips
              Row(
                children: [
                  _FilterChip(
                    label: l10n.topVolume,
                    selected: _sortBy == 'volume',
                    onTap: () => setState(() => _sortBy = 'volume'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.topGainers,
                    selected: _sortBy == 'gainers',
                    color: isDark ? Colors.green[400] : Colors.green[600],
                    onTap: () => setState(() => _sortBy = 'gainers'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.topLosers,
                    selected: _sortBy == 'losers',
                    color: isDark ? Colors.red[400] : Colors.red[600],
                    onTap: () => setState(() => _sortBy = 'losers'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Stock list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              itemCount: _filteredStocks.length,
              itemBuilder: (context, index) {
                return _StockRow(stock: _filteredStocks[index]);
              },
            ),
          ),
        ),

        // Source info
        Container(
          padding: const EdgeInsets.all(12),
          color: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRefreshing) ...[
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 6),
                Text(
                  'Updating...',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ] else ...[
                Icon(Icons.info_outline, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(
                  'Source: ShareSansar / Merolagani',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final chipColor = color ?? colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? chipColor.withValues(alpha: isDark ? 0.3 : 0.15)
              : (isDark ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? chipColor : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? chipColor : colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  final StockPrice stock;

  const _StockRow({required this.stock});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isPositive = stock.change >= 0;
    final changeColor = isPositive
        ? (isDark ? Colors.green[400]! : Colors.green[600]!)
        : (isDark ? Colors.red[400]! : Colors.red[600]!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? colorScheme.surfaceContainerHighest : colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          // Symbol and company
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.symbol,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  stock.companyName,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Volume
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatVolume(stock.volume),
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                ),
                Text(
                  'Vol',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          // Price and change
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs ${stock.ltp.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: changeColor,
                      size: 18,
                    ),
                    Text(
                      '${stock.changePercent.abs().toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: changeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatVolume(int volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toString();
  }
}
