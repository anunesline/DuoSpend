import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/knowledge/taxonomy/taxonomy_item.dart';

class DetectedCategoryCard extends StatelessWidget {
  const DetectedCategoryCard({
    super.key,
    required this.category,
    required this.subcategory,
    required this.onEdit,
  });

  final TaxonomyItem category;
  final TaxonomyItem? subcategory;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final subcategoryName = subcategory?.name ?? 'Sem subcategoria';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            CircleAvatar(
              child: Text(category.icon),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categoria detectada',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(subcategoryName),
                ],
              ),
            ),
            TextButton(
              onPressed: onEdit,
              child: const Text('Editar'),
            ),
          ],
        ),
      ),
    );
  }
}