import 'package:flutter/material.dart';

import '../services/finance_store.dart';
import '../theme/finance_theme.dart';
import '../widgets/finance_widgets.dart';

class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FinanceStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Compliance Ledger',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: FinancePalette.blue,
                  ),
                  child: const Text('Finalize Audit'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FinanceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel(
                    title: 'System Audit Trail',
                    subtitle: 'Immutable local action log',
                  ),
                  const SizedBox(height: 14),
                  ...store.audits.map(
                    (log) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: log.human
                                  ? FinancePalette.blue.withValues(alpha: 0.14)
                                  : FinancePalette.soft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              log.human ? Icons.person : Icons.settings,
                              size: 17,
                              color: log.human
                                  ? FinancePalette.blue
                                  : FinancePalette.ink,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.message,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(
                                  '${log.actor} • ${log.time}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: FinancePalette.ink.withValues(
                                          alpha: 0.56,
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
