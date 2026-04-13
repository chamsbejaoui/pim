import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../services/finance_store.dart';
import '../theme/finance_theme.dart';
import '../widgets/finance_form_widgets.dart';
import '../widgets/finance_widgets.dart';

class TransfersScreen extends StatelessWidget {
  const TransfersScreen({super.key});

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
                    'Gestion des Transferts & Indemnites',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                FilledButton(
                  onPressed: () => _openTransferDialog(context, store),
                  style: FilledButton.styleFrom(
                    backgroundColor: FinancePalette.blue,
                  ),
                  child: const Text('+ Nouveau transfert'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FinanceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel(
                    title: 'Registre transferts',
                    subtitle:
                        'Entrant/sortant, commissions, bonus conditionnels, amortissement',
                  ),
                  const SizedBox(height: 12),
                  ...store.transfers.map(
                    (transfer) => _TransferRow(
                      transfer: transfer,
                      onEdit: () => _openTransferDialog(
                        context,
                        store,
                        current: transfer,
                      ),
                      onDelete: () => store.deleteTransfer(transfer.id),
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
                          title: 'Tranches paiements',
                          subtitle: 'Paiement echelonne + suivi statut',
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openTrancheDialog(context, store),
                        child: const Text('+ Tranche'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...store.tranches.map(
                    (tranche) => _TrancheTile(
                      tranche: tranche,
                      onPay: tranche.status == 'PAID'
                          ? null
                          : () => store.payTranche(tranche.id),
                      onDelete: () => store.deleteTranche(tranche.id),
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

  Future<void> _openTransferDialog(
    BuildContext context,
    FinanceStore store, {
    TransferItem? current,
  }) async {
    final player = TextEditingController(text: current?.player ?? '');
    final totalFee = TextEditingController(
      text: current != null ? current.totalFee.toStringAsFixed(0) : '',
    );
    final contractYears = TextEditingController(
      text: current != null ? current.contractYears.toString() : '5',
    );
    final resalePct = TextEditingController(
      text: current != null
          ? current.resalePercentage.toStringAsFixed(1)
          : '10',
    );
    final conditionalBonus = TextEditingController(
      text: current != null ? current.conditionalBonus.toStringAsFixed(0) : '0',
    );
    final agentCommission = TextEditingController(
      text: current != null ? current.agentCommission.toStringAsFixed(0) : '0',
    );
    String direction = current?.direction ?? 'IN';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FinanceFormSheet(
              title: current == null
                  ? 'Ajouter transfert'
                  : 'Modifier transfert',
              onSave: () {
                final fee = double.tryParse(totalFee.text.trim()) ?? 0;
                final years = int.tryParse(contractYears.text.trim()) ?? 1;
                final resale = double.tryParse(resalePct.text.trim()) ?? 0;
                final bonus =
                    double.tryParse(conditionalBonus.text.trim()) ?? 0;
                final commission =
                    double.tryParse(agentCommission.text.trim()) ?? 0;

                if (current == null) {
                  store.addTransfer(
                    player.text.trim(),
                    direction,
                    fee,
                    years,
                    resale,
                    bonus,
                    commission,
                  );
                } else {
                  store.updateTransfer(
                    current.id,
                    player.text.trim(),
                    direction,
                    fee,
                    years,
                    resale,
                    bonus,
                    commission,
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
                  FinanceTextField(label: 'Joueur', controller: player),
                  const SizedBox(height: 12),
                  FinanceDropdownField(
                    label: 'Direction',
                    value: direction,
                    items: const ['IN', 'OUT'],
                    onChanged: (value) => setState(() => direction = value),
                  ),
                  const SizedBox(height: 20),
                  const FinanceSectionHeader(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'DONNEES FINANCIERES',
                  ),
                  const SizedBox(height: 12),
                  FinanceTextField(
                    label: 'Montant transfert',
                    controller: totalFee,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    suffix: const Text('DT'),
                  ),
                  const SizedBox(height: 12),
                  FinanceTextField(
                    label: 'Duree contrat (annees)',
                    controller: contractYears,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  FinanceTextField(
                    label: '% revente',
                    controller: resalePct,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    suffix: const Text('%'),
                  ),
                  const SizedBox(height: 12),
                  FinanceTextField(
                    label: 'Bonus conditionnels',
                    controller: conditionalBonus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    suffix: const Text('DT'),
                  ),
                  const SizedBox(height: 12),
                  FinanceTextField(
                    label: 'Commission agent',
                    controller: agentCommission,
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
      },
    );
  }

  Future<void> _openTrancheDialog(
    BuildContext context,
    FinanceStore store,
  ) async {
    String? transferId = store.transfers.isNotEmpty
        ? store.transfers.first.id
        : null;
    final club = TextEditingController();
    final amount = TextEditingController();
    final dueDate = TextEditingController(
      text: _formatDate(DateTime.now().add(const Duration(days: 30))),
    );
    bool receivable = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FinanceFormSheet(
              title: 'Ajouter tranche',
              onSave: () {
                if (transferId == null) return;
                final value = double.tryParse(amount.text.trim()) ?? 0;
                final parsedDate =
                    _parseDate(dueDate.text.trim()) ?? DateTime.now();
                store.addTranche(
                  transferId!,
                  club.text.trim(),
                  value,
                  parsedDate,
                  receivable,
                );
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
                    label: 'Transfert',
                    value: transferId,
                    menuItems: store.transfers
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.player),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => transferId = value),
                  ),
                  const SizedBox(height: 12),
                  FinanceTextField(label: 'Club', controller: club),
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
                    label: 'Echeance (dd/MM/yyyy)',
                    controller: dueDate,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: FinancePalette.soft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SwitchListTile(
                      value: receivable,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      title: const Text('Recevable (entrant)'),
                      onChanged: (v) => setState(() => receivable = v),
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

  static String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
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

class _TransferRow extends StatelessWidget {
  const _TransferRow({
    required this.transfer,
    required this.onEdit,
    required this.onDelete,
  });

  final TransferItem transfer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
                  '${transfer.player} • ${transfer.direction == 'IN' ? 'Entrant' : 'Sortant'}',
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
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              Text(
                'Montant ${formatCompactMoney(transfer.totalFee, symbol: 'DT')}',
              ),
              Text(
                'Amortissement/an ${formatCompactMoney(transfer.annualAmortization, symbol: 'DT')}',
              ),
              Text('Revente ${transfer.resalePercentage.toStringAsFixed(1)}%'),
              Text(
                'Bonus ${formatCompactMoney(transfer.conditionalBonus, symbol: 'DT')}',
              ),
              Text(
                'Agent ${formatCompactMoney(transfer.agentCommission, symbol: 'DT')}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrancheTile extends StatelessWidget {
  const _TrancheTile({
    required this.tranche,
    required this.onPay,
    required this.onDelete,
  });

  final TrancheItem tranche;
  final VoidCallback? onPay;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = tranche.status == 'PAID'
        ? FinancePalette.success
        : FinancePalette.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FinancePalette.soft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tranche.club,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${TransfersScreen._formatDate(tranche.dueDate)} • ${tranche.receivable ? 'Receivable' : 'Payable'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCompactMoney(tranche.amount, symbol: 'DT'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: tranche.receivable
                      ? FinancePalette.success
                      : FinancePalette.danger,
                ),
              ),
              Text(
                tranche.status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
          ),
          if (onPay != null)
            TextButton(onPressed: onPay, child: const Text('Pay')),
        ],
      ),
    );
  }
}
