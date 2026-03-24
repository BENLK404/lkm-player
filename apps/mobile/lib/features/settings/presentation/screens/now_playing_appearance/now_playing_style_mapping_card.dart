import 'package:flutter/material.dart';

/// Ligne de documentation : clé persistée → effet UI (pour extension / debug).
class StyleMappingEntry {
  const StyleMappingEntry({
    required this.jsonKey,
    required this.description,
    this.unit,
  });

  final String jsonKey;
  final String description;
  final String? unit;
}

/// Cartographie des réglages affichée sur chaque page de style.
class NowPlayingStyleMappingCard extends StatelessWidget {
  const NowPlayingStyleMappingCard({
    super.key,
    required this.styleId,
    required this.entries,
  });

  final String styleId;
  final List<StyleMappingEntry> entries;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(Icons.account_tree_outlined, color: scheme.primary),
        title: const Text('Cartographie des réglages'),
        subtitle: Text(
          'Identifiant : $styleId',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ces clés sont enregistrées dans les préférences (JSON). '
                  'Tu peux les relire côté code ou étendre le modèle.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2.2),
                    1: FlexColumnWidth(3),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.top,
                  children: [
                    TableRow(
                      children: [
                        _th(context, 'Clé JSON'),
                        _th(context, 'Effet'),
                      ],
                    ),
                    ...entries.map(
                      (e) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8,
                              right: 8,
                              bottom: 8,
                            ),
                            child: SelectableText(
                              e.jsonKey,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8),
                            child: Text(
                              e.unit != null
                                  ? '${e.description} (${e.unit})'
                                  : e.description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
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

  Widget _th(BuildContext context, String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        t,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
