import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../services/finance_store.dart';
import '../theme/finance_theme.dart';
import '../widgets/finance_form_widgets.dart';
import '../widgets/finance_widgets.dart';

class AccountingScreen extends StatelessWidget {
  const AccountingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FinanceStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final trialBalance = store.buildTrialBalance();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Gestion Comptable Generale',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                FilledButton(
                  onPressed: () => _openLedgerDialog(context, store),
                  style: FilledButton.styleFrom(
                    backgroundColor: FinancePalette.blue,
                  ),
                  child: const Text('+ Ecriture manuelle'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _export(context, store, 'PDF'),
                  child: const Text('Export PDF'),
                ),
                OutlinedButton(
                  onPressed: () => _export(context, store, 'Excel'),
                  child: const Text('Export Excel'),
                ),
                OutlinedButton(
                  onPressed: () => _export(context, store, 'FEC'),
                  child: const Text('Export FEC'),
                ),
                OutlinedButton(
                  onPressed: () => _closePeriod(context, store),
                  child: const Text('Cloture mensuelle'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FinanceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: SectionLabel(
                          title: 'Plan comptable (Chart of Accounts)',
                          subtitle: 'CRUD des comptes comptables',
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openAccountPlanDialog(context, store),
                        child: const Text('+ Compte'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...store.chartOfAccounts.map(
                    (account) => _AccountPlanRow(
                      account: account,
                      onEdit: () => _openAccountPlanDialog(
                        context,
                        store,
                        current: account,
                      ),
                      onDelete: () => store.deleteChartAccount(account.id),
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
                    title: 'Journal comptable / Grand livre',
                    subtitle: 'Ecritures automatiques et manuelles',
                  ),
                  const SizedBox(height: 12),
                  ...store.ledger.map(
                    (entry) => _LedgerRow(
                      entry: entry,
                      onEdit: () =>
                          _openLedgerDialog(context, store, current: entry),
                      onPost: entry.status == 'POSTED'
                          ? null
                          : () => store.postLedgerEntry(entry.id),
                      onDelete: () => store.deleteLedger(entry.id),
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
                    title: 'Balance comptable (Trial Balance)',
                    subtitle: 'Debit / credit par compte',
                  ),
                  const SizedBox(height: 10),
                  ...trialBalance.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(line.accountCode)),
                          Expanded(
                            child: Text(
                              formatCompactMoney(line.debit, symbol: 'DT'),
                              textAlign: TextAlign.end,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              formatCompactMoney(line.credit, symbol: 'DT'),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    label: 'Bilan - Actif',
                    value: formatCompactMoney(store.totalAssets, symbol: 'DT'),
                    icon: Icons.account_balance_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricTile(
                    label: 'Bilan - Passif',
                    value: formatCompactMoney(
                      store.totalLiabilitiesAndEquity,
                      symbol: 'DT',
                    ),
                    icon: Icons.balance_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    label: 'Compte resultat - Revenus',
                    value: formatCompactMoney(store.pnlRevenue, symbol: 'DT'),
                    icon: Icons.trending_up_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricTile(
                    label: 'Compte resultat - Charges',
                    value: formatCompactMoney(store.pnlExpenses, symbol: 'DT'),
                    positive: false,
                    icon: Icons.trending_down_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            MetricTile(
              label: 'Resultat net',
              value: formatCompactMoney(store.netResult, symbol: 'DT'),
              positive: store.netResult >= 0,
              icon: Icons.summarize_outlined,
            ),
          ],
        );
      },
    );
  }

  void _export(BuildContext context, FinanceStore store, String kind) {
    store.exportAccountingDocument(kind);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Export $kind genere')));
  }

  void _closePeriod(BuildContext context, FinanceStore store) {
    final month = DateTime.now();
    final label = '${month.month}/${month.year}';
    store.closeAccountingPeriod(label);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cloture comptable effectuee pour $label')),
    );
  }

  Future<void> _openAccountPlanDialog(
    BuildContext context,
    FinanceStore store, {
    AccountPlanItem? current,
  }) async {
    final code = TextEditingController(text: current?.code ?? '');
    final label = TextEditingController(text: current?.label ?? '');
    final parentCode = TextEditingController(text: current?.parentCode ?? '');
    String type = current?.type ?? 'ASSET';
    bool active = current?.active ?? true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FinanceFormSheet(
              title: current == null ? 'Ajouter compte' : 'Modifier compte',
              onSave: () {
                if (current == null) {
                  store.addChartAccount(
                    code.text.trim(),
                    label.text.trim(),
                    type,
                    parentCode: parentCode.text.trim().isEmpty
                        ? null
                        : parentCode.text.trim(),
                  );
                } else {
                  store.updateChartAccount(
                    current.id,
                    code.text.trim(),
                    label.text.trim(),
                    type,
                    parentCode: parentCode.text.trim().isEmpty
                        ? null
                        : parentCode.text.trim(),
                    active: active,
                  );
                }
                Navigator.pop(context);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FinanceSectionHeader(
                    icon: Icons.info_outline_rounded,
                    label: 'INFORMATIONS DE BASE',
                  ),
                  const SizedBox(height: 12),
                  FinanceTextField(label: 'Code', controller: code),
                  const SizedBox(height: 12),
                  FinanceTextField(label: 'Libelle', controller: label),
                  const SizedBox(height: 12),
                  FinanceDropdownField(
                    label: 'Type',
                    value: type,
                    items: const [
                      'ASSET',
                      'LIABILITY',
                      'EQUITY',
                      'REVENUE',
                      'EXPENSE',
                    ],
                    onChanged: (value) => setState(() => type = value),
                  ),
                  const SizedBox(height: 12),
                  FinanceTextField(
                    label: 'Parent code (optionnel)',
                    controller: parentCode,
                  ),
                  const SizedBox(height: 20),
                  const FinanceSectionHeader(
                    icon: Icons.tune_rounded,
                    label: 'PARAMETRES',
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: FinancePalette.soft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SwitchListTile(
                      value: active,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      title: const Text('Actif'),
                      onChanged: (v) => setState(() => active = v),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openLedgerDialog(
    BuildContext context,
    FinanceStore store, {
    LedgerEntryItem? current,
  }) async {
    final date = TextEditingController(
      text: current == null
          ? _formatDate(DateTime.now())
          : _formatDate(current.entryDate),
    );
    final accountCode = TextEditingController(text: current?.accountCode ?? '');
    final description = TextEditingController(text: current?.description ?? '');
    final amount = TextEditingController(
      text: current != null ? current.amount.toStringAsFixed(0) : '',
    );
    String nature = current?.nature ?? 'DEBIT';
    String source = current?.source ?? 'MANUAL';
    String status = current?.status ?? 'DRAFT';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FinanceFormSheet(
              title: current == null ? 'Ajouter ecriture' : 'Modifier ecriture',
              onSave: () {
                final parsedAmount = double.tryParse(amount.text.trim()) ?? 0;
                final parsedDate =
                    _parseDate(date.text.trim()) ?? DateTime.now();
                if (current == null) {
                  store.addLedger(
                    parsedDate,
                    accountCode.text.trim(),
                    description.text.trim(),
                    parsedAmount,
                    nature,
                    source,
                    status,
                  );
                } else {
                  store.updateLedger(
                    current.id,
                    parsedDate,
                    accountCode.text.trim(),
                    description.text.trim(),
                    parsedAmount,
                    nature,
                    source,
                    status,
                  );
                }
                Navigator.pop(context);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FinanceSectionHeader(
                    icon: Icons.info_outline_rounded,
                    label: 'INFORMATIONS DE BASE',
                  ),
                  const SizedBox(height: 12),
                  FinanceTextField(
                    label: 'Date (dd/MM/yyyy)',
                    controller: date,
                  ),
                  const SizedBox(height: 12),
                  FinanceTextField(label: 'Compte', controller: accountCode),
                  const SizedBox(height: 12),
                  FinanceTextField(
                    label: 'Description',
                    controller: description,
                  ),
                  const SizedBox(height: 20),
                  const FinanceSectionHeader(
                    icon: Icons.receipt_long_outlined,
                    label: 'ECRITURE',
                  ),
                  const SizedBox(height: 12),
                  FinanceTextField(
                    label: 'Montant',
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FinanceDropdownField(
                    label: 'Nature',
                    value: nature,
                    items: const ['DEBIT', 'CREDIT'],
                    onChanged: (value) => setState(() => nature = value),
                  ),
                  const SizedBox(height: 12),
                  FinanceDropdownField(
                    label: 'Source',
                    value: source,
                    items: const ['MANUAL', 'AUTO'],
                    onChanged: (value) => setState(() => source = value),
                  ),
                  const SizedBox(height: 12),
                  FinanceDropdownField(
                    label: 'Status',
                    value: status,
                    items: const ['DRAFT', 'POSTED'],
                    onChanged: (value) => setState(() => status = value),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  static DateTime? _parseDate(String input) {
    final parts = input.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }
}

class _AccountPlanRow extends StatelessWidget {
  const _AccountPlanRow({
    required this.account,
    required this.onEdit,
    required this.onDelete,
  });

  final AccountPlanItem account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: FinancePalette.soft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${account.code} - ${account.label}'),
                Text(
                  '${account.type}${account.parentCode != null ? ' • parent ${account.parentCode}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.entry,
    required this.onEdit,
    required this.onPost,
    required this.onDelete,
  });

  final LedgerEntryItem entry;
  final VoidCallback onEdit;
  final VoidCallback? onPost;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FinancePalette.soft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${entry.accountCode} • ${entry.description}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
          Text(
            '${AccountingScreen._formatDate(entry.entryDate)} • ${entry.nature} • ${entry.source} • ${entry.status}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                formatCompactMoney(entry.amount, symbol: 'DT'),
                style: TextStyle(
                  color: entry.nature == 'CREDIT'
                      ? FinancePalette.success
                      : FinancePalette.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (entry.status != 'POSTED')
                TextButton(onPressed: onPost, child: const Text('Post entry')),
            ],
          ),
        ],
      ),
    );
  }
}
