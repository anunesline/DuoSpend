import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_colors.dart';
import '../../domain/models/savings_goal.dart';

extension SavingsGoalCategoryVisuals on SavingsGoalCategory {
  String get label => switch (this) {
    SavingsGoalCategory.travel => 'Viagem',
    SavingsGoalCategory.emergency => 'Emergência',
    SavingsGoalCategory.vehicle => 'Veículo',
    SavingsGoalCategory.housing => 'Moradia',
    SavingsGoalCategory.education => 'Educação',
    SavingsGoalCategory.health => 'Saúde',
    SavingsGoalCategory.shopping => 'Compras',
    SavingsGoalCategory.investment => 'Investimento',
    SavingsGoalCategory.others => 'Outros',
  };

  IconData get icon => switch (this) {
    SavingsGoalCategory.travel => Icons.flight_rounded,
    SavingsGoalCategory.emergency => Icons.health_and_safety_rounded,
    SavingsGoalCategory.vehicle => Icons.directions_car_rounded,
    SavingsGoalCategory.housing => Icons.home_rounded,
    SavingsGoalCategory.education => Icons.school_rounded,
    SavingsGoalCategory.health => Icons.favorite_rounded,
    SavingsGoalCategory.shopping => Icons.shopping_bag_rounded,
    SavingsGoalCategory.investment => Icons.trending_up_rounded,
    SavingsGoalCategory.others => Icons.flag_rounded,
  };

  Color get accent => switch (this) {
    SavingsGoalCategory.travel => DuoColors.orbitAccent,
    SavingsGoalCategory.emergency => const Color(0xFFFF9800),
    SavingsGoalCategory.vehicle => const Color(0xFF3B82F6),
    SavingsGoalCategory.housing => const Color(0xFF32C766),
    SavingsGoalCategory.education => const Color(0xFF9B6CFF),
    SavingsGoalCategory.health => const Color(0xFFFF5D8F),
    SavingsGoalCategory.shopping => const Color(0xFFFFC857),
    SavingsGoalCategory.investment => const Color(0xFF20C997),
    SavingsGoalCategory.others => const Color(0xFF7D8998),
  };
}
