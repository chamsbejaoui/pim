class AccountPlanItem {
  AccountPlanItem({
    required this.id,
    required this.code,
    required this.label,
    required this.type,
    this.parentCode,
    this.active = true,
  });

  final String id;
  String code;
  String label;
  String type;
  String? parentCode;
  bool active;
}

class LedgerEntryItem {
  LedgerEntryItem({
    required this.id,
    required this.entryDate,
    required this.accountCode,
    required this.description,
    required this.amount,
    required this.nature,
    required this.source,
    required this.status,
  });

  final String id;
  DateTime entryDate;
  String accountCode;
  String description;
  double amount;
  String nature;
  String source;
  String status;
}

class SalaryRecord {
  SalaryRecord({
    required this.id,
    required this.employee,
    required this.role,
    required this.fixedSalary,
    required this.matchBonus,
    required this.performanceBonus,
    required this.signingBonus,
    required this.penalties,
    required this.benefits,
    required this.socialContributions,
    required this.taxes,
    required this.status,
    this.lastPaymentDate,
  });

  final String id;
  String employee;
  String role;
  double fixedSalary;
  double matchBonus;
  double performanceBonus;
  double signingBonus;
  double penalties;
  double benefits;
  double socialContributions;
  double taxes;
  String status;
  DateTime? lastPaymentDate;

  double get grossSalary =>
      fixedSalary +
      matchBonus +
      performanceBonus +
      signingBonus +
      benefits -
      penalties;

  double get netToPay => grossSalary - socialContributions - taxes;
}

class SalaryPaymentHistoryItem {
  SalaryPaymentHistoryItem({
    required this.id,
    required this.employee,
    required this.amount,
    required this.paidAt,
    required this.reference,
  });

  final String id;
  String employee;
  double amount;
  DateTime paidAt;
  String reference;
}

class TransferItem {
  TransferItem({
    required this.id,
    required this.player,
    required this.direction,
    required this.totalFee,
    required this.contractYears,
    required this.resalePercentage,
    required this.conditionalBonus,
    required this.agentCommission,
  });

  final String id;
  String player;
  String direction;
  double totalFee;
  int contractYears;
  double resalePercentage;
  double conditionalBonus;
  double agentCommission;

  double get annualAmortization =>
      contractYears <= 0 ? totalFee : totalFee / contractYears;
}

class TrancheItem {
  TrancheItem({
    required this.id,
    required this.transferId,
    required this.club,
    required this.amount,
    required this.dueDate,
    required this.receivable,
    required this.status,
  });

  final String id;
  String transferId;
  String club;
  double amount;
  DateTime dueDate;
  bool receivable;
  String status;
}

class RevenueItem {
  RevenueItem({
    required this.id,
    required this.category,
    required this.title,
    required this.season,
    required this.competition,
    required this.forecastAmount,
    required this.actualAmount,
    required this.entryDate,
  });

  final String id;
  String category;
  String title;
  String season;
  String competition;
  double forecastAmount;
  double actualAmount;
  DateTime entryDate;
}

class ExpenseItem {
  ExpenseItem({
    required this.id,
    required this.category,
    required this.title,
    required this.season,
    required this.amount,
    required this.justificationFile,
    required this.approvalLevelRequired,
    required this.currentApprovalLevel,
    required this.status,
  });

  final String id;
  String category;
  String title;
  String season;
  double amount;
  String justificationFile;
  int approvalLevelRequired;
  int currentApprovalLevel;
  String status;
}

class TreasuryAccountItem {
  TreasuryAccountItem({
    required this.id,
    required this.name,
    required this.code,
    required this.balance,
    required this.connected,
  });

  final String id;
  String name;
  String code;
  double balance;
  bool connected;
}

class BudgetItemModel {
  BudgetItemModel({
    required this.id,
    required this.label,
    required this.used,
    required this.max,
  });

  final String id;
  String label;
  double used;
  double max;
}

class AuditItem {
  AuditItem({
    required this.id,
    required this.message,
    required this.actor,
    required this.time,
    required this.human,
  });

  final String id;
  String message;
  String actor;
  String time;
  bool human;
}

class TrialBalanceLine {
  TrialBalanceLine({
    required this.accountCode,
    required this.debit,
    required this.credit,
  });

  final String accountCode;
  final double debit;
  final double credit;
}
