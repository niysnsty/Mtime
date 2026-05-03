import 'package:intl/intl.dart';

class CycleEngine {
  /// Calculates the next predicted period date based on average cycle length.
  static DateTime predictNextPeriod(DateTime lastPeriodDate, int averageCycleLength) {
    return lastPeriodDate.add(Duration(days: averageCycleLength));
  }

  /// Calculates the ovulation window (usually 14 days before the next period).
  static Map<String, DateTime> calculateOvulationWindow(DateTime predictedNextPeriod) {
    DateTime ovulationDate = predictedNextPeriod.subtract(const Duration(days: 14));
    return {
      'start': ovulationDate.subtract(const Duration(days: 2)),
      'ovulation': ovulationDate,
      'end': ovulationDate.add(const Duration(days: 2)),
    };
  }

  /// Returns the current phase of the cycle.
  static String getCyclePhase(DateTime today, DateTime lastPeriodDate, int averageCycleLength) {
    final nextPeriod = predictNextPeriod(lastPeriodDate, averageCycleLength);
    final ovulation = calculateOvulationWindow(nextPeriod)['ovulation']!;
    
    final daysSinceStart = today.difference(lastPeriodDate).inDays;

    if (daysSinceStart >= 0 && daysSinceStart < 5) {
      return 'Menstruasi';
    } else if (today.isAfter(ovulation.subtract(const Duration(days: 3))) && 
               today.isBefore(ovulation.add(const Duration(days: 3)))) {
      return 'Masa Subur';
    } else {
      return 'Fase Luteal';
    }
  }

  /// Formats days remaining until next period.
  static int daysUntilNextPeriod(DateTime today, DateTime predictedNextPeriod) {
    return predictedNextPeriod.difference(today).inDays;
  }
}
