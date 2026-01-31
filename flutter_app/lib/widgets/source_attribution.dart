import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A small footer widget showing the official source for government data
class SourceAttribution extends StatelessWidget {
  final String sourceName;
  final String sourceUrl;

  const SourceAttribution({
    super.key,
    required this.sourceName,
    required this.sourceUrl,
  });

  // Pre-defined sources for common government data
  const SourceAttribution.constitution({super.key})
      : sourceName = 'Nepal Law Commission',
        sourceUrl = 'https://lawcommission.gov.np/en/?cat=89';

  const SourceAttribution.election({super.key})
      : sourceName = 'Election Commission of Nepal',
        sourceUrl = 'https://election.gov.np';

  const SourceAttribution.forex({super.key})
      : sourceName = 'Nepal Rastra Bank',
        sourceUrl = 'https://www.nrb.org.np/forex/';

  const SourceAttribution.bullion({super.key})
      : sourceName = 'FENEGOSIDA',
        sourceUrl = 'https://www.fenegosida.org/';

  const SourceAttribution.nepse({super.key})
      : sourceName = 'Nepal Stock Exchange',
        sourceUrl = 'https://nepalstock.com.np/';

  const SourceAttribution.government({super.key})
      : sourceName = 'Government of Nepal',
        sourceUrl = 'https://nepal.gov.np';

  const SourceAttribution.localBodies({super.key})
      : sourceName = 'Local Level Portal',
        sourceUrl = 'https://sthaniya.gov.np';

  const SourceAttribution.osm({super.key})
      : sourceName = 'OpenStreetMap contributors',
        sourceUrl = 'https://www.openstreetmap.org/copyright';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_outlined,
            size: 14,
            color: colorScheme.outline,
          ),
          const SizedBox(width: 6),
          Text(
            'Source: ',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.outline,
            ),
          ),
          GestureDetector(
            onTap: _openSource,
            child: Text(
              sourceName,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _openSource,
            child: Icon(
              Icons.open_in_new,
              size: 12,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSource() async {
    final uri = Uri.parse(sourceUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
