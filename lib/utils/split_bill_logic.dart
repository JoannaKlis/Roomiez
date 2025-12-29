import '../models/expense_history_item.dart';

// Klasa pomocnicza reprezentująca pojedynczy dług (kto, komu, ile)
class Debt {
  final String fromUser; // Dłużnik
  final String toUser;   // Wierzyciel
  final double amount;   // Kwota

  Debt({required this.fromUser, required this.toUser, required this.amount});
}

class SplitBillLogic {
  
  // Główna metoda implementująca algorytm z PDF
  static List<Debt> calculateDebts(List<ExpenseHistoryItem> expenses, List<String> allUserIds) {
    
    // KROK 1 & 2 (wg PDF): Oblicz Bilans Netto dla każdej osoby
    // Bilans = (To co zapłaciłem) - (Mój udział w kosztach)
    Map<String, double> balances = {};

    // Inicjalizacja zerami
    for (var uid in allUserIds) {
      balances[uid] = 0.0;
    }

    for (var expense in expenses) {
      // Jeśli wydatek nie ma uczestników, pomiń go (zabezpieczenie)
      if (expense.participantsIds.isEmpty) continue;

      double splitAmount = expense.amount / expense.participantsIds.length;

      // Dodajemy temu, kto zapłacił (on jest "na plusie" względem grupy)
      balances[expense.payerId] = (balances[expense.payerId] ?? 0.0) + expense.amount;

      // Odejmujemy uczestnikom (oni są "na minusie", bo skonsumowali)
      for (var participantId in expense.participantsIds) {
        balances[participantId] = (balances[participantId] ?? 0.0) - splitAmount;
      }
    }

    // KROK 3 (wg PDF): Podział na Dłużników i Wierzycieli
    List<MapEntry<String, double>> debtors = [];
    List<MapEntry<String, double>> creditors = [];

    balances.forEach((userId, amount) {
      // Zaokrąglamy do 2 miejsc po przecinku, by uniknąć błędów zmiennoprzecinkowych
      double val = double.parse(amount.toStringAsFixed(2));
      
      if (val < -0.01) debtors.add(MapEntry(userId, val)); // Ujemny bilans = Dłużnik
      if (val > 0.01) creditors.add(MapEntry(userId, val));  // Dodatni bilans = Wierzyciel
    });

    // KROK 4 (wg PDF): Sortowanie list (Klucz do minimalizacji przelewów)
    // Dłużnicy: od największego długu (najmniejsza liczba ujemna)
    debtors.sort((a, b) => a.value.compareTo(b.value)); 
    // Wierzyciele: od największej należności (największa liczba dodatnia)
    creditors.sort((a, b) => b.value.compareTo(a.value)); 

    List<Debt> finalDebts = [];
    int i = 0; // wskaźnik dłużnika
    int j = 0; // wskaźnik wierzyciela

    // KROK 5, 6, 7 (wg PDF): Pętla parowania i "wykonywanie przelewów" wirtualnie
    while (i < debtors.length && j < creditors.length) {
      var debtor = debtors[i];
      var creditor = creditors[j];

      // Kwota do oddania to minimum z dwóch wartości:
      // albo cały dług dłużnika, albo cała należność wierzyciela
      // abs() używamy, bo dług jest ujemny
      double amount = double.parse(
          (debtor.value.abs() < creditor.value ? debtor.value.abs() : creditor.value)
              .toStringAsFixed(2));

      // Jeśli kwota jest znacząca, dodajemy do listy przelewów
      if (amount > 0.00) {
        finalDebts.add(Debt(fromUser: debtor.key, toUser: creditor.key, amount: amount));
      }

      // Aktualizacja bilansów po "wirtualnym przelewie"
      double remainingDebt = debtor.value + amount;      // Dług się zmniejsza (zbliża do 0)
      double remainingCredit = creditor.value - amount;  // Należność się zmniejsza

      // Sprawdzenie czy ktoś został w pełni rozliczony
      // Używamy małego marginesu błędu 0.01 dla double
      if (remainingDebt.abs() < 0.01) {
        i++; // Dłużnik "czysty", bierzemy następnego
      } else {
        debtors[i] = MapEntry(debtor.key, remainingDebt); // Zaktualizuj dług
      }

      if (remainingCredit.abs() < 0.01) {
        j++; // Wierzyciel spłacony, bierzemy następnego
      } else {
        creditors[j] = MapEntry(creditor.key, remainingCredit); // Zaktualizuj należność
      }
    }

    return finalDebts;
  }
}