import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/players_provider.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<PlayersProvider>(context, listen: false).fetchPlayers();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlayersProvider>(context);
    final playersWithSalary = provider.players.where((p) => p.salary != null).toList();
    final double totalPayroll = playersWithSalary.fold(0, (sum, p) => sum + p.salary!);

    return Scaffold(
      backgroundColor: OdinTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FINANCE MANAGER',
              style: TextStyle(
                color: OdinTheme.textTertiary,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text('Command Center'),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: OdinTheme.primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // ─── Main KPI Card ─────────────────────────────
                   Container(
                     width: double.infinity,
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         begin: Alignment.topLeft,
                         end: Alignment.bottomRight,
                         colors: [OdinTheme.primaryBlue, OdinTheme.primaryBlue.withValues(alpha: 0.7)],
                       ),
                       borderRadius: BorderRadius.circular(16),
                     ),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           children: [
                             const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                             const SizedBox(width: 12),
                             const Text(
                               'MASSE SALARIALE GLOBALE',
                               style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                             ),
                           ],
                         ),
                         const SizedBox(height: 16),
                         Text(
                           '${totalPayroll.toStringAsFixed(2)} MAD',
                           style: const TextStyle(
                             color: Colors.white,
                             fontSize: 32,
                             fontWeight: FontWeight.w800,
                           ),
                         ),
                         const SizedBox(height: 8),
                         Text(
                           'Basé sur ${playersWithSalary.length} joueurs sous contrat actif',
                           style: const TextStyle(color: Colors.white70, fontSize: 12),
                         ),
                       ],
                     ),
                   ),

                   const SizedBox(height: 24),

                   // ─── Player Salary List ─────────────────────────────
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       const Text(
                         'DÉTAILS DES CONTRATS',
                         style: TextStyle(
                           color: OdinTheme.textSecondary,
                           fontSize: 12,
                           fontWeight: FontWeight.w600,
                           letterSpacing: 1.5,
                         ),
                       ),
                       TextButton(
                         onPressed: () {},
                         child: const Text('Export PDF', style: TextStyle(color: OdinTheme.primaryBlue, fontSize: 12)),
                       )
                     ],
                   ),
                   const SizedBox(height: 8),
                   
                   if (playersWithSalary.isEmpty)
                     Container(
                       width: double.infinity,
                       padding: const EdgeInsets.all(24),
                       decoration: OdinTheme.glassCard,
                       child: const Center(
                         child: Text('Aucun salaire enregistré.', style: TextStyle(color: OdinTheme.textTertiary)),
                       ),
                     )
                   else
                     ...playersWithSalary.map((p) => Container(
                       margin: const EdgeInsets.only(bottom: 8),
                       padding: const EdgeInsets.all(16),
                       decoration: OdinTheme.glassCard,
                       child: Row(
                         children: [
                           CircleAvatar(
                             radius: 18,
                             backgroundColor: OdinTheme.primaryBlue.withValues(alpha: 0.15),
                             child: const Icon(Icons.person_rounded, color: OdinTheme.primaryBlue, size: 18),
                           ),
                           const SizedBox(width: 14),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   p.fullName,
                                   style: const TextStyle(color: OdinTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                 ),
                                 const SizedBox(height: 4),
                                 Text(
                                   p.position,
                                   style: const TextStyle(color: OdinTheme.textTertiary, fontSize: 12),
                                 ),
                               ],
                             ),
                           ),
                           Text(
                             '${p.salary} MAD',
                             style: const TextStyle(color: OdinTheme.primaryBlue, fontSize: 14, fontWeight: FontWeight.w700),
                           ),
                         ],
                       ),
                     )),
                ],
              ),
            ),
    );
  }
}
