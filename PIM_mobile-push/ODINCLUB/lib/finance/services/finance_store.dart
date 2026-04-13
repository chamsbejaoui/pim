import 'package:flutter/foundation.dart';

import '../models/finance_models.dart';

class FinanceStore extends ChangeNotifier {
  FinanceStore._();
  static final FinanceStore instance = FinanceStore._();

  int _id = 1000;
  String _nextId() => (++_id).toString();

  static const revenueCategories = [
    'BILLETTERIE',
    'SPONSORING',
    'DROITS_TV',
    'MERCHANDISING',
    'SUBVENTIONS',
    'ACADEMY_FEES',
    'PRIZE_MONEY',
  ];

  static const expenseCategories = [
    'SALAIRES_JOUEURS',
    'STAFF_TECHNIQUE',
    'MEDICAL',
    'TRANSPORT',
    'HEBERGEMENT',
    'EQUIPEMENT',
    'MAINTENANCE_STADE',
    'FORMATION_JEUNES',
    'MARKETING',
  ];

  final List<AccountPlanItem> chartOfAccounts = [
    AccountPlanItem(
      id: 'a1',
      code: '101000',
      label: 'Capital social',
      type: 'EQUITY',
    ),
    AccountPlanItem(
      id: 'a2',
      code: '213000',
      label: 'Immobilisation joueurs',
      type: 'ASSET',
    ),
    AccountPlanItem(
      id: 'a3',
      code: '401000',
      label: 'Fournisseurs',
      type: 'LIABILITY',
    ),
    AccountPlanItem(id: 'a4', code: '512000', label: 'Banque', type: 'ASSET'),
    AccountPlanItem(
      id: 'a5',
      code: '641000',
      label: 'Salaires',
      type: 'EXPENSE',
    ),
    AccountPlanItem(
      id: 'a6',
      code: '622000',
      label: 'Commissions agents',
      type: 'EXPENSE',
    ),
    AccountPlanItem(
      id: 'a7',
      code: '706000',
      label: 'Sponsoring',
      type: 'REVENUE',
    ),
    AccountPlanItem(
      id: 'a8',
      code: '707000',
      label: 'Billetterie',
      type: 'REVENUE',
    ),
  ];

  final List<LedgerEntryItem> ledger = [
    LedgerEntryItem(
      id: 'l1',
      entryDate: DateTime.now().subtract(const Duration(days: 2)),
      accountCode: '641000',
      description: 'Base Salaries - Senior Squad',
      amount: 2450000,
      nature: 'DEBIT',
      source: 'AUTO',
      status: 'POSTED',
    ),
    LedgerEntryItem(
      id: 'l2',
      entryDate: DateTime.now().subtract(const Duration(days: 1)),
      accountCode: '706000',
      description: 'Sponsorship - Emirates Monthly',
      amount: 3000000,
      nature: 'CREDIT',
      source: 'AUTO',
      status: 'POSTED',
    ),
  ];

