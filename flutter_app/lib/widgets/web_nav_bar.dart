import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';

/// Primary brand color - blue
const _brandColor = Color(0xFF1976D2);

/// Horizontal navigation bar for web layout
/// Replaces bottom navigation with a top navigation bar
/// Responsive: collapses nav items into hamburger menu on narrow screens
class WebNavBar extends StatelessWidget implements PreferredSizeWidget {
  const WebNavBar({
    required this.currentRoute,
    super.key,
  });

  final String currentRoute;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  void _navigateTo(BuildContext context, String route) {
    if (route == currentRoute) return;
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 900;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Logo / Brand
            InkWell(
              onTap: () => _navigateTo(context, '/home'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: _brandColor,
                      size: 28,
                    ),
                    if (!isNarrow) ...[
                      const SizedBox(width: 8),
                      Text(
                        'नागरिक पात्रो',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _brandColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (isNarrow) ...[
              // Narrow screen: hamburger menu
              const Spacer(),
              _HamburgerMenu(
                currentRoute: currentRoute,
                onNavigate: (route) => _navigateTo(context, route),
              ),
            ] else ...[
              // Wide screen: simple nav items
              const SizedBox(width: 16),
              _NavItem(
                icon: Icons.calendar_month,
                label: l10n.calendar,
                isActive: currentRoute == '/calendar',
                onTap: () => _navigateTo(context, '/calendar'),
              ),
              _NavItem(
                icon: Icons.map,
                label: l10n.map,
                isActive: currentRoute.startsWith('/map'),
                onTap: () => _navigateTo(context, '/map'),
              ),
              _NavItem(
                icon: Icons.gavel,
                label: l10n.constitution,
                isActive: currentRoute == '/constitution' || currentRoute == '/constitutional-rights',
                onTap: () => _navigateTo(context, '/constitutional-rights'),
              ),
              _NavItem(
                icon: Icons.people,
                label: l10n.leaders,
                isActive: currentRoute.startsWith('/leaders'),
                onTap: () => _navigateTo(context, '/leaders'),
              ),
              _NavItem(
                icon: Icons.newspaper,
                label: 'RONB',
                isActive: currentRoute == '/news',
                onTap: () => _navigateTo(context, '/news'),
              ),
              const Spacer(),
            ],

            // Theme toggle
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () => context.push('/settings'),
              tooltip: l10n.theme,
            ),

            // Settings
            IconButton(
              icon: Icon(
                Icons.settings,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () => context.push('/settings'),
              tooltip: l10n.settings,
            ),
          ],
        ),
      ),
    );
  }
}

/// Hamburger menu for narrow screens
class _HamburgerMenu extends StatelessWidget {
  const _HamburgerMenu({
    required this.currentRoute,
    required this.onNavigate,
  });

  final String currentRoute;
  final void Function(String route) onNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu),
      tooltip: 'Menu',
      offset: const Offset(0, 40),
      onSelected: onNavigate,
      itemBuilder: (context) => [
        _buildMenuItem(Icons.calendar_month, l10n.calendar, '/calendar', currentRoute == '/calendar'),
        _buildMenuItem(Icons.map, l10n.map, '/map', currentRoute.startsWith('/map')),
        _buildMenuItem(Icons.gavel, l10n.constitution, '/constitutional-rights',
            currentRoute == '/constitution' || currentRoute == '/constitutional-rights'),
        _buildMenuItem(Icons.people, l10n.leaders, '/leaders', currentRoute.startsWith('/leaders')),
        _buildMenuItem(Icons.newspaper, 'RONB Feed', '/news', currentRoute == '/news'),
        const PopupMenuDivider(),
        _buildMenuItem(Icons.currency_exchange, l10n.forex, '/forex', currentRoute == '/forex'),
        _buildMenuItem(Icons.diamond, l10n.goldSilver, '/gold-price', currentRoute == '/gold-price'),
        _buildMenuItem(Icons.trending_up, l10n.ipoShares, '/ipo', currentRoute == '/ipo'),
        const PopupMenuDivider(),
        _buildMenuItem(Icons.swap_horiz, l10n.dateConvert, '/date-converter', currentRoute == '/date-converter'),
        _buildMenuItem(Icons.translate, l10n.unicodeConverter, '/unicode', currentRoute == '/unicode'),
        _buildMenuItem(Icons.photo_library, l10n.photoMerger, '/photo-merger', currentRoute == '/photo-merger'),
        _buildMenuItem(Icons.compress, l10n.imageCompressor, '/photo-compress', currentRoute == '/photo-compress'),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(IconData icon, String label, String route, bool isActive) {
    return PopupMenuItem<String>(
      value: route,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isActive ? _brandColor : null),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? _brandColor : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? _brandColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? _brandColor : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? _brandColor : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small icon button for tools in the nav bar
class _ToolIconButton extends StatelessWidget {
  const _ToolIconButton({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = currentRoute == route;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? _brandColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? _brandColor : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
