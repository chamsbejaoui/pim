import 'package:flutter/material.dart';

import '../services/finance_store.dart';
import '../theme/finance_theme.dart';
import '../widgets/finance_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FinanceStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final totalCash =
            store.treasuryBalance +
            store.totalRevenueActual -
            store.totalSalaryExpense;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
          children: [
            Text(
              'Finance Dashboard',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Vision globale: compta, paie, transferts, revenus, depenses',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: FinancePalette.ink.withValues(alpha: 0.58),
              ),
            ),
            const SizedBox(height: 16),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.28,
              ),
              children: [
                MetricTile(
                  label: 'Total Cash',
                  value: formatCompactMoney(totalCash, symbol: 'DT'),
                  icon: Icons.account_balance_wallet_outlined,
                ),
                MetricTile(
                  label: 'Revenus (Actual)',
                  value: formatCompactMoney(
                    store.totalRevenueActual,
                    symbol: 'DT',
                  ),
                  delta: '${store.revenues.length} lignes',
                  icon: Icons.trending_up_rounded,
                ),
                MetricTile(
                  label: 'Paie (Net)',
                  value: formatCompactMoney(
                    store.totalSalaryExpense,
                    symbol: 'DT',
                  ),
                  delta: '${store.salaries.length} fiches',
                  positive: false,
                  icon: Icons.payments_outlined,
                ),
                MetricTile(
                  label: 'Exposition transferts',
                  value: formatCompactMoney(
                    store.totalTransferExposure,
                    symbol: 'DT',
                  ),
                  positive: false,
                  icon: Icons.swap_horiz_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            FinanceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel(
                    title: 'Revenus recents',
                    subtitle: 'Categories + forecast vs actual',
                  ),
                  const SizedBox(height: 12),
                  ...store.revenues
                      .take(6)
                      .map(
                        (revenue) => _TxnRow(
                          label: '${revenue.title} (${revenue.category})',
                          type: '${revenue.season} • ${revenue.competition}',
                          amount:
                              '+${formatCompactMoney(revenue.actualAmount, symbol: 'DT')}',
                          positive: true,
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FinanceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel(
                    title: 'Depenses critiques',
                    subtitle: 'Workflow d\'approbation',
                  ),
                  const SizedBox(height: 12),
                  ...store.expenses
                      .take(6)
                      .map(
                        (expense) => _TxnRow(
                          label: '${expense.title} (${expense.category})',
                          type: expense.status,
                          amount:
                              '-${formatCompactMoney(expense.amount, symbol: 'DT')}',
                          positive: false,
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

class _TxnRow extends StatelessWidget {
  const _TxnRow({
    required this.label,
    required this.type,
    required this.amount,
    required this.positive,
  });

  final String label;
  final String type;
  final String amount;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: positive
                  ? FinancePalette.success.withValues(alpha: 0.12)
                  : FinancePalette.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              positive ? Icons.north_east_rounded : Icons.south_east_rounded,
              color: positive ? FinancePalette.success : FinancePalette.danger,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  type,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: FinancePalette.ink.withValues(alpha: 0.56),
                  ),
                ),
              ],
            ),
          ),
          AmountTag(amount: amount, positive: positive),
        ],
      ),
    );
  }
}