  final List<SalaryRecord> salaries = [
    SalaryRecord(
      id: 'p1',
      employee: 'Vinicius Junior',
      role: 'PLAYER',
      fixedSalary: 800000,
      matchBonus: 40000,
      performanceBonus: 110000,
      signingBonus: 0,
      penalties: 0,
      benefits: 25000,
      socialContributions: 145000,
      taxes: 280000,
      status: 'READY',
    ),
    SalaryRecord(
      id: 'p2',
      employee: 'Carlo Ancelotti',
      role: 'HEAD_COACH',
      fixedSalary: 500000,
      matchBonus: 0,
      performanceBonus: 50000,
      signingBonus: 0,
      penalties: 0,
      benefits: 20000,
      socialContributions: 85000,
      taxes: 140000,
      status: 'PAID',
      lastPaymentDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  final List<SalaryPaymentHistoryItem> salaryPayments = [
    SalaryPaymentHistoryItem(
      id: 'ph1',
      employee: 'Carlo Ancelotti',
      amount: 345000,
      paidAt: DateTime.now().subtract(const Duration(days: 2)),
      reference: 'PAY-2026-0001',
    ),
  ];

  final List<TransferItem> transfers = [
    TransferItem(
      id: 't1',
      player: 'Jude Bellingham',
      direction: 'IN',
      totalFee: 103000000,
      contractYears: 6,
      resalePercentage: 10,
      conditionalBonus: 5000000,
      agentCommission: 3000000,
    ),
    TransferItem(
      id: 't2',
      player: 'Young Prospect X',
      direction: 'OUT',
      totalFee: 18000000,
      contractYears: 1,
      resalePercentage: 15,
      conditionalBonus: 1200000,
      agentCommission: 600000,
    ),
  ];

  final List<TrancheItem> tranches = [
    TrancheItem(
      id: 'tr1',
      transferId: 't1',
      club: 'B. Dortmund',
      amount: 25000000,
      dueDate: DateTime(2026, 3, 15),
      receivable: false,
      status: 'UPCOMING',
    ),
    TrancheItem(
      id: 'tr2',
      transferId: 't1',
      club: 'B. Dortmund',
      amount: 20000000,
      dueDate: DateTime(2026, 7, 15),
      receivable: false,
      status: 'UPCOMING',
    ),
    TrancheItem(
      id: 'tr3',
      transferId: 't2',
      club: 'Al Hilal',
      amount: 4000000,
      dueDate: DateTime(2026, 6, 20),
      receivable: true,
      status: 'UPCOMING',
    ),
  ];

  final List<RevenueItem> revenues = [
    RevenueItem(
      id: 'r1',
      category: 'SPONSORING',
      title: 'Fly Emirates Main Deal',
      season: '2025/2026',
      competition: 'ALL',
      forecastAmount: 5200000,
      actualAmount: 5000000,
      entryDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
    RevenueItem(
      id: 'r2',
      category: 'BILLETTERIE',
      title: 'UCL Quarter Final',
      season: '2025/2026',
      competition: 'UCL',
      forecastAmount: 1400000,
      actualAmount: 1320000,
      entryDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final List<ExpenseItem> expenses = [
    ExpenseItem(
      id: 'e1',
      category: 'TRANSPORT',
      title: 'Away match travel package',
      season: '2025/2026',
      amount: 220000,
      justificationFile: 'invoice-transport-021.pdf',
      approvalLevelRequired: 2,
      currentApprovalLevel: 1,
      status: 'PENDING_L2',
    ),
    ExpenseItem(
      id: 'e2',
      category: 'MEDICAL',
      title: 'Rehabilitation equipment',
      season: '2025/2026',
      amount: 85000,
      justificationFile: 'invoice-med-004.pdf',
      approvalLevelRequired: 1,
      currentApprovalLevel: 1,
      status: 'APPROVED',
    ),
  ];

  final List<TreasuryAccountItem> accounts = [
    TreasuryAccountItem(
      id: '50',
      name: 'Santander',
      code: 'TND •••• 8842',
      balance: 24500000,
      connected: true,
    ),
    TreasuryAccountItem(
      id: '51',
      name: 'BNP Paribas',
      code: 'TND •••• 1129',
      balance: 12100000,
      connected: true,
    ),
    TreasuryAccountItem(
      id: '52',
      name: 'Petty Cash Vault',
      code: 'Office Secure',
      balance: 45000,
      connected: false,
    ),
  ];

  final List<BudgetItemModel> budgets = [
    BudgetItemModel(
      id: '60',
      label: 'Senior Team Operations',
      used: 42.1,
      max: 55,
    ),
    BudgetItemModel(id: '61', label: 'Youth Academy', used: 8.4, max: 12),
    BudgetItemModel(id: '62', label: 'Medical & Health', used: 4.2, max: 5),
  ];

  final List<AuditItem> audits = [
    AuditItem(
      id: '70',
      message: 'Modified Ledger Entry #TX-992',
      actor: 'Sarah Accountant',
      time: '10 min ago',
      human: true,
    ),
    AuditItem(
      id: '71',
      message: 'Approved Payroll Cycle Feb 2026',
      actor: 'Marco Silva (Admin)',
      time: '2 hours ago',
      human: false,
    ),
  ];

  List<TrialBalanceLine> buildTrialBalance() {
    final grouped = <String, List<double>>{};
    for (final entry in ledger.where((e) => e.status == 'POSTED')) {
      final debit = entry.nature == 'DEBIT' ? entry.amount : 0.0;
      final credit = entry.nature == 'CREDIT' ? entry.amount : 0.0;
      final values = grouped.putIfAbsent(entry.accountCode, () => [0.0, 0.0]);
      values[0] += debit;
      values[1] += credit;
    }

    final lines = grouped.entries
        .map(
          (e) => TrialBalanceLine(
            accountCode: e.key,
            debit: e.value[0],
            credit: e.value[1],
          ),
        )
        .toList();

    lines.sort((a, b) => a.accountCode.compareTo(b.accountCode));
    return lines;
  }

  double get pnlRevenue {
    return ledger
        .where((e) => e.status == 'POSTED' && e.accountCode.startsWith('7'))
        .fold(
          0.0,
          (sum, e) => sum + (e.nature == 'CREDIT' ? e.amount : -e.amount),
        );
  }

  double get pnlExpenses {
    return ledger
        .where((e) => e.status == 'POSTED' && e.accountCode.startsWith('6'))
        .fold(
          0.0,
          (sum, e) => sum + (e.nature == 'DEBIT' ? e.amount : -e.amount),
        );
  }

  double get netResult => pnlRevenue - pnlExpenses;

  double get totalAssets {
    return ledger.where((e) => e.status == 'POSTED').fold(0.0, (sum, e) {
      if (e.accountCode.startsWith('1') ||
          e.accountCode.startsWith('2') ||
          e.accountCode.startsWith('5')) {
        return sum + (e.nature == 'DEBIT' ? e.amount : -e.amount);
      }
      return sum;
    });
  }

  double get totalLiabilitiesAndEquity {
    return ledger.where((e) => e.status == 'POSTED').fold(0.0, (sum, e) {
      if (e.accountCode.startsWith('3') || e.accountCode.startsWith('4')) {
        return sum + (e.nature == 'CREDIT' ? e.amount : -e.amount);
      }
      return sum;
    });
  }

  void exportAccountingDocument(String kind) {
    _audit('Export generated: $kind', true);
    notifyListeners();
  }

  void closeAccountingPeriod(String periodLabel) {
    _audit('Monthly/Annual close completed for $periodLabel', false);
    notifyListeners();
  }

  void addChartAccount(
    String code,
    String label,
    String type, {
    String? parentCode,
  }) {
    chartOfAccounts.insert(
      0,
      AccountPlanItem(
        id: _nextId(),
        code: code,
        label: label,
        type: type,
        parentCode: parentCode,
      ),
    );
    _audit('Chart account created: $code - $label', true);
    notifyListeners();
  }

  void updateChartAccount(
    String id,
    String code,
    String label,
    String type, {
    String? parentCode,
    required bool active,
  }) {
    final account = chartOfAccounts.firstWhere((a) => a.id == id);
    account.code = code;
    account.label = label;
    account.type = type;
    account.parentCode = parentCode;
    account.active = active;
    _audit('Chart account updated: $code', true);
    notifyListeners();
  }

  void deleteChartAccount(String id) {
    final removed = chartOfAccounts.where((a) => a.id == id).toList();
    chartOfAccounts.removeWhere((a) => a.id == id);
    _audit(
      'Chart account deleted: ${removed.isNotEmpty ? removed.first.code : id}',
      true,
    );
    notifyListeners();
  }

  void addLedger(
    DateTime entryDate,
    String accountCode,
    String description,
    double amount,
    String nature,
    String source,
    String status,
  ) {
    ledger.insert(
      0,
      LedgerEntryItem(
        id: _nextId(),
        entryDate: entryDate,
        accountCode: accountCode,
        description: description,
        amount: amount,
        nature: nature,
        source: source,
        status: status,
      ),
    );
    _audit('Journal entry added: $accountCode', true);
    notifyListeners();
  }

  void updateLedger(
    String id,
    DateTime entryDate,
    String accountCode,
    String description,
    double amount,
    String nature,
    String source,
    String status,
  ) {
    final item = ledger.firstWhere((l) => l.id == id);
    item.entryDate = entryDate;
    item.accountCode = accountCode;
    item.description = description;
    item.amount = amount;
    item.nature = nature;
    item.source = source;
    item.status = status;
    _audit('Journal entry updated: $accountCode', true);
    notifyListeners();
  }

  void postLedgerEntry(String id) {
    final item = ledger.firstWhere((l) => l.id == id);
    item.status = 'POSTED';
    _audit('Journal entry posted: ${item.accountCode}', true);
    notifyListeners();
  }

  void deleteLedger(String id) {
    ledger.removeWhere((l) => l.id == id);
    _audit('Journal entry deleted', true);
    notifyListeners();
  }

  void addSalary(
    String employee,
    String role,
    double fixedSalary,
    double matchBonus,
    double performanceBonus,
    double signingBonus,
    double penalties,
    double benefits,
    double socialContributions,
    double taxes,
    String status,
  ) {
    salaries.insert(
      0,
      SalaryRecord(
        id: _nextId(),
        employee: employee,
        role: role,
        fixedSalary: fixedSalary,
        matchBonus: matchBonus,
        performanceBonus: performanceBonus,
        signingBonus: signingBonus,
        penalties: penalties,
        benefits: benefits,
        socialContributions: socialContributions,
        taxes: taxes,
        status: status,
      ),
    );
    _audit('Payroll record added: $employee', true);
    notifyListeners();
  }

  void updateSalary(
    String id,
    String employee,
    String role,
    double fixedSalary,
    double matchBonus,
    double performanceBonus,
    double signingBonus,
    double penalties,
    double benefits,
    double socialContributions,
    double taxes,
    String status,
  ) {
    final salary = salaries.firstWhere((s) => s.id == id);
    salary.employee = employee;
    salary.role = role;
    salary.fixedSalary = fixedSalary;
    salary.matchBonus = matchBonus;
    salary.performanceBonus = performanceBonus;
    salary.signingBonus = signingBonus;
    salary.penalties = penalties;
    salary.benefits = benefits;
    salary.socialContributions = socialContributions;
    salary.taxes = taxes;
    salary.status = status;
    _audit('Payroll record updated: $employee', true);
    notifyListeners();
  }

  void markSalaryPaid(String id) {
    final salary = salaries.firstWhere((s) => s.id == id);
    salary.status = 'PAID';
    salary.lastPaymentDate = DateTime.now();
    salaryPayments.insert(
      0,
      SalaryPaymentHistoryItem(
        id: _nextId(),
        employee: salary.employee,
        amount: salary.netToPay,
        paidAt: DateTime.now(),
        reference: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
    _audit('Payroll paid: ${salary.employee}', true);
    notifyListeners();
  }

  void generatePayslip(String id) {
    final salary = salaries.firstWhere((s) => s.id == id);
    _audit('Payslip generated (PDF): ${salary.employee}', true);
    notifyListeners();
  }

  void exportPayrollBankBatch() {
    _audit('Bank transfer export generated for payroll', true);
    notifyListeners();
  }

  void deleteSalary(String id) {
    salaries.removeWhere((s) => s.id == id);
    _audit('Payroll record deleted', true);
    notifyListeners();
  }

  void addTransfer(
    String player,
    String direction,
    double totalFee,
    int contractYears,
    double resalePercentage,
    double conditionalBonus,
    double agentCommission,
  ) {
    transfers.insert(
      0,
      TransferItem(
        id: _nextId(),
        player: player,
        direction: direction,
        totalFee: totalFee,
        contractYears: contractYears,
        resalePercentage: resalePercentage,
        conditionalBonus: conditionalBonus,
        agentCommission: agentCommission,
      ),
    );
    _audit('Transfer created: $player', true);
    notifyListeners();
  }

  void updateTransfer(
    String id,
    String player,
    String direction,
    double totalFee,
    int contractYears,
    double resalePercentage,
    double conditionalBonus,
    double agentCommission,
  ) {
    final transfer = transfers.firstWhere((t) => t.id == id);
    transfer.player = player;
    transfer.direction = direction;
    transfer.totalFee = totalFee;
    transfer.contractYears = contractYears;
    transfer.resalePercentage = resalePercentage;
    transfer.conditionalBonus = conditionalBonus;
    transfer.agentCommission = agentCommission;
    _audit('Transfer updated: $player', true);
    notifyListeners();
  }

  void deleteTransfer(String id) {
    transfers.removeWhere((t) => t.id == id);
    tranches.removeWhere((t) => t.transferId == id);
    _audit('Transfer deleted', true);
    notifyListeners();
  }

  void addTranche(
    String transferId,
    String club,
    double amount,
    DateTime dueDate,
    bool receivable,
  ) {
    tranches.insert(
      0,
      TrancheItem(
        id: _nextId(),
        transferId: transferId,
        club: club,
        amount: amount,
        dueDate: dueDate,
        receivable: receivable,
        status: 'UPCOMING',
      ),
    );
    _audit('Transfer tranche added: $club', true);
    notifyListeners();
  }

  void payTranche(String id) {
    final tranche = tranches.firstWhere((t) => t.id == id);
    tranche.status = 'PAID';
    _audit('Transfer tranche paid: ${tranche.club}', true);
    notifyListeners();
  }

  void deleteTranche(String id) {
    tranches.removeWhere((t) => t.id == id);
    _audit('Transfer tranche deleted', true);
    notifyListeners();
  }

  void addRevenue(
    String category,
    String title,
    String season,
    String competition,
    double forecastAmount,
    double actualAmount,
  ) {
    revenues.insert(
      0,
      RevenueItem(
        id: _nextId(),
        category: category,
        title: title,
        season: season,
        competition: competition,
        forecastAmount: forecastAmount,
        actualAmount: actualAmount,
        entryDate: DateTime.now(),
      ),
    );
    _audit('Revenue created: $title', true);
    notifyListeners();
  }

  void updateRevenue(
    String id,
    String category,
    String title,
    String season,
    String competition,
    double forecastAmount,
    double actualAmount,
  ) {
    final revenue = revenues.firstWhere((r) => r.id == id);
    revenue.category = category;
    revenue.title = title;
    revenue.season = season;
    revenue.competition = competition;
    revenue.forecastAmount = forecastAmount;
    revenue.actualAmount = actualAmount;
    _audit('Revenue updated: $title', true);
    notifyListeners();
  }

  void deleteRevenue(String id) {
    revenues.removeWhere((r) => r.id == id);
    _audit('Revenue deleted', true);
    notifyListeners();
  }

  void addExpense(
    String category,
    String title,
    String season,
    double amount,
    String justificationFile,
    int approvalLevelRequired,
  ) {
    expenses.insert(
      0,
      ExpenseItem(
        id: _nextId(),
        category: category,
        title: title,
        season: season,
        amount: amount,
        justificationFile: justificationFile,
        approvalLevelRequired: approvalLevelRequired,
        currentApprovalLevel: 0,
        status: 'DRAFT',
      ),
    );
    _audit('Expense created: $title', true);
    notifyListeners();
  }

  void updateExpense(
    String id,
    String category,
    String title,
    String season,
    double amount,
    String justificationFile,
    int approvalLevelRequired,
  ) {
    final expense = expenses.firstWhere((e) => e.id == id);
    expense.category = category;
    expense.title = title;
    expense.season = season;
    expense.amount = amount;
    expense.justificationFile = justificationFile;
    expense.approvalLevelRequired = approvalLevelRequired;
    _audit('Expense updated: $title', true);
    notifyListeners();
  }

  void submitExpense(String id) {
    final expense = expenses.firstWhere((e) => e.id == id);
    expense.currentApprovalLevel = 1;
    expense.status = expense.approvalLevelRequired > 1
        ? 'PENDING_L2'
        : 'PENDING_L1';
    _audit('Expense submitted for approval: ${expense.title}', true);
    notifyListeners();
  }

  void approveExpense(String id) {
    final expense = expenses.firstWhere((e) => e.id == id);
    if (expense.currentApprovalLevel < expense.approvalLevelRequired) {
      expense.currentApprovalLevel += 1;
    }

    if (expense.currentApprovalLevel >= expense.approvalLevelRequired) {
      expense.status = 'APPROVED';
    } else {
      expense.status = 'PENDING_L${expense.currentApprovalLevel + 1}';
    }
    _audit('Expense approval progressed: ${expense.title}', true);
    notifyListeners();
  }

  void rejectExpense(String id) {
    final expense = expenses.firstWhere((e) => e.id == id);
    expense.status = 'REJECTED';
    _audit('Expense rejected: ${expense.title}', true);
    notifyListeners();
  }

  void deleteExpense(String id) {
    expenses.removeWhere((e) => e.id == id);
    _audit('Expense deleted', true);
    notifyListeners();
  }

  void addAccount(String name, String code, double balance, bool connected) {
    accounts.insert(
      0,
      TreasuryAccountItem(
        id: _nextId(),
        name: name,
        code: code,
        balance: balance,
        connected: connected,
      ),
    );
    _audit('Treasury account added: $name', true);
    notifyListeners();
  }

  void updateAccount(
    String id,
    String name,
    String code,
    double balance,
    bool connected,
  ) {
    final account = accounts.firstWhere((a) => a.id == id);
    account.name = name;
    account.code = code;
    account.balance = balance;
    account.connected = connected;
    _audit('Treasury account updated: $name', true);
    notifyListeners();
  }

  void deleteAccount(String id) {
    accounts.removeWhere((a) => a.id == id);
    _audit('Treasury account deleted', true);
    notifyListeners();
  }

  void addBudget(String label, double used, double max) {
    budgets.insert(
      0,
      BudgetItemModel(id: _nextId(), label: label, used: used, max: max),
    );
    _audit('Budget threshold added: $label', true);
    notifyListeners();
  }

  void updateBudget(String id, String label, double used, double max) {
    final budget = budgets.firstWhere((b) => b.id == id);
    budget.label = label;
    budget.used = used;
    budget.max = max;
    _audit('Budget threshold updated: $label', true);
    notifyListeners();
  }

  void deleteBudget(String id) {
    budgets.removeWhere((b) => b.id == id);
    _audit('Budget threshold deleted', true);
    notifyListeners();
  }

  void _audit(String message, bool human) {
    audits.insert(
      0,
      AuditItem(
        id: _nextId(),
        message: message,
        actor: human ? 'UI Operator' : 'System',
        time: 'Just now',
        human: human,
      ),
    );
    if (audits.length > 120) {
      audits.removeLast();
    }
  }

  double get totalRevenueActual =>
      revenues.fold(0.0, (sum, e) => sum + e.actualAmount);
  double get totalRevenueForecast =>
      revenues.fold(0.0, (sum, e) => sum + e.forecastAmount);
  double get totalSalaryExpense =>
      salaries.fold(0.0, (sum, e) => sum + e.netToPay);
  double get totalExpenseAmount =>
      expenses.fold(0.0, (sum, e) => sum + e.amount);
  double get treasuryBalance => accounts.fold(0.0, (sum, e) => sum + e.balance);
  double get totalTransferExposure => tranches
      .where((t) => t.status != 'PAID' && !t.receivable)
      .fold(0.0, (sum, t) => sum + t.amount);
}
