import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../services/finance_store.dart';
import '../theme/finance_theme.dart';
import '../widgets/finance_form_widgets.dart';
import '../widgets/finance_widgets.dart';

class TreasuryScreen extends StatelessWidget {
  const TreasuryScreen({super.key});

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
                    'Liquidity Terminal',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _openAccountDialog(context, store),
                  child: const Text('+ Account'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...store.accounts.map(
              (account) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AccountCard(
                  account: account,
                  onEdit: () =>
                      _openAccountDialog(context, store, current: account),
                  onDelete: () => store.deleteAccount(account.id),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const FinanceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(title: 'Flux Projection'),
                  SizedBox(height: 14),
                  _Bars(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAccountDialog(
    BuildContext context,
    FinanceStore store, {
    TreasuryAccountItem? current,
  }) async {
    final nameController = TextEditingController(text: current?.name ?? '');
    final codeController = TextEditingController(text: current?.code ?? '');
    final balanceController = TextEditingController(
      text: current != null ? current.balance.toStringAsFixed(0) : '',
    );
    bool connected = current?.connected ?? true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FinanceFormSheet(
              title: current == null ? 'Ajouter compte' : 'Modifier compte',
              onSave: () {
                final balance =
                    double.tryParse(balanceController.text.trim()) ?? 0;
                if (current == null) {
                  store.addAccount(
                    nameController.text.trim(),
                    codeController.text.trim(),
                    balance,
                    connected,
                  );
                } else {
                  store.updateAccount(
                    current.id,
                    nameController.text.trim(),
                    codeController.text.trim(),
                    balance,
                    connected,
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
                  FinanceTextField(label: 'Name', controller: nameController),
                  const SizedBox(height: 12),
                  FinanceTextField(label: 'Code', controller: codeController),
                  const SizedBox(height: 20),
                  const FinanceSectionHeader(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'DONNEES FINANCIERES',
                  ),
                  const SizedBox(height: 12),
                  FinanceTextField(
                    label: 'Balance',
                    controller: balanceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    suffix: const Text('DT'),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: FinancePalette.soft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SwitchListTile(
                      value: connected,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      title: const Text('Connected'),
                      onChanged: (value) => setState(() => connected = value),
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
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.onEdit,
    required this.onDelete,
  });

  final TreasuryAccountItem account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return FinanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  account.name,
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
          Text(account.code, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          Text(
            formatCompactMoney(
              account.balance,
              symbol: 'DT',
            ),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: account.connected
                  ? FinancePalette.success.withValues(alpha: 0.14)
                  : FinancePalette.warning.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              account.connected ? 'CONNECTED' : 'MANUAL',
              style: TextStyle(
                color: account.connected
                    ? FinancePalette.success
                    : FinancePalette.warning,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars();

  @override
  Widget build(BuildContext context) {
    const inflow = [0.5, 0.32, 0.82, 0.56, 0.41, 0.95];
    const outflow = [0.28, 0.62, 0.43, 0.31, 0.25, 0.64];

    return SizedBox(
      height: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(inflow.length, (index) {
          return Row(
            children: [
              _OneBar(heightFactor: inflow[index], color: FinancePalette.cyan),
              const SizedBox(width: 4),
              _OneBar(
                heightFactor: outflow[index],
                color: FinancePalette.danger.withValues(alpha: 0.75),
              ),
              const SizedBox(width: 10),
            ],
          );
        }),
      ),
    );
  }
}

class _OneBar extends StatelessWidget {
  const _OneBar({required this.heightFactor, required this.color});

  final double heightFactor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 170 * heightFactor,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
