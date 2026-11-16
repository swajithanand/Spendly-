import '../models/category_model.dart';

/// Health of a category budget for the current period.
///
/// Spending categories: on track below 80% of the limit, near the limit at
/// 80–99%, over at 100%+. Savings categories invert the logic — reaching
/// 100% of the allocation is the goal, so they report [achieved] instead
/// of [over] and never warn.
enum BudgetStatus { onTrack, nearLimit, over, achieved }

class BudgetHealth {
  BudgetHealth._();

  static bool isSavings(CategoryModel cat) => cat.isSavings;

  static BudgetStatus statusFor({
    required double spent,
    required double limit,
    bool isSavings = false,
  }) {
    if (limit <= 0) return BudgetStatus.onTrack;
    final ratio = spent / limit;
    if (isSavings) {
      return ratio >= 1.0 ? BudgetStatus.achieved : BudgetStatus.onTrack;
    }
    if (ratio >= 1.0) return BudgetStatus.over;
    if (ratio >= 0.8) return BudgetStatus.nearLimit;
    return BudgetStatus.onTrack;
  }
}
