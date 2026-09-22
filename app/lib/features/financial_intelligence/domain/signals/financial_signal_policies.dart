import 'financial_signals.dart';

/// Approved deterministic runtime policy for FI-D V1.
abstract final class FinancialSignalPolicies {
  static const v1 = FinancialSignalPolicy(
    minimumPercentage: 0.20,
    minimumAbsoluteDifference: 50,
    allowBaseZeroByAbsolute: true,
  );
}
