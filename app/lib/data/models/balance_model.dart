class BalanceModel {
  final int cashBalance;
  final int onlineBalance;

  BalanceModel({required this.cashBalance, required this.onlineBalance});

  int get totalBalance => cashBalance + onlineBalance;

  factory BalanceModel.fromJson(Map<String, dynamic> json) {
    return BalanceModel(
      cashBalance: json['cashBalance'] ?? 0,
      onlineBalance: json['onlineBalance'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'cashBalance': cashBalance,
    'onlineBalance': onlineBalance,
  };
}
