import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../services/finance_ai_service.dart';
import '../services/finance_store.dart';
import '../theme/finance_theme.dart';
import '../widgets/finance_form_widgets.dart';
import '../widgets/finance_widgets.dart';
import '../../widgets/ai/ai_suggestion_banner.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FinanceStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final forecast = FinanceAiService.instance.buildBudgetForecast(store);
        final optimization =
            FinanceAiService.instance.buildExpenseOptimization(store);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Gestion des Depenses',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                FilledButton(
                  onPressed: () => _openExpenseDialog(context, store),
                  style: FilledButton.styleFrom(
                    backgroundColor: FinancePalette.blue,
                  ),
                  child: const Text('+ Depense'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    label: 'Total depenses',
                    value: formatCompactMoney(
                      store.totalExpenseAmount,
                      symbol: 'DT',
                    ),
                    icon: Icons.money_off_csred_rounded,
                    positive: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricTile(
                    label: 'En attente approbation',
                    value:
                        '${store.expenses.where((e) => e.status.startsWith('PENDING')).length}',
                    icon: Icons.pending_actions_rounded,
                    positive: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AiSuggestionBanner(
              title: '${forecast.title} (AI)',
              message: forecast.summary,
              onTap: () => _openAiDetailsSheet(context, forecast),
            ),
            const SizedBox(height: 10),
            AiSuggestionBanner(
              title: '${optimization.title} (AI)',
              message: optimization.summary,
              onTap: () => _openAiDetailsSheet(context, optimization),
            ),
            const SizedBox(height: 12),
            FinanceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel(
                    title: 'Depenses par categorie',
                    subtitle:
                        'Workflow validation + justificatif PDF + approbation multi-level',
                  ),
                  const SizedBox(height: 12),
                  ...store.expenses.map(
                    (expense) => _ExpenseRow(
                      expense: expense,
                      onEdit: () =>
                          _openExpenseDialog(context, store, current: expense),
                      onDelete: () => store.deleteExpense(expense.id),
                      onSubmit: expense.status == 'DRAFT'
                          ? () => store.submitExpense(expense.id)
                          : null,
                      onApprove: expense.status.startsWith('PENDING')
                          ? () => store.approveExpense(expense.id)
                          : null,
                      onReject: expense.status.startsWith('PENDING')
                          ? () => store.rejectExpense(expense.id)
                          : null,
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
                  Row(
                    children: [
                      const Expanded(
                        child: SectionLabel(
                          title: 'Budget thresholds',
                          subtitle: 'Suivi budget vs utilisation',
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openBudgetDialog(context, store),
                        child: const Text('+ Budget item'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...store.budgets.map(
                    (budget) => _BudgetBar(
                      item: budget,
                      onEdit: () =>
                          _openBudgetDialog(context, store, current: budget),
                      onDelete: () => store.deleteBudget(budget.id),
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

  Future<void> _openExpenseDialog(
    BuildContext context,
    FinanceStore store, {
    ExpenseItem? current,
  }) async {
    final title = TextEditingController(text: current?.title ?? '');
    final season = TextEditingController(text: current?.season ?? '2025/2026');
    final amount = TextEditingController(
      text: current != null ? current.amount.toStringAsFixed(0) : '',
    );
    final justification = TextEditingController(
      text: current?.justificationFile ?? 'invoice.pdf',
    );
    final approvalLevel = TextEditingController(
      text: current != null ? current.approvalLevelRequired.toString() : '2',
    );
    String category = current?.category ?? FinanceStore.expenseCategories.first;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FinanceFormSheet(
              title: current == null ? 'Ajouter depense' : 'Modifier depense',
              onSave: () {
                final amountValue = double.tryParse(amount.text.trim()) ?? 0;
                final approvalValue =
                    int.tryParse(approvalLevel.text.trim()) ?? 1;

                if (current == null) {
                  store.addExpense(
                    category,
                    title.text.trim(),
                    season.text.trim(),
                    amountValue,
                    justification.text.trim(),
                    approvalValue.clamp(1, 3),
                  );
                } else {
                  store.updateExpense(
                    current.id,
                    category,
                    title.text.trim(),
                    season.text.trim(),
                    amountValue,
                    justification.text.trim(),
                    approvalValue.clamp(1, 3),
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
                  FinanceDropdownField(
                    label: 'Categorie',
                    value: category,
                    items: FinanceStore.expenseCategories,
                    onChanged: (value) => setState(() => category = value),
                  ),
                  const SizedBox(height: 12),
                  FinanceTextField(label: 'Libelle depense', controller: title),
                  const SizedBox(height: 12),
                  FinanceTextField(label: 'Saison', controller: season),
                  const SizedBox(height: 20),
                  const FinanceSectionHeader(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'DONNEES FINANCIERES',
                  ),
                  const SizedBox(height: 12),
                  FinanceTextField(
                    label: 'Montant',
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    suffix: const Text('DT'),
                  ),
                  const SizedBox(height: 12),
                  FinanceTextField(
                    label: 'Justificatif PDF (nom fichier)',
                    controller: justification,
                  ),
                  const SizedBox(height: 12),
                  FinanceTextField(
                    label: 'Niveau approbation requis (1-3)',
                    controller: approvalLevel,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openBudgetDialog(
    BuildContext context,
    FinanceStore store, {
    BudgetItemModel? current,
  }) async {
    final label = TextEditingController(text: current?.label ?? '');
    final used = TextEditingController(
      text: current != null ? current.used.toStringAsFixed(1) : '',
    );
    final max = TextEditingController(
      text: current != null ? current.max.toStringAsFixed(1) : '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FinanceFormSheet(
          title: current == null
              ? 'Ajouter seuil budget'
              : 'Modifier seuil budget',
          onSave: () {
            final usedValue = double.tryParse(used.text.trim()) ?? 0;
            final maxValue = double.tryParse(max.text.trim()) ?? 1;
            if (current == null) {
              store.addBudget(label.text.trim(), usedValue, maxValue);
            } else {
              store.updateBudget(
                current.id,
                label.text.trim(),
                usedValue,
                maxValue,
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
              FinanceTextField(label: 'Categorie', controller: label),
              const SizedBox(height: 20),
              const FinanceSectionHeader(
                icon: Icons.account_balance_wallet_outlined,
                label: 'DONNEES FINANCIERES',
              ),
              const SizedBox(height: 12),
              FinanceTextField(
                label: 'Montant utilise',
                controller: used,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffix: const Text('DT'),
              ),
              const SizedBox(height: 12),
              FinanceTextField(
                label: 'Seuil max',
                controller: max,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffix: const Text('DT'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAiDetailsSheet(
    BuildContext context,
    FinanceAiInsight insight,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${insight.title} (AI)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    insight.details,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
    required this.onSubmit,
    required this.onApprove,
    required this.onReject,
  });

  final ExpenseItem expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSubmit;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(expense.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FinancePalette.soft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${expense.title} • ${expense.category}',
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
            'Saison ${expense.season} • Justificatif ${expense.justificationFile}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Montant ${formatCompactMoney(expense.amount, symbol: 'DT')}',
            style: TextStyle(
              color: FinancePalette.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Workflow L${expense.currentApprovalLevel}/${expense.approvalLevelRequired} • ${expense.status}',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onSubmit != null)
                OutlinedButton(
                  onPressed: onSubmit,
                  child: const Text('Submit'),
                ),
              if (onApprove != null)
                FilledButton(
                  onPressed: onApprove,
                  child: const Text('Approve'),
                ),
              if (onReject != null)
                OutlinedButton(
                  onPressed: onReject,
                  child: const Text('Reject'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    if (status == 'APPROVED' || status == 'PAID') return FinancePalette.success;
    if (status == 'REJECTED') return FinancePalette.danger;
    return FinancePalette.warning;
  }
}

class _BudgetBar extends StatelessWidget {
  const _BudgetBar({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetItemModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ratio = (item.used / item.max).clamp(0, 1).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text('${item.used}M DT / ${item.max}M DT'),
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
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: ratio,
              backgroundColor: FinancePalette.soft,
              valueColor: AlwaysStoppedAnimation(
                ratio > 0.85 ? FinancePalette.danger : FinancePalette.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
