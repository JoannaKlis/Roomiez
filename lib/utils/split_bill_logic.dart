import '../models/expense_history_item.dart';

// --- NOWOŚĆ: Extension do zaokrąglania ---
// Wklej to na samym dole pliku lub na górze, poza klasą
extension DoubleRounding on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}

// Klasa pomocnicza
class Debt {
  final String fromUser;
  final String toUser;
  final double amount;

  Debt({required this.fromUser, required this.toUser, required this.amount});
}

class SplitBillLogic {
  
  static List<Debt> calculateDebts(List<ExpenseHistoryItem> expenses, List<String> allUserIds) {
    Map<String, double> balances = {};

    // Inicjalizacja zerami TYLKO dla obecnych członków
    for (var uid in allUserIds) {
      balances[uid] = 0.0;
    }

    for (var expense in expenses) {
      if (expense.participantsIds.isEmpty) continue;

      double splitAmount = expense.amount / expense.participantsIds.length;

      // 1. Dodajemy płatnikowi (jeśli nadal jest w grupie)
      if (allUserIds.contains(expense.payerId)) {
        balances[expense.payerId] = (balances[expense.payerId] ?? 0.0) + expense.amount;
      }

      // 2. Odejmujemy uczestnikom (tylko tym, którzy są w grupie)
      for (var participantId in expense.participantsIds) {
        if (allUserIds.contains(participantId)) {
          balances[participantId] = (balances[participantId] ?? 0.0) - splitAmount;
        }
      }
    }

    List<MapEntry<String, double>> debtors = [];
    List<MapEntry<String, double>> creditors = [];

    balances.forEach((userId, amount) {
      // UŻYCIE EXTENSION (czyściej i bezpieczniej)
      double val = amount.toPrecision(2);
      
      if (val < -0.01) debtors.add(MapEntry(userId, val)); 
      if (val > 0.01) creditors.add(MapEntry(userId, val));  
    });

    debtors.sort((a, b) => a.value.compareTo(b.value)); 
    creditors.sort((a, b) => b.value.compareTo(a.value)); 

    List<Debt> finalDebts = [];
    int i = 0; 
    int j = 0; 

    while (i < debtors.length && j < creditors.length) {
      var debtor = debtors[i];
      var creditor = creditors[j];

      // UŻYCIE EXTENSION
      double amount = (debtor.value.abs() < creditor.value ? debtor.value.abs() : creditor.value)
          .toPrecision(2);

      if (amount > 0.00) {
        finalDebts.add(Debt(fromUser: debtor.key, toUser: creditor.key, amount: amount));
      }

      // UŻYCIE EXTENSION
      double remainingDebt = (debtor.value + amount).toPrecision(2);
      double remainingCredit = (creditor.value - amount).toPrecision(2);

      if (remainingDebt.abs() < 0.01) {
        i++; 
      } else {
        debtors[i] = MapEntry(debtor.key, remainingDebt); 
      }

      if (remainingCredit.abs() < 0.01) {
        j++; 
      } else {
        creditors[j] = MapEntry(creditor.key, remainingCredit); 
      }
    }

    return finalDebts;
  }

  // Nowa metoda: Szybkie liczenie z gotowej mapy (bez mielenia historii)
  static List<Debt> calculateDebtsFromMap(Map<String, double> balances) {
    List<MapEntry<String, double>> debtors = [];
    List<MapEntry<String, double>> creditors = [];

    balances.forEach((userId, amount) {
      double val = amount.toPrecision(2);
      if (val < -0.01) debtors.add(MapEntry(userId, val));
      if (val > 0.01) creditors.add(MapEntry(userId, val));
    });

    debtors.sort((a, b) => a.value.compareTo(b.value));
    creditors.sort((a, b) => b.value.compareTo(a.value));

    List<Debt> finalDebts = [];
    int i = 0;
    int j = 0;

    while (i < debtors.length && j < creditors.length) {
      var debtor = debtors[i];
      var creditor = creditors[j];

      double amount = (debtor.value.abs() < creditor.value ? debtor.value.abs() : creditor.value)
          .toPrecision(2);

      if (amount > 0.00) {
        finalDebts.add(Debt(fromUser: debtor.key, toUser: creditor.key, amount: amount));
      }

      double remainingDebt = (debtor.value + amount).toPrecision(2);
      double remainingCredit = (creditor.value - amount).toPrecision(2);

      if (remainingDebt.abs() < 0.01) i++;
      else debtors[i] = MapEntry(debtor.key, remainingDebt);

      if (remainingCredit.abs() < 0.01) j++;
      else creditors[j] = MapEntry(creditor.key, remainingCredit);
    }

    return finalDebts;
  }
}